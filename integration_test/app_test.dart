import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:font_v/src/app.dart';
import 'package:font_v/src/ads.dart';
import 'package:font_v/src/controller.dart';
import 'package:font_v/src/font_service.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'real OS catalog, distinct font rendering, search and persistence',
    (tester) async {
      final service = FontService();
      expect(service.isDemo, false);
      final fonts = await service.loadFonts();
      expect(fonts.length, greaterThan(20));
      expect(fonts.map((f) => f.id).toSet().length, fonts.length);
      final candidates = fonts
          .where(
            (f) => RegExp(
              r'Roboto|NotoSerif-Regular|Helvetica|Courier',
            ).hasMatch(f.name),
          )
          .toList();
      expect(candidates.length, greaterThan(1));
      Future<List<int>> render(FontFace face) => service.render(
        PreviewRequest(
          fontId: face.id,
          text: 'Ag 가나다 123',
          size: 32,
          color: 0xFF252329,
          width: 280,
          height: 140,
        ),
      );
      final first = await render(candidates.first);
      final second = await render(candidates.last);
      expect(first.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
      expect(first, isNot(orderedEquals(second)));
      final c = FontController(service: service);
      final ads = AdsController(enabled: false);
      addTearDown(ads.dispose);
      await tester.pumpWidget(FontVApp(controller: c, ads: ads));
      await tester.pumpAndSettle(const Duration(milliseconds: 250));
      expect(c.error, isNull);
      if (defaultTargetPlatform == TargetPlatform.android) {
        await binding.convertFlutterSurfaceToImage();
      }
      await tester.pumpAndSettle();
      await binding.takeScreenshot(
        'font-v-${defaultTargetPlatform.name}-catalog',
      );
      await tester.enterText(
        find.byKey(const Key('font-search')),
        candidates.first.name,
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 250));
      expect(c.visibleFonts, isNotEmpty);
      final selected = c.visibleFonts.first;
      await tester.tap(find.byKey(ValueKey('favorite:${selected.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('font:${selected.id}')));
      await tester.pumpAndSettle(const Duration(milliseconds: 250));
      expect(find.byKey(const Key('preview-canvas')), findsOneWidget);
      c.setSize(48);
      c.setSkin(FontSkin.purple);
      c.setSample('Font V\n가나다 012345');
      await tester.pumpAndSettle(const Duration(milliseconds: 250));
      expect(tester.takeException(), isNull);
      await c.flushSettings();
      final restored = FontController(service: FontService());
      await restored.initialize();
      expect(
        restored.favorites.contains(selected.id),
        c.favorites.contains(selected.id),
      );
      expect(restored.size, 48);
      expect(restored.skin, FontSkin.purple);
      expect(restored.sample, 'Font V\n가나다 012345');
      restored.dispose();
      await tester.pumpAndSettle();
      await binding.takeScreenshot(
        'font-v-${defaultTargetPlatform.name}-preview',
      );
    },
  );
}
