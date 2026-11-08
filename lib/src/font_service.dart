import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

@immutable
class FontFace {
  const FontFace({
    required this.id,
    required this.name,
    required this.family,
    required this.style,
    this.imported = false,
  });
  final String id;
  final String name;
  final String family;
  final String style;
  final bool imported;
  factory FontFace.fromMap(Map<Object?, Object?> map) => FontFace(
    id: map['id'] as String,
    name: map['name'] as String,
    family: map['family'] as String,
    style: map['style'] as String? ?? 'Regular',
    imported: map['imported'] == true,
  );
  bool matches(String query) {
    final words = query.toLowerCase().trim().split(RegExp(r'\s+'));
    final haystack = '$name $family $style'.toLowerCase();
    return words.every(haystack.contains);
  }
}

enum PreviewAlignment { left, center, right }

class GlyphCoverage {
  const GlyphCoverage(this.missing, {this.available = true});
  final List<int> missing;
  final bool available;
  bool get complete => available && missing.isEmpty;
}

class PreviewRequest {
  const PreviewRequest({
    required this.fontId,
    required this.text,
    required this.size,
    required this.color,
    required this.width,
    required this.height,
    this.scale = 2,
    this.letterSpacing = 0,
    this.lineHeight = 1.35,
    this.alignment = PreviewAlignment.left,
  });
  final String fontId;
  final String text;
  final double size;
  final int color;
  final double width;
  final double height;
  final double scale;
  final double letterSpacing;
  final double lineHeight;
  final PreviewAlignment alignment;
  Map<String, Object> toMap() => {
    'fontId': fontId,
    'text': text,
    'size': size,
    'color': color,
    'width': width,
    'height': height,
    'scale': scale,
    'letterSpacing': letterSpacing,
    'lineHeight': lineHeight,
    'alignment': alignment.name,
  };
  String get cacheKey =>
      '$fontId\u0000$text\u0000$size/$color/$width/$height/$scale/$letterSpacing/$lineHeight/${alignment.name}';
}

class FontService {
  static const channel = MethodChannel('app.toolmoa.fontv/fonts');
  final _cache = <String, Uint8List>{};
  final _pending = <String, Future<Uint8List>>{};
  int _cacheBytes = 0;
  static const _maxCacheBytes = 12 * 1024 * 1024;
  bool get isDemo =>
      kIsWeb ||
      (defaultTargetPlatform != TargetPlatform.iOS &&
          defaultTargetPlatform != TargetPlatform.android);

  Future<Set<String>> hangulFonts() async {
    if (isDemo) throw UnsupportedError('Device fonts are required');
    final ids = await channel.invokeListMethod<String>('getHangulFonts');
    if (ids == null) throw StateError('Missing coverage result');
    return ids.toSet();
  }

  Future<GlyphCoverage> checkGlyphs(String fontId, String text) async {
    if (isDemo) return const GlyphCoverage([], available: false);
    // Ignore spacing/control characters, not printable combining marks.
    final codePoints = text.runes
        .where(
          (c) =>
              c > 0x20 &&
              c != 0x7f &&
              c != 0x200b &&
              c != 0x200c &&
              c != 0x200d &&
              c != 0x2060 &&
              c != 0xfeff &&
              !(c >= 0xfe00 && c <= 0xfe0f) &&
              !(c >= 0xe0100 && c <= 0xe01ef) &&
              !RegExp(r'\s', unicode: true).hasMatch(String.fromCharCode(c)),
        )
        .toSet()
        .take(1000)
        .toList();
    final missing = await channel.invokeListMethod<int>('checkGlyphs', {
      'fontId': fontId,
      'codePoints': codePoints,
    });
    if (missing == null) throw StateError('Missing coverage result');
    return GlyphCoverage(List.unmodifiable(missing));
  }

  Future<FontFace> importFont(Uint8List bytes, String filename) async {
    if (isDemo) throw UnsupportedError('Device fonts are required');
    if (bytes.length > 32 * 1024 * 1024) {
      throw PlatformException(code: 'FONT_TOO_LARGE');
    }
    final row = await channel.invokeMapMethod<Object?, Object?>('importFont', {
      'bytes': bytes,
      'filename': filename,
    });
    if (row == null) throw StateError('Empty import result');
    clearCache();
    return FontFace.fromMap(row);
  }

  Future<void> removeImportedFont(String id) async {
    await channel.invokeMethod<void>('removeImportedFont', {'fontId': id});
    clearCache();
  }

  Future<bool> saveImage(Uint8List bytes, String filename) async =>
      await channel.invokeMethod<bool>('saveImage', {
        'bytes': bytes,
        'filename': filename,
      }) ??
      false;

  void clearCache() {
    _cache.clear();
    _cacheBytes = 0;
  }

  Future<List<FontFace>> loadFonts() async {
    if (isDemo) return demoFonts;
    final rows = await channel.invokeListMethod<Object?>('getFonts');
    final fonts = (rows ?? [])
        .map((row) => FontFace.fromMap(row as Map<Object?, Object?>))
        .toList();
    fonts.sort(
      (a, b) => a.family.toLowerCase().compareTo(b.family.toLowerCase()) != 0
          ? a.family.toLowerCase().compareTo(b.family.toLowerCase())
          : a.name.compareTo(b.name),
    );
    return fonts;
  }

  Future<Uint8List> render(PreviewRequest request) {
    final key = request.cacheKey;
    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached;
      return Future.value(cached);
    }
    return _pending.putIfAbsent(key, () async {
      try {
        final data = await channel.invokeMethod<Uint8List>(
          'renderPreview',
          request.toMap(),
        );
        if (data == null) throw StateError('Empty font preview');
        _cache[key] = data;
        _cacheBytes += data.length;
        while (_cacheBytes > _maxCacheBytes && _cache.isNotEmpty) {
          _cacheBytes -= _cache.remove(_cache.keys.first)!.length;
        }
        return data;
      } finally {
        _pending.remove(key);
      }
    });
  }

  static const demoFonts = [
    FontFace(
      id: 'demo:regular',
      name: 'Default Sans',
      family: 'Preview Demo',
      style: 'Regular',
    ),
    FontFace(
      id: 'demo:bold',
      name: 'Default Sans Bold',
      family: 'Preview Demo',
      style: 'Bold',
    ),
    FontFace(
      id: 'demo:italic',
      name: 'Default Sans Italic',
      family: 'Preview Demo',
      style: 'Italic',
    ),
  ];
}
