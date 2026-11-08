import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'font_service.dart';
import 'font_collection.dart';

enum FontSkin {
  pink('핑크', Color(0xFFD9437B)),
  red('레드', Color(0xFFCC4149)),
  green('그린', Color(0xFF28745B)),
  brown('브라운', Color(0xFF896344)),
  purple('퍼플', Color(0xFF7655AB));

  const FontSkin(this.label, this.color);
  final String label;
  final Color color;
}

enum AppLanguage {
  system,
  en,
  ko;

  Locale? get locale => this == system ? null : Locale(name);
}

enum FontLoadIssue { empty, unavailable }

enum FontStorageIssue { read, write }

class FontController extends ChangeNotifier {
  FontController({required this.service});
  final FontService service;
  SharedPreferences? _preferences;
  List<FontFace> fonts = [];
  final Set<String> favorites = {};
  final List<FontCollection> collections = [];
  final List<String> comparisonIds = [];
  bool selectingForCompare = false;
  String? selectedCollectionId;
  bool hangulOnly = false;
  bool hangulLoading = false;
  Set<String>? _hangulIds;
  int _hangulGeneration = 0;
  double letterSpacing = 0;
  double lineHeight = 1.35;
  PreviewAlignment alignment = PreviewAlignment.left;
  bool get coverageAvailable => !service.isDemo;
  FontCollection? get selectedCollection =>
      collections.where((x) => x.id == selectedCollectionId).firstOrNull;
  List<FontFace> get comparisonFonts => comparisonIds
      .map((id) => fonts.where((f) => f.id == id).firstOrNull)
      .whereType<FontFace>()
      .toList();
  bool loading = true;
  FontLoadIssue? error;
  FontStorageIssue? storageError;
  AppLanguage language = AppLanguage.system;
  String query = '';
  int tab = 0;
  FontSkin skin = FontSkin.pink;
  double size = 36;
  Color ink = const Color(0xFF252329);
  Color paper = const Color(0xFFFFFBF5);
  String sample = 'Aa Bb Cc\n가나다라\n0123456789';
  Future<void> _writeQueue = Future.value();
  bool _disposed = false;
  List<FontFace> get visibleFonts => fonts
      .where(
        (font) =>
            (tab != 1 ||
                (selectedCollection?.fontIds ?? favorites).contains(font.id)) &&
            (!hangulOnly || (_hangulIds?.contains(font.id) ?? false)) &&
            font.matches(query),
      )
      .toList();
  int get familyCount => fonts.map((font) => font.family).toSet().length;

  Future<void> initialize() async {
    loading = true;
    error = null;
    _emit();
    try {
      _preferences ??= await SharedPreferences.getInstance();
      final prefs = _preferences!;
      favorites
        ..clear()
        ..addAll(prefs.getStringList('favorites') ?? []);
      Object? storedCollections;
      try {
        storedCollections = jsonDecode(prefs.getString('collections') ?? '[]');
        if (storedCollections is! List) {
          throw const FormatException('Invalid collections');
        }
      } catch (_) {
        storageError = FontStorageIssue.read;
      }
      collections.clear();
      if (storedCollections is List) {
        for (final row in storedCollections) {
          final collection = FontCollection.fromJson(row);
          if (collection != null &&
              !collections.any(
                (x) =>
                    x.id == collection.id ||
                    x.name.toLowerCase() == collection.name.toLowerCase(),
              )) {
            collections.add(collection);
          }
        }
      }
      letterSpacing = (prefs.getDouble('letterSpacing') ?? 0).clamp(-2, 12);
      lineHeight = (prefs.getDouble('lineHeight') ?? 1.35).clamp(1, 2.5);
      alignment =
          PreviewAlignment.values
              .where((a) => a.name == prefs.getString('alignment'))
              .firstOrNull ??
          PreviewAlignment.left;
      final storedSkin = prefs.getString('skin');
      final storedLanguage = prefs.getString('language');
      language =
          AppLanguage.values
              .where((value) => value.name == storedLanguage)
              .firstOrNull ??
          AppLanguage.system;
      skin =
          FontSkin.values.where((s) => s.name == storedSkin).firstOrNull ??
          FontSkin.pink;
      size = (prefs.getDouble('size') ?? 36).clamp(12, 96);
      ink = Color(prefs.getInt('ink') ?? 0xFF252329);
      paper = Color(prefs.getInt('paper') ?? 0xFFFFFBF5);
      sample = prefs.getString('sample') ?? sample;
    } catch (_) {
      storageError = FontStorageIssue.read;
    }
    try {
      fonts = await service.loadFonts();
      if (fonts.isEmpty) error = FontLoadIssue.empty;
    } catch (_) {
      error = FontLoadIssue.unavailable;
    }
    loading = false;
    _emit();
  }

  void setQuery(String value) {
    query = value;
    _emit();
  }

  void setTab(int value) {
    tab = value;
    query = '';
    _emit();
  }

  void selectCollection(String? id) {
    selectedCollectionId = collections.any((x) => x.id == id) ? id : null;
    tab = 1;
    query = '';
    _emit();
  }

  String? createCollection(String value) {
    final name = value.trim();
    if (!_validCollectionName(name)) return null;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    collections.add(FontCollection(id: id, name: name));
    _save();
    _emit();
    return id;
  }

  bool _validCollectionName(String name, [String? except]) =>
      name.isNotEmpty &&
      name.length <= 40 &&
      !collections.any(
        (x) => x.id != except && x.name.toLowerCase() == name.toLowerCase(),
      );

  bool renameCollection(String id, String value) {
    final name = value.trim();
    final index = collections.indexWhere((x) => x.id == id);
    if (index < 0 || !_validCollectionName(name, id)) return false;
    collections[index] = collections[index].copyWith(name: name);
    _save();
    _emit();
    return true;
  }

  void deleteCollection(String id) {
    collections.removeWhere((x) => x.id == id);
    if (selectedCollectionId == id) selectedCollectionId = null;
    _save();
    _emit();
  }

  void setCollectionMembership(String id, String fontId, bool included) {
    final index = collections.indexWhere((x) => x.id == id);
    if (index < 0 || !fonts.any((x) => x.id == fontId)) return;
    final ids = {...collections[index].fontIds};
    included ? ids.add(fontId) : ids.remove(fontId);
    collections[index] = collections[index].copyWith(fontIds: ids);
    _save();
    _emit();
  }

  bool toggleComparison(String id) {
    if (comparisonIds.remove(id)) {
      _emit();
      return true;
    }
    if (comparisonIds.length >= 4 || !fonts.any((x) => x.id == id)) {
      return false;
    }
    comparisonIds.add(id);
    _emit();
    return true;
  }

  void setComparisonSelection(bool value) {
    selectingForCompare = value;
    _emit();
  }

  void clearComparison() {
    comparisonIds.clear();
    selectingForCompare = false;
    _emit();
  }

  Future<void> setHangulOnly(bool value) async {
    if (value && (!coverageAvailable || loading)) return;
    hangulOnly = value;
    final generation = ++_hangulGeneration;
    hangulLoading = value && _hangulIds == null;
    _emit();
    if (!hangulLoading) return;
    try {
      final ids = await service.hangulFonts();
      if (generation == _hangulGeneration) _hangulIds = ids;
    } catch (_) {
      if (generation == _hangulGeneration) {
        hangulOnly = false;
        rethrow;
      }
    } finally {
      if (generation == _hangulGeneration) {
        hangulLoading = false;
        _emit();
      }
    }
  }

  Future<FontFace> importFont(Uint8List bytes, String filename) async {
    final face = await service.importFont(bytes, filename);
    fonts = await service.loadFonts();
    _hangulIds = null;
    if (hangulOnly) await setHangulOnly(true);
    _emit();
    return face;
  }

  Future<void> removeImportedFont(String id) async {
    if (!fonts.any((x) => x.id == id && x.imported)) return;
    await service.removeImportedFont(id);
    fonts = await service.loadFonts();
    favorites.remove(id);
    comparisonIds.remove(id);
    _hangulIds?.remove(id);
    for (var i = 0; i < collections.length; i++) {
      collections[i] = collections[i].copyWith(
        fontIds: {...collections[i].fontIds}..remove(id),
      );
    }
    _save();
    _emit();
  }

  void setLetterSpacing(double value) {
    letterSpacing = value.clamp(-2, 12);
    _save();
    _emit();
  }

  void setLineHeight(double value) {
    lineHeight = value.clamp(1, 2.5);
    _save();
    _emit();
  }

  void setAlignment(PreviewAlignment value) {
    alignment = value;
    _save();
    _emit();
  }

  void toggleFavorite(String id) {
    if (!favorites.remove(id)) favorites.add(id);
    _save();
    _emit();
  }

  void setSkin(FontSkin value) {
    skin = value;
    _save();
    _emit();
  }

  void setLanguage(AppLanguage value) {
    language = value;
    _save();
    _emit();
  }

  void setSize(double value) {
    size = value.clamp(12, 96);
    _save();
    _emit();
  }

  void setInk(Color value) {
    ink = value;
    _save();
    _emit();
  }

  void setPaper(Color value) {
    paper = value;
    _save();
    _emit();
  }

  void setSample(String value) {
    sample = value;
    _save();
    _emit();
  }

  void resetPreview() {
    size = 36;
    ink = const Color(0xFF252329);
    paper = const Color(0xFFFFFBF5);
    letterSpacing = 0;
    lineHeight = 1.35;
    alignment = PreviewAlignment.left;
    _save();
    _emit();
  }

  void _save() {
    // Serialize snapshots: rapid edits must never restore an older setting.
    final snapshot = (
      favorites.toList()..sort(),
      skin.name,
      size,
      ink.toARGB32(),
      paper.toARGB32(),
      sample,
      language.name,
      jsonEncode(collections.map((x) => x.toJson()).toList()),
      letterSpacing,
      lineHeight,
      alignment.name,
    );
    _writeQueue = _writeQueue
        .then((_) async {
          final prefs = _preferences;
          if (prefs == null) return;
          final results = await Future.wait([
            prefs.setStringList('favorites', snapshot.$1),
            prefs.setString('skin', snapshot.$2),
            prefs.setDouble('size', snapshot.$3),
            prefs.setInt('ink', snapshot.$4),
            prefs.setInt('paper', snapshot.$5),
            prefs.setString('sample', snapshot.$6),
            prefs.setString('language', snapshot.$7),
            prefs.setString('collections', snapshot.$8),
            prefs.setDouble('letterSpacing', snapshot.$9),
            prefs.setDouble('lineHeight', snapshot.$10),
            prefs.setString('alignment', snapshot.$11),
          ]);
          if (results.any((success) => !success)) {
            throw StateError('Could not save preferences');
          }
        })
        .catchError((Object _) {
          storageError = FontStorageIssue.write;
          _emit();
        });
  }

  Future<void> flushSettings() => _writeQueue;
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
