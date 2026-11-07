import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_v/src/app.dart';
import 'package:font_v/src/controller.dart';
import 'package:font_v/src/font_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'controller_test.dart' show TestFonts;

class _AlphabetFonts extends FontService {
  @override
  bool get isDemo => true;
  @override
  Future<List<FontFace>> loadFonts() async => [
    for (var i = 0; i < 26; i++)
      FontFace(
        id: 'face:$i',
        name: '${String.fromCharCode(65 + i)} Family-Regular',
        family: '${String.fromCharCode(65 + i)} Family',
        style: 'Regular',
      ),
    const FontFace(
      id: 'a-bold',
      name: 'A Family-Bold',
      family: 'A Family',
      style: 'Bold',
    ),
  ];
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('family folds, expands, searches styles and filters favorites', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = FontController(service: TestFonts());
    await tester.pumpWidget(FontVApp(controller: c));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('family:Alpha')), findsOneWidget);
    expect(find.byKey(const ValueKey('font:a')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('family:Alpha')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('font:a')), findsOneWidget);
    expect(find.byKey(const ValueKey('font:c')), findsOneWidget);
    await tester.tap(find.byKey(const Key('toggle-all-families')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('font:a')), findsNothing);
    await tester.enterText(find.byKey(const Key('font-search')), 'Alpha');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('font:a')), findsOneWidget);
    expect(find.byKey(const ValueKey('font:c')), findsOneWidget);
    expect(find.text('Beta-Regular'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('favorite:a')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('즐겨찾기').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('font:a')), findsOneWidget);
    expect(find.byKey(const ValueKey('font:c')), findsNothing);
    expect(tester.takeException(), isNull);
    await c.flushSettings();
  });

  testWidgets(
    'right index jumps and drags accurately after expanding and filtering',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final c = FontController(service: _AlphabetFonts());
      await tester.pumpWidget(FontVApp(controller: c));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('family:A Family')),
        80,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('family:A Family')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('font:a-bold')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('font-index:Z')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('font:face:25')).hitTestable(),
        findsOneWidget,
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('font-index:Z'))).left,
        greaterThan(
          tester.getRect(find.byKey(const ValueKey('font:face:25'))).right,
        ),
      );
      final start = tester.getCenter(
        find.byKey(const ValueKey('font-index:Z')),
      );
      final end = tester.getCenter(find.byKey(const ValueKey('font-index:A')));
      await tester.timedDragFrom(
        start,
        end - start,
        const Duration(milliseconds: 500),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('family:A Family')).hitTestable(),
        findsOneWidget,
      );
      c.setQuery('B Family');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('font-index:B')), findsOneWidget);
      expect(find.byKey(const ValueKey('font-index:Z')), findsNothing);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('font:face:1')),
        80,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('font:face:1')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
