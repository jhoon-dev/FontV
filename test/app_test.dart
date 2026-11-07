import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_v/src/app.dart';
import 'package:font_v/src/controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'controller_test.dart' show TestFonts;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('search, open preview, save favorite, and change skin', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = FontController(service: TestFonts());
    await tester.pumpWidget(FontVApp(controller: c));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('font-search')), 'Alpha Bold');
    await tester.pumpAndSettle();
    expect(find.text('Alpha-Bold'), findsOneWidget);
    expect(find.text('Beta-Regular'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('favorite:a')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('font:a')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('preview-canvas')), findsOneWidget);
    await tester.tap(find.text('직접 입력'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('sample-input')),
      '가나다 ABC 123',
    );
    await tester.tap(find.text('적용'));
    await tester.pumpAndSettle();
    expect(c.sample, '가나다 ABC 123');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('즐겨찾기').last);
    await tester.pumpAndSettle();
    expect(find.text('Alpha-Bold'), findsOneWidget);
    expect(find.text('Beta-Regular'), findsNothing);
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('skin:purple')));
    await tester.pumpAndSettle();
    expect(c.skin, FontSkin.purple);
    expect(tester.takeException(), isNull);
    await c.flushSettings();
  });
  testWidgets('tablet shows master/detail without navigating', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      FontVApp(controller: FontController(service: TestFonts())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('font:a')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('preview-canvas')), findsOneWidget);
    expect(find.byKey(const Key('font-search')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('landscape and large text keep the catalog scrollable', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(640, 360);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      FontVApp(controller: FontController(service: TestFonts())),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('font:a')),
      80,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('font:a')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
