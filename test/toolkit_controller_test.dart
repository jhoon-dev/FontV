import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_v/src/controller.dart';
import 'package:font_v/src/font_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ToolkitFonts extends FontService {
  final entries = <FontFace>[
    for (final id in ['a', 'b', 'c', 'd', 'e'])
      FontFace(
        id: id,
        name: 'Face $id',
        family: 'Family $id',
        style: 'Regular',
      ),
  ];
  Completer<Set<String>>? coverageGate;
  @override
  bool get isDemo => false;
  @override
  Future<List<FontFace>> loadFonts() async => List.of(entries);
  @override
  Future<Set<String>> hangulFonts() =>
      coverageGate?.future ?? Future.value({'b'});
  @override
  Future<GlyphCoverage> checkGlyphs(String fontId, String text) async =>
      GlyphCoverage(text.runes.where((r) => r == 0x3a9).toList());
  @override
  Future<FontFace> importFont(Uint8List bytes, String filename) async {
    const face = FontFace(
      id: 'import:test',
      name: 'Imported',
      family: 'Imported',
      style: 'Regular',
      imported: true,
    );
    if (!entries.any((f) => f.id == face.id)) entries.add(face);
    return face;
  }

  @override
  Future<void> removeImportedFont(String id) async =>
      entries.removeWhere((f) => f.id == id);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'four comparison faces retain selection order, reject a fifth, and can be replaced',
    () async {
      final c = FontController(service: ToolkitFonts());
      await c.initialize();
      for (final id in ['c', 'a', 'b', 'e']) {
        expect(c.toggleComparison(id), true);
      }
      expect(c.toggleComparison('d'), false);
      expect(c.comparisonFonts.map((f) => f.id), ['c', 'a', 'b', 'e']);
      c.toggleComparison('a');
      c.toggleComparison('d');
      expect(c.comparisonFonts.map((f) => f.id), ['c', 'b', 'e', 'd']);
      c.clearComparison();
      expect(c.comparisonFonts, isEmpty);
      c.dispose();
    },
  );
  test(
    'named collections, membership and typography survive restart independently of favorites',
    () async {
      final service = ToolkitFonts();
      final c = FontController(service: service);
      await c.initialize();
      final id = c.createCollection('  Headings  ')!;
      expect(c.createCollection('headings'), isNull);
      expect(c.renameCollection(id, ' '), false);
      c.setCollectionMembership(id, 'b', true);
      c.toggleFavorite('a');
      c.setLetterSpacing(2.5);
      c.setLineHeight(1.8);
      c.setAlignment(PreviewAlignment.center);
      await c.flushSettings();
      final restored = FontController(service: service);
      await restored.initialize();
      restored.selectCollection(id);
      expect(restored.visibleFonts.map((f) => f.id), ['b']);
      expect(restored.favorites, {'a'});
      expect(restored.letterSpacing, 2.5);
      expect(restored.lineHeight, 1.8);
      expect(restored.alignment, PreviewAlignment.center);
      restored.deleteCollection(id);
      expect(restored.visibleFonts.map((f) => f.id), ['a']);
      restored.resetPreview();
      expect(restored.letterSpacing, 0);
      expect(restored.lineHeight, 1.35);
      expect(restored.alignment, PreviewAlignment.left);
      await restored.flushSettings();
      c.dispose();
      restored.dispose();
    },
  );
  test(
    'removing an imported font clears only that face from every saved list',
    () async {
      final c = FontController(service: ToolkitFonts());
      await c.initialize();
      final face = await c.importFont(Uint8List(1), 'example.ttf');
      final id = c.createCollection('Body')!;
      for (final font in [face.id, 'a']) {
        c.toggleFavorite(font);
        c.toggleComparison(font);
        c.setCollectionMembership(id, font, true);
      }
      await c.removeImportedFont(face.id);
      expect(c.fonts.any((f) => f.imported), false);
      expect(c.favorites, {'a'});
      expect(c.comparisonIds, ['a']);
      expect(c.collections.single.fontIds, {'a'});
      await c.removeImportedFont('a');
      expect(c.fonts, hasLength(5));
      await c.flushSettings();
      c.dispose();
    },
  );
  test(
    'cancelled glyph scan cannot reactivate filter or hide the catalog later',
    () async {
      final service = ToolkitFonts()..coverageGate = Completer<Set<String>>();
      final c = FontController(service: service);
      await c.initialize();
      final scan = c.setHangulOnly(true);
      expect(c.hangulLoading, true);
      await c.setHangulOnly(false);
      service.coverageGate!.complete({'b'});
      await scan;
      expect(c.hangulOnly, false);
      expect(c.hangulLoading, false);
      expect(c.visibleFonts, hasLength(5));
      service.coverageGate = null;
      await c.setHangulOnly(true);
      expect(c.visibleFonts.map((f) => f.id), ['b']);
      c.dispose();
    },
  );
  test(
    'a malformed new collection preference does not discard legacy settings',
    () async {
      SharedPreferences.setMockInitialValues({
        'collections': 'broken',
        'language': 'ko',
        'size': 52.0,
        'favorites': ['a'],
      });
      final c = FontController(service: ToolkitFonts());
      await c.initialize();
      expect(c.language, AppLanguage.ko);
      expect(c.size, 52);
      expect(c.favorites, {'a'});
      expect(c.collections, isEmpty);
      expect(c.fonts, hasLength(5));
      c.dispose();
    },
  );
}
