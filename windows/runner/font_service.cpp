#include "font_service.h"

#include <flutter/standard_method_codec.h>
#include <bcrypt.h>
#include <d2d1.h>
#include <dwrite_3.h>
#include <shlobj.h>
#include <wincodec.h>
#include <wrl/client.h>
#include <algorithm>
#include <cmath>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <map>
#include <sstream>
#include <stdexcept>

namespace {
using Microsoft::WRL::ComPtr;
using V = flutter::EncodableValue;
using Map = flutter::EncodableMap;
using List = flutter::EncodableList;
namespace fs = std::filesystem;
struct NativeError { HRESULT hr; };
void Check(HRESULT hr) { if (FAILED(hr)) throw NativeError{hr}; }
const V& Arg(const Map& args, const char* name) {
  auto it = args.find(V(name));
  if (it == args.end()) throw "FONT_INVALID";
  return it->second;
}
std::string String(const Map& args, const char* key) {
  return std::get<std::string>(Arg(args, key));
}
double Number(const Map& args, const char* key, double fallback) {
  auto it = args.find(V(key));
  if (it == args.end()) return fallback;
  if (auto value = std::get_if<double>(&it->second)) return std::isfinite(*value) ? *value : fallback;
  if (auto value = std::get_if<int32_t>(&it->second)) return *value;
  if (auto value = std::get_if<int64_t>(&it->second)) return static_cast<double>(*value);
  throw "FONT_INVALID";
}
std::wstring Wide(const std::string& text) {
  if (text.empty()) return {};
  const int count = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, text.data(), static_cast<int>(text.size()), nullptr, 0);
  if (!count) throw "FONT_INVALID";
  std::wstring output(count, 0);
  MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, text.data(), static_cast<int>(text.size()), output.data(), count);
  return output;
}
std::string Utf8(const std::wstring& text) {
  const int count = WideCharToMultiByte(CP_UTF8, 0, text.data(), static_cast<int>(text.size()), nullptr, 0, nullptr, nullptr);
  std::string output(count, 0);
  WideCharToMultiByte(CP_UTF8, 0, text.data(), static_cast<int>(text.size()), output.data(), count, nullptr, nullptr);
  return output;
}
std::wstring Name(IDWriteLocalizedStrings* names) {
  UINT32 index = 0, length = 0;
  BOOL found = FALSE;
  Check(names->FindLocaleName(L"en-us", &index, &found));
  if (!found) index = 0;
  Check(names->GetStringLength(index, &length));
  std::wstring value(length + 1, 0);
  Check(names->GetString(index, value.data(), length + 1));
  value.resize(length);
  return value;
}
std::string Digest(const std::vector<uint8_t>& data) {
  // CNG's reusable SHA-256 provider is built into supported Windows versions.
  uint8_t digest[32] = {};
  if (BCryptHash(BCRYPT_SHA256_ALG_HANDLE, nullptr, 0,
                 const_cast<PUCHAR>(data.data()), static_cast<ULONG>(data.size()),
                 digest, sizeof(digest)) < 0) throw "FONT_ERROR";
  std::ostringstream value;
  for (auto byte : digest) value << std::hex << std::setw(2) << std::setfill('0') << static_cast<int>(byte);
  return value.str();
}
bool ImportId(const std::string& id) {
  return id.size() == 71 && id.compare(0, 7, "import:") == 0 &&
      id.find_first_not_of("0123456789abcdef", 7) == std::string::npos;
}
struct Face {
  ComPtr<IDWriteFont> font;
  ComPtr<IDWriteFontFace> face;
  ComPtr<IDWriteFontCollection> collection;
  std::wstring family;
  Map row;
};

class Catalog {
 public:
  Catalog() {
    Check(DWriteCreateFactory(DWRITE_FACTORY_TYPE_SHARED, __uuidof(IDWriteFactory5), &factory_));
    Check(D2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED, d2d_.GetAddressOf()));
    Check(CoCreateInstance(CLSID_WICImagingFactory, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&wic_)));
    PWSTR path = nullptr;
    Check(SHGetKnownFolderPath(FOLDERID_LocalAppData, 0, nullptr, &path));
    imports_ = fs::path(path) / L"ToolMoa" / L"FontV" / L"imports";
    CoTaskMemFree(path);
    fs::create_directories(imports_);
  }
  V Call(const std::string& method, const Map& args) {
    if (method == "getFonts") return Load();
    if (method == "importFont") return Import(args);
    if (method == "removeImportedFont") {
      const auto id = String(args, "fontId");
      if (!ImportId(id)) throw "FONT_INVALID";
      // Release DirectWrite's file references before removing the local copy.
      faces_.erase(id);
      hangul_.erase(id);
      fs::remove(imports_ / (Wide(id.substr(7)) + L".font"));
      return V();
    }
    if (method == "getHangulFonts") {
      List result;
      std::vector<UINT32> points;
      for (UINT32 c = 0xac00; c <= 0xd7a3; ++c) points.push_back(c);
      for (auto& entry : faces_) {
        auto cached = hangul_.find(entry.first);
        const bool complete = cached == hangul_.end() ? Missing(entry.second, points).empty() : cached->second;
        hangul_[entry.first] = complete;
        if (complete) result.emplace_back(entry.first);
      }
      return V(result);
    }
    const auto id = String(args, "fontId");
    const auto found = faces_.find(id);
    if (found == faces_.end()) throw "FONT_INVALID";
    if (method == "renderPreview") return V(Render(found->second, args));
    if (method == "checkGlyphs") {
      std::vector<UINT32> points;
      for (const auto& value : std::get<List>(Arg(args, "codePoints"))) {
        if (points.size() == 1000) break;
        points.push_back(static_cast<UINT32>(value.LongValue()));
      }
      return V(Missing(found->second, points));
    }
    throw "FONT_INVALID";
  }

 private:
  Face MakeFace(IDWriteFont* font, IDWriteFontCollection* collection, const std::string& id, bool imported) {
    Face value;
    value.font = font;
    value.collection = collection;
    Check(font->CreateFontFace(&value.face));
    ComPtr<IDWriteFontFamily> family;
    ComPtr<IDWriteLocalizedStrings> names;
    Check(font->GetFontFamily(&family));
    Check(family->GetFamilyNames(&names));
    value.family = Name(names.Get());
    names.Reset();
    Check(font->GetFaceNames(&names));
    const auto style = Name(names.Get());
    names.Reset();
    BOOL exists = FALSE;
    const HRESULT info = font->GetInformationalStrings(DWRITE_INFORMATIONAL_STRING_POSTSCRIPT_NAME, &names, &exists);
    const auto name = SUCCEEDED(info) && exists ? Name(names.Get()) : value.family + L" " + style;
    value.row = {{V("id"), V(id.empty() ? "system:" + Utf8(name) : id)},
                 {V("name"), V(Utf8(name))}, {V("family"), V(Utf8(value.family))},
                 {V("style"), V(Utf8(style))}, {V("imported"), V(imported)}};
    return value;
  }
  Face ReadImported(const fs::path& path) {
    if (fs::file_size(path) > 32 * 1024 * 1024) throw "FONT_TOO_LARGE";
    ComPtr<IDWriteFontFile> file;
    Check(factory_->CreateFontFileReference(path.c_str(), nullptr, &file));
    BOOL supported = FALSE;
    DWRITE_FONT_FILE_TYPE file_type;
    DWRITE_FONT_FACE_TYPE face_type;
    UINT32 count = 0;
    Check(file->Analyze(&supported, &file_type, &face_type, &count));
    if (!supported || count != 1 || file_type == DWRITE_FONT_FILE_TYPE_OPENTYPE_COLLECTION) throw "FONT_INVALID";
    ComPtr<IDWriteFontSetBuilder1> builder;
    Check(factory_->CreateFontSetBuilder(&builder));
    Check(builder->AddFontFile(file.Get()));
    ComPtr<IDWriteFontSet> set;
    Check(builder->CreateFontSet(&set));
    ComPtr<IDWriteFontCollection1> collection;
    Check(factory_->CreateFontCollectionFromFontSet(set.Get(), &collection));
    ComPtr<IDWriteFontFamily> family;
    ComPtr<IDWriteFont> font;
    Check(static_cast<IDWriteFontCollection*>(collection.Get())->GetFontFamily(0, &family));
    Check(family->GetFont(0, &font));
    return MakeFace(font.Get(), collection.Get(), "import:" + Utf8(path.stem().wstring()), true);
  }
  V Load() {
    faces_.clear();
    hangul_.clear();
    ComPtr<IDWriteFontCollection> system;
    Check(factory_->GetSystemFontCollection(&system, TRUE));
    for (UINT32 f = 0; f < system->GetFontFamilyCount(); ++f) {
      ComPtr<IDWriteFontFamily> family;
      if (FAILED(system->GetFontFamily(f, &family))) continue;
      for (UINT32 i = 0; i < family->GetFontCount(); ++i) {
        try {
          ComPtr<IDWriteFont> font;
          Check(family->GetFont(i, &font));
          if (font->GetSimulations() != DWRITE_FONT_SIMULATIONS_NONE) continue;
          auto face = MakeFace(font.Get(), system.Get(), "", false);
          auto id = std::get<std::string>(face.row.at(V("id")));
          faces_[id] = std::move(face);
        } catch (const NativeError&) {
          // Installed collections can contain unavailable or damaged faces.
          // Keep every accessible font usable instead of failing the catalog.
        }
      }
    }
    for (const auto& entry : fs::directory_iterator(imports_)) {
      if (entry.path().extension() != L".font" || !ImportId("import:" + Utf8(entry.path().stem().wstring()))) continue;
      try {
        auto face = ReadImported(entry.path());
        faces_[std::get<std::string>(face.row.at(V("id")))] = std::move(face);
      } catch (...) { /* A damaged import must not hide system fonts. */ }
    }
    List rows;
    for (const auto& entry : faces_) rows.emplace_back(entry.second.row);
    return V(rows);
  }
  V Import(const Map& args) {
    const auto& bytes = std::get<std::vector<uint8_t>>(Arg(args, "bytes"));
    if (bytes.size() > 32 * 1024 * 1024) throw "FONT_TOO_LARGE";
    if (bytes.size() < 12 || !((bytes[0] == 0 && bytes[1] == 1 && bytes[2] == 0 && bytes[3] == 0) ||
        std::equal(bytes.begin(), bytes.begin() + 4, "OTTO") || std::equal(bytes.begin(), bytes.begin() + 4, "true"))) throw "FONT_INVALID";
    const auto digest = Digest(bytes);
    const auto path = imports_ / (Wide(digest) + L".font");
    const bool exists = fs::exists(path);
    if (!exists) {
      uintmax_t total = 0;
      size_t count = 0;
      for (const auto& entry : fs::directory_iterator(imports_)) {
        if (entry.path().extension() == L".font") { total += entry.file_size(); ++count; }
      }
      if (count >= 50 || total + bytes.size() > 100 * 1024 * 1024) throw "FONT_LIMIT";
      const auto temporary = imports_ / (Wide(digest) + L".tmp");
      try {
        std::ofstream stream(temporary, std::ios::binary | std::ios::trunc);
        stream.exceptions(std::ios::badbit | std::ios::failbit);
        stream.write(reinterpret_cast<const char*>(bytes.data()), static_cast<std::streamsize>(bytes.size()));
        stream.close();
        fs::rename(temporary, path);
      } catch (...) { fs::remove(temporary); throw; }
    }
    try {
      auto face = ReadImported(path);
      const V row(face.row);
      faces_["import:" + digest] = std::move(face);
      hangul_.erase("import:" + digest);
      return row;
    } catch (...) {
      if (!exists) fs::remove(path);
      throw "FONT_INVALID";
    }
  }
  List Missing(const Face& font, const std::vector<UINT32>& points) {
    List missing;
    if (points.empty()) return missing;
    std::vector<UINT16> glyphs(points.size());
    Check(font.face->GetGlyphIndices(points.data(), static_cast<UINT32>(points.size()), glyphs.data()));
    for (size_t i = 0; i < points.size(); ++i) {
      if (points[i] > 0x10ffff || (points[i] >= 0xd800 && points[i] <= 0xdfff) || glyphs[i] == 0)
        missing.emplace_back(static_cast<int64_t>(points[i]));
    }
    return missing;
  }
  std::vector<uint8_t> Render(const Face& font, const Map& args) {
    const auto width = static_cast<float>(std::clamp(Number(args, "width", 1), 1.0, 1600.0));
    const auto height = static_cast<float>(std::clamp(Number(args, "height", 1), 1.0, 1600.0));
    const auto scale = static_cast<float>(std::clamp(Number(args, "scale", 2), 1.0, 3.0));
    const auto size = static_cast<float>(std::clamp(Number(args, "size", 32), 8.0, 120.0));
    auto text = Wide(String(args, "text"));
    if (text.size() > 1000) {
      text.resize(1000);
      if (text.back() >= 0xd800 && text.back() <= 0xdbff) text.pop_back();
    }
    ComPtr<IDWriteTextFormat> format;
    Check(factory_->CreateTextFormat(font.family.c_str(), font.collection.Get(), font.font->GetWeight(),
          font.font->GetStyle(), font.font->GetStretch(), size, L"en-us", &format));
    const auto align = String(args, "alignment");
    Check(format->SetTextAlignment(align == "center" ? DWRITE_TEXT_ALIGNMENT_CENTER :
          align == "right" ? DWRITE_TEXT_ALIGNMENT_TRAILING : DWRITE_TEXT_ALIGNMENT_LEADING));
    const auto line_height = size * static_cast<float>(std::clamp(Number(args, "lineHeight", 1.35), 1.0, 2.5));
    DWRITE_FONT_METRICS metrics;
    font.face->GetMetrics(&metrics);
    const float baseline = std::min(line_height, size * static_cast<float>(metrics.ascent) / metrics.designUnitsPerEm);
    Check(format->SetLineSpacing(DWRITE_LINE_SPACING_METHOD_UNIFORM, line_height, baseline));
    ComPtr<IDWriteTextLayout> layout;
    Check(factory_->CreateTextLayout(text.c_str(), static_cast<UINT32>(text.size()), format.Get(), width, height, &layout));
    ComPtr<IDWriteTextLayout1> layout1;
    Check(layout.As(&layout1));
    Check(layout1->SetCharacterSpacing(0, static_cast<float>(std::clamp(Number(args, "letterSpacing", 0), -2.0, 12.0)),
          0, {0, static_cast<UINT32>(text.size())}));
    ComPtr<IWICBitmap> bitmap;
    Check(wic_->CreateBitmap(static_cast<UINT>(std::ceil(width * scale)), static_cast<UINT>(std::ceil(height * scale)),
          GUID_WICPixelFormat32bppPBGRA, WICBitmapCacheOnLoad, &bitmap));
    ComPtr<ID2D1RenderTarget> target;
    const auto properties = D2D1::RenderTargetProperties(D2D1_RENDER_TARGET_TYPE_SOFTWARE,
          D2D1::PixelFormat(DXGI_FORMAT_B8G8R8A8_UNORM, D2D1_ALPHA_MODE_PREMULTIPLIED), 96 * scale, 96 * scale);
    Check(d2d_->CreateWicBitmapRenderTarget(bitmap.Get(), properties, &target));
    const auto argb = static_cast<uint32_t>(Number(args, "color", 0xff000000));
    ComPtr<ID2D1SolidColorBrush> brush;
    Check(target->CreateSolidColorBrush(D2D1::ColorF(argb & 0xffffff, static_cast<float>((argb >> 24) & 255) / 255), &brush));
    target->BeginDraw();
    target->Clear(D2D1::ColorF(0, 0.0f));
    target->SetTextAntialiasMode(D2D1_TEXT_ANTIALIAS_MODE_GRAYSCALE);
    target->DrawTextLayout(D2D1::Point2F(0, 0), layout.Get(), brush.Get(), D2D1_DRAW_TEXT_OPTIONS_CLIP);
    Check(target->EndDraw());
    ComPtr<IStream> stream;
    Check(CreateStreamOnHGlobal(nullptr, TRUE, &stream));
    ComPtr<IWICBitmapEncoder> encoder;
    Check(wic_->CreateEncoder(GUID_ContainerFormatPng, nullptr, &encoder));
    Check(encoder->Initialize(stream.Get(), WICBitmapEncoderNoCache));
    ComPtr<IWICBitmapFrameEncode> frame;
    Check(encoder->CreateNewFrame(&frame, nullptr));
    Check(frame->Initialize(nullptr));
    Check(frame->SetSize(static_cast<UINT>(std::ceil(width * scale)), static_cast<UINT>(std::ceil(height * scale))));
    WICPixelFormatGUID pixel_format = GUID_WICPixelFormat32bppBGRA;
    Check(frame->SetPixelFormat(&pixel_format));
    Check(frame->WriteSource(bitmap.Get(), nullptr));
    Check(frame->Commit());
    Check(encoder->Commit());
    STATSTG stat = {};
    Check(stream->Stat(&stat, STATFLAG_NONAME));
    if (stat.cbSize.QuadPart > 100 * 1024 * 1024) throw "FONT_ERROR";
    std::vector<uint8_t> png(static_cast<size_t>(stat.cbSize.QuadPart));
    LARGE_INTEGER zero = {};
    Check(stream->Seek(zero, STREAM_SEEK_SET, nullptr));
    ULONG read = 0;
    Check(stream->Read(png.data(), static_cast<ULONG>(png.size()), &read));
    if (read != png.size()) throw "FONT_ERROR";
    return png;
  }
  ComPtr<IDWriteFactory5> factory_;
  ComPtr<ID2D1Factory> d2d_;
  ComPtr<IWICImagingFactory> wic_;
  fs::path imports_;
  std::map<std::string, Face> faces_;
  std::map<std::string, bool> hangul_;
};
}  // namespace

FontService::FontService(flutter::BinaryMessenger* messenger, HWND window) : window_(window) {
  channel_ = std::make_unique<flutter::MethodChannel<Value>>(messenger,
      "app.toolmoa.fontv/fonts", &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler([this](const auto& call, std::unique_ptr<Result> result) {
    const auto& method = call.method_name();
    if (method != "getFonts" && method != "renderPreview" && method != "checkGlyphs" &&
        method != "getHangulFonts" && method != "importFont" && method != "removeImportedFont") {
      result->NotImplemented(); return;
    }
    {
      std::lock_guard<std::mutex> lock(mutex_);
      tasks_.push_back({method, call.arguments() ? *call.arguments() : Value(Map{}), std::move(result)});
    }
    ready_.notify_one();
  });
  worker_ = std::thread([this] { Run(); });
}
FontService::~FontService() {
  channel_->SetMethodCallHandler(nullptr);
  {
    std::lock_guard<std::mutex> lock(mutex_);
    stopping_ = true;
    tasks_.clear();
  }
  ready_.notify_one();
  worker_.join();
  CompleteResults();
}
void FontService::Run() {
  const HRESULT com = CoInitializeEx(nullptr, COINIT_MULTITHREADED);
  {
    std::unique_ptr<Catalog> catalog;
    for (;;) {
      Task task;
      {
        std::unique_lock<std::mutex> lock(mutex_);
        ready_.wait(lock, [this] { return stopping_ || !tasks_.empty(); });
        if (stopping_) break;
        task = std::move(tasks_.front()); tasks_.pop_front();
      }
      Completion completion{std::move(task.result), Value(), ""};
      try {
        Check(com);
        if (!catalog) catalog = std::make_unique<Catalog>();
        completion.value = catalog->Call(task.method, std::get<Map>(task.arguments));
      } catch (const NativeError& error) {
          completion.error = "FONT_ERROR";
          completion.value = Value(Map{{Value("method"), Value(task.method)},
              {Value("hresult"), Value(static_cast<int64_t>(static_cast<uint32_t>(error.hr)))}});
        } catch (const char* code) { completion.error = code; }
        catch (...) { completion.error = "FONT_ERROR"; }
      {
        std::lock_guard<std::mutex> lock(mutex_);
        completed_.push_back(std::move(completion));
      }
      PostMessage(window_, kResultMessage, 0, 0);
    }
  }
  if (SUCCEEDED(com)) CoUninitialize();
}
void FontService::CompleteResults() {
  std::deque<Completion> ready;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    ready.swap(completed_);
  }
  for (auto& item : ready) {
    if (item.error.empty()) item.result->Success(item.value);
    else item.result->Error(item.error, "Font operation failed", item.value);
  }
}
