import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:font_v/src/ads.dart';
import 'package:font_v/src/app.dart';
import 'package:font_v/src/comparison.dart';
import 'package:font_v/src/controller.dart';
import 'package:font_v/src/font_export.dart';
import 'package:font_v/src/font_service.dart';
import '../test/fixtures/font_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'real native font imports, exact coverage, typography, export and collection persistence',
    (tester) async {
      final service = FontService();
      expect(service.isDemo, false);
      final system = await service.loadFonts();
      expect(system.length, greaterThan(20));
      await expectLater(
        service.importFont(Uint8List.fromList([0, 1, 2, 3]), 'broken.ttf'),
        throwsA(isA<PlatformException>()),
      );
      final bytes = base64Decode(fixtureFontBase64);
      final imported = await service.importFont(bytes, 'FontVFixture.ttf');
      expect(imported.imported, true);
      expect(imported.name, contains('FontVFixture'));
      expect((await service.importFont(bytes, 'Renamed.otf')).id, imported.id);
      final reloaded = await FontService().loadFonts();
      expect(reloaded.where((f) => f.id == imported.id), hasLength(1));
      final coverage = await service.checkGlyphs(imported.id, 'A한Ω😀');
      expect(coverage.missing.toSet(), {0x3a9, 0x1f600});
      final hangul = await service.hangulFonts();
      expect(hangul, isNotEmpty);
      expect(
        hangul.contains(imported.id),
        false,
        reason:
            'The fixture contains only a few Hangul syllables, not the full modern set.',
      );
      PreviewRequest request({
        double spacing = 0,
        PreviewAlignment alignment = PreviewAlignment.left,
      }) => PreviewRequest(
        fontId: imported.id,
        text: 'AV 한글\nFont V',
        size: 36,
        color: 0xff242329,
        width: 280,
        height: 180,
        scale: 2,
        letterSpacing: spacing,
        lineHeight: 1.7,
        alignment: alignment,
      );
      final plain = await service.render(request());
      final spaced = await service.render(
        request(spacing: 4, alignment: PreviewAlignment.center),
      );
      expect(plain, isNot(orderedEquals(spaced)));
      final imageCodec = await ui.instantiateImageCodec(spaced);
      final rendered = (await imageCodec.getNextFrame()).image;
      final pixels = (await rendered.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!.buffer.asUint8List();
      expect(
        [
          for (var i = 3; i < pixels.length; i += 4) pixels[i],
        ].any((alpha) => alpha > 0),
        true,
        reason: 'Native preview must contain visible glyphs.',
      );
      rendered.dispose();
      imageCodec.dispose();
      final png = await FontImageExporter(service).render(
        face: imported,
        request: request(spacing: 4),
        paper: Colors.white,
        transparent: true,
      );
      expect(png.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);

      final c = FontController(service: service);
      final ads = AdsController(enabled: false);
      addTearDown(ads.dispose);
      await tester.pumpWidget(FontVApp(controller: c, ads: ads));
      await tester.pumpAndSettle(const Duration(milliseconds: 250));
      c.setLanguage(AppLanguage.ko);
      final collectionId = c.createCollection('본문과 제목')!;
      c.setCollectionMembership(collectionId, imported.id, true);
      c.toggleFavorite(imported.id);
      c.setSample('AV 한글\nFont V');
      c.setLetterSpacing(2);
      c.setLineHeight(1.6);
      c.setAlignment(PreviewAlignment.center);
      c.toggleComparison(imported.id);
      c.toggleComparison(system.firstWhere((f) => hangul.contains(f.id)).id);
      await c.flushSettings();
      final restored = FontController(service: FontService());
      await restored.initialize();
      expect(
        restored.collections.any(
          (x) => x.id == collectionId && x.fontIds.contains(imported.id),
        ),
        true,
      );
      expect(restored.letterSpacing, 2);
      expect(restored.lineHeight, 1.6);
      expect(restored.alignment, PreviewAlignment.center);
      restored.dispose();

      final context = tester.element(find.byType(Scaffold).first);
      Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => ComparisonPage(controller: c)),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
      if (defaultTargetPlatform == TargetPlatform.android) {
        await binding.convertFlutterSurfaceToImage();
      }
      await tester.pumpAndSettle();
      await binding.takeScreenshot(
        'font-v-${defaultTargetPlatform.name}-comparison',
      );
      await tester.tap(find.byTooltip('이미지 저장·공유').first);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      for (
        var i = 0;
        i < 20 &&
            find.byKey(const Key('export-image-preview')).evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byKey(const Key('export-image-preview')), findsOneWidget);
      final decodedPreview = find.descendant(
        of: find.byKey(const Key('export-image-preview')),
        matching: find.byType(RawImage),
      );
      for (var i = 0; i < 100; i++) {
        if (decodedPreview.evaluate().isNotEmpty &&
            tester.widget<RawImage>(decodedPreview).image != null) {
          break;
        }
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.widget<RawImage>(decodedPreview).image, isNotNull);
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot(
        'font-v-${defaultTargetPlatform.name}-export',
      );
      Navigator.of(tester.element(find.byKey(const Key('export-save')))).pop();
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(Scaffold).last)).pop();
      await tester.pumpAndSettle();
      await c.removeImportedFont(imported.id);
      expect(c.favorites.contains(imported.id), false);
      expect(c.comparisonIds.contains(imported.id), false);
      expect(c.collections.single.fontIds.contains(imported.id), false);
      expect(
        (await service.loadFonts()).any((f) => f.id == imported.id),
        false,
      );
      await c.flushSettings();
    },
  );
}
