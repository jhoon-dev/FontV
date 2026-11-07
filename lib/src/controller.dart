import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'font_service.dart';

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
            (tab != 1 || favorites.contains(font.id)) && font.matches(query),
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
      favorites.addAll(prefs.getStringList('favorites') ?? []);
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
