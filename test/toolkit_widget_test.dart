import 'dart:convert';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_v/l10n/app_localizations.dart';
import 'package:font_v/src/app.dart';
import 'package:font_v/src/controller.dart';
import 'package:font_v/src/font_preview.dart';
import 'package:font_v/src/import_tools.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'controller_test.dart' show TestFonts;
import 'toolkit_controller_test.dart' show ToolkitFonts;
import 'fixtures/font_fixture.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'language': 'ko'}));
  testWidgets(
    'phone selects two fonts, compares them, and applies shared typography',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final c = FontController(service: TestFonts());
      await tester.pumpWidget(FontVApp(controller: c));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('compare-mode')));
      await tester.pumpAndSettle();
      Future<void> choose(String query, String id) async {
        await tester.ensureVisible(find.byKey(const Key('font-search')));
        await tester.enterText(find.byKey(const Key('font-search')), query);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(ValueKey('compare:$id')));
        await tester.tap(find.byKey(ValueKey('compare:$id')));
        await tester.pumpAndSettle();
      }

      await choose('Alpha Bold', 'a');
      await choose('Beta', 'b');
      await tester.tap(find.byKey(const Key('open-comparison')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('comparison:a')), findsOneWidget);
      expect(find.byKey(const ValueKey('comparison:b')), findsOneWidget);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.view.physicalSize = const Size(320, 844);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('comparison:a'))).dy,
        tester.getTopLeft(find.byKey(const ValueKey('comparison:b'))).dy,
      );
      c.setLetterSpacing(3);
      c.setLineHeight(1.75);
      await tester.pumpAndSettle();
      for (final preview in tester.widgetList<FontPreview>(
        find.byType(FontPreview),
      )) {
        // Only the comparison route is onstage.
        expect(preview.letterSpacing, 3);
        expect(preview.lineHeight, 1.75);
      }
      expect(tester.takeException(), isNull);
      await c.flushSettings();
    },
  );
  testWidgets(
    'create collection from a preview, save membership, then filter it on home',
    (tester) async {
      final c = FontController(service: TestFonts());
      await tester.pumpWidget(FontVApp(controller: c));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('font-search')), 'Beta');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('font:b')));
      await tester.tap(find.byKey(const ValueKey('font:b')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('font-collections')));
      await tester.tap(find.byKey(const Key('font-collections')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, '새 컬렉션'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('collection-name')), '본문');
      await tester.tap(find.widgetWithText(FilledButton, '적용'));
      await tester.pumpAndSettle();
      expect(c.collections.single.fontIds, {'b'});
      await tester.tap(find.widgetWithText(FilledButton, '완료'));
      await tester.pumpAndSettle();
      c.selectCollection(c.collections.single.id);
      expect(c.visibleFonts.single.id, 'b');
      await c.flushSettings();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'font picker cancellation is harmless and an imported face is listed',
    (tester) async {
      final c = FontController(service: ToolkitFonts());
      await c.initialize();
      XFile? chosen;
      Widget app() => MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: ImportedFontsPage(controller: c, pickFile: () async => chosen),
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pick-font-file')));
      await tester.pumpAndSettle();
      expect(c.fonts.where((f) => f.imported), isEmpty);
      chosen = XFile.fromData(
        base64Decode(fixtureFontBase64),
        name: 'Example.ttf',
      );
      await tester.tap(find.byKey(const Key('pick-font-file')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('imported:import:test')),
        findsOneWidget,
      );
      expect(c.fonts.where((f) => f.imported), hasLength(1));
      expect(tester.takeException(), isNull);
      c.dispose();
    },
  );
}
