import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_v/src/app.dart';
import 'package:font_v/src/controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'controller_test.dart' show TestFonts;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final language in ['en', 'ko', 'ja']) {
    testWidgets('system $language resolves to supported UI language', (
      tester,
    ) async {
      tester.platformDispatcher.localesTestValue = [Locale(language)];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final c = FontController(service: TestFonts());
      await tester.pumpWidget(FontVApp(controller: c));
      await tester.pumpAndSettle();
      final appContext = tester.element(find.byType(Scaffold).first);
      expect(
        Localizations.localeOf(appContext).languageCode,
        language == 'ko' ? 'ko' : 'en',
      );
      expect(find.text(language == 'ko' ? '설정' : 'Settings'), findsOneWidget);
      expect(find.byType(AppBar).evaluate().single.widget is AppBar, true);
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.byType(Chip)),
        findsNothing,
      );
    });
  }

  testWidgets('settings switch language immediately and persist override', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.localesTestValue = [const Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final c = FontController(service: TestFonts());
    await tester.pumpWidget(FontVApp(controller: c));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('app-language')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('한국어').last);
    await tester.pumpAndSettle();
    expect(c.language, AppLanguage.ko);
    expect(find.text('언어'), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
    await c.flushSettings();
    final restored = FontController(service: TestFonts());
    await restored.initialize();
    expect(restored.language, AppLanguage.ko);
    restored.dispose();
    await tester.tap(find.byKey(const Key('app-language')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('시스템 설정').last);
    await tester.pumpAndSettle();
    expect(c.language, AppLanguage.system);
    expect(find.text('Language'), findsOneWidget);
    await c.flushSettings();
    expect(tester.takeException(), isNull);
  });
}
