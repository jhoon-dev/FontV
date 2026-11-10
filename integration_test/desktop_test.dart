import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:font_v/src/ads.dart';
import 'package:font_v/src/app.dart';
import 'package:font_v/src/controller.dart';
import 'package:font_v/src/font_export.dart';
import 'package:font_v/src/font_service.dart';
import '../test/fixtures/font_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('desktop native catalog, imports, coverage, PNG and wide UI', (
    tester,
  ) async {
    expect(
      defaultTargetPlatform,
      anyOf(TargetPlatform.windows, TargetPlatform.macOS),
    );
    final service = FontService();
    expect(service.isDemo, false);
    final system = await service.loadFonts();
    expect(system.length, greaterThan(20));
    expect(system.every((font) => !font.id.startsWith('demo:')), true);
    expect(system.map((font) => font.id).toSet().length, system.length);
    await expectLater(
      service.importFont(Uint8List.fromList([0, 1, 2, 3]), 'broken.ttf'),
      throwsA(isA<PlatformException>()),
    );
    await expectLater(
      service.removeImportedFont('import:../../outside'),
      throwsA(isA<PlatformException>()),
    );
    final bytes = base64Decode(fixtureFontBase64);
    final face = await service.importFont(bytes, 'FontVFixture.ttf');
    addTearDown(() => service.removeImportedFont(face.id));
    expect(face.imported, true);
    expect(face.name, contains('FontVFixture'));
    expect((await service.importFont(bytes, 'Renamed.otf')).id, face.id);
    expect(
      (await service.loadFonts()).where((font) => font.id == face.id),
      hasLength(1),
    );
    expect((await service.checkGlyphs(face.id, 'A한Ω😀')).missing.toSet(), {
      0x3a9,
      0x1f600,
    });
    final hangul = await service.hangulFonts();
    expect(hangul, isNotEmpty);
    expect(hangul, isNot(contains(face.id)));
    PreviewRequest request(double spacing) => PreviewRequest(
      fontId: face.id,
      text: 'AV 한글\nFont V',
      size: 36,
      color: 0xff242329,
      width: 280,
      height: 180,
      scale: 2,
      letterSpacing: spacing,
      lineHeight: 1.7,
      alignment: PreviewAlignment.center,
    );
    // Exercise an actual system font as well as the imported collection.
    final systemPng = await service.render(
      PreviewRequest(
        fontId: system.first.id,
        text: 'Font V',
        size: 32,
        color: 0xff242329,
        width: 280,
        height: 180,
      ),
    );
    expect(systemPng.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
    final plain = await service.render(request(0));
    final spaced = await service.render(request(4));
    expect(plain, isNot(orderedEquals(spaced)));
    final codec = await ui.instantiateImageCodec(spaced);
    final image = (await codec.getNextFrame()).image;
    expect(image.width, 560);
    expect(image.height, 360);
    final pixels = (await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!.buffer.asUint8List();
    final alphas = [for (var i = 3; i < pixels.length; i += 4) pixels[i]];
    expect(alphas.any((alpha) => alpha > 0), true);
    expect(alphas.any((alpha) => alpha == 0), true);
    image.dispose();
    codec.dispose();
    final png = await FontImageExporter(service).render(
      face: face,
      request: request(4),
      paper: Colors.white,
      transparent: true,
    );
    expect(png.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
    final controller = FontController(service: service);
    final ads = AdsController();
    expect(ads.supported, false);
    await ads.start();
    expect(ads.canShowAds, false);
    addTearDown(ads.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(FontVApp(controller: controller, ads: ads));
    for (var i = 0; i < 200 && controller.loading; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(controller.loading, false);
    expect(controller.error, isNull);
    await tester.pumpAndSettle();
    if (!controller.favorites.contains(face.id)) {
      controller.toggleFavorite(face.id);
    }
    final collection = controller.createCollection(
      'Desktop ${DateTime.now().millisecondsSinceEpoch}',
    )!;
    controller.setCollectionMembership(collection, face.id, true);
    await controller.flushSettings();
    final restored = FontController(service: FontService());
    await restored.initialize();
    expect(restored.favorites, contains(face.id));
    expect(
      restored.collections.firstWhere((item) => item.id == collection).fontIds,
      contains(face.id),
    );
    restored.dispose();
    expect(tester.takeException(), isNull);
    await controller.removeImportedFont(face.id);
    expect(controller.favorites, isNot(contains(face.id)));
    expect(
      controller.collections
          .firstWhere((item) => item.id == collection)
          .fontIds,
      isNot(contains(face.id)),
    );
    expect(
      (await service.loadFonts()).any((font) => font.id == face.id),
      false,
    );
    controller.deleteCollection(collection);
    await controller.flushSettings();
  });
}
