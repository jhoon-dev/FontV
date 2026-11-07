import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_v/src/controller.dart';
import 'package:font_v/src/font_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestFonts extends FontService {
  TestFonts({this.fail = false});
  bool fail;
  @override
  bool get isDemo => true;
  @override
  Future<List<FontFace>> loadFonts() async {
    if (fail) throw StateError('Test failure');
    return const [
      FontFace(id: 'a', name: 'Alpha-Bold', family: 'Alpha', style: 'Bold'),
      FontFace(id: 'b', name: 'Beta-Regular', family: 'Beta', style: 'Regular'),
      FontFace(id: 'c', name: 'Alpha-Italic', family: 'Alpha', style: 'Italic'),
    ];
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'search combines case-insensitive words across family and face style',
    () async {
      final c = FontController(service: TestFonts());
      await c.initialize();
      expect(c.familyCount, 2);
      c.setQuery(' ALPHA bold ');
      expect(c.visibleFonts.map((f) => f.id), ['a']);
      c.toggleFavorite('b');
      c.setTab(1);
      expect(c.query, '');
      expect(c.visibleFonts.map((f) => f.id), ['b']);
      c.setQuery('Alpha');
      expect(c.visibleFonts, isEmpty);
      await c.flushSettings();
      c.dispose();
    },
  );
  test(
    'favorites, custom text, size, color and theme survive a fresh controller',
    () async {
      final c = FontController(service: TestFonts());
      await c.initialize();
      c.toggleFavorite('a');
      c.toggleFavorite('c');
      c.toggleFavorite('a');
      c.setSkin(FontSkin.green);
      c.setSize(999);
      c.setInk(const Color(0xFF123456));
      c.setPaper(const Color(0xFFFAFAFA));
      c.setSample('한글\nABC\n0123');
      await c.flushSettings();
      c.dispose();
      final restored = FontController(service: TestFonts());
      await restored.initialize();
      expect(restored.favorites, {'c'});
      expect(restored.skin, FontSkin.green);
      expect(restored.size, 96);
      expect(restored.ink.toARGB32(), 0xFF123456);
      expect(restored.paper.toARGB32(), 0xFFFAFAFA);
      expect(restored.sample, '한글\nABC\n0123');
      restored.dispose();
    },
  );
  test('native load failures are actionable and a retry recovers', () async {
    final service = TestFonts(fail: true);
    final c = FontController(service: service);
    await c.initialize();
    expect(c.loading, false);
    expect(c.error, isNotNull);
    service.fail = false;
    await c.initialize();
    expect(c.error, isNull);
    expect(c.fonts, hasLength(3));
    c.dispose();
  });
}
