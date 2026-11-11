import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_v/src/app.dart';
import 'package:font_v/src/ads.dart';
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

class _FeedAds extends AdsController {
  final hidden = <int>{};
  @override
  Future<void> start() async {}
  @override
  bool get canShowAds => true;
  @override
  bool showSlot(int slot) => !hidden.contains(slot);
  @override
  Widget buildSlot(BuildContext context, int slot) =>
      ColoredBox(color: Colors.white, child: Text('Test ad $slot'));
  void fail(int slot) {
    hidden.add(slot);
    notifyListeners();
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'language': 'ko'}));

  for (final size in [const Size(390, 844), const Size(1200, 900)]) {
    testWidgets(
      'iOS status bar tap scrolls catalog to top at $size',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        tester.view.padding = const FakeViewPadding(top: 24);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetPadding);
        final c = FontController(service: _AlphabetFonts());
        await tester.pumpWidget(FontVApp(controller: c));
        await tester.pumpAndSettle();

        final catalog = find.byKey(const Key('font-catalog-scroll'));
        final scroll = tester.widget<CustomScrollView>(catalog).controller!;
        ScrollPosition? detailPosition;
        if (size.width >= 900) {
          await tester.tap(find.byKey(const ValueKey('font-index:B')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('font:face:1')));
          await tester.pumpAndSettle();
          final detail = find.descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          );
          detailPosition = tester.state<ScrollableState>(detail).position;
          detailPosition.jumpTo(100);
          await tester.pumpAndSettle();
        }

        c.favorites.addAll(c.fonts.map((font) => font.id));
        for (final tab in [0, 1]) {
          c.setTab(tab);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('font-index:Z')));
          await tester.pumpAndSettle();
          expect(scroll.offset, greaterThan(0));
          final detailOffset = detailPosition?.pixels;

          await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
            SystemChannels.statusBar.name,
            SystemChannels.statusBar.codec.encodeMethodCall(
              const MethodCall('handleScrollToTop'),
            ),
            (_) {},
          );
          await tester.pumpAndSettle();

          expect(scroll.offset, 0);
          expect(
            find.byKey(const Key('font-search')).hitTestable(),
            findsOneWidget,
          );
          expect(detailPosition?.pixels, detailOffset);
        }
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }

  testWidgets(
    'feed ads respect family boundaries, index, failures and filters',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = FontController(service: _AlphabetFonts());
      final ads = _FeedAds();
      addTearDown(ads.dispose);
      await tester.pumpWidget(FontVApp(controller: c, ads: ads));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('font-index:H')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('font:face:7')).hitTestable(),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('ad-slot:1')), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('ad-slot:1'))).dy,
        greaterThan(
          tester.getTopLeft(find.byKey(const ValueKey('font:face:7'))).dy,
        ),
      );
      expect(
        tester
            .getRect(
              find.descendant(
                of: find.byKey(const ValueKey('ad-slot:1')),
                matching: find.byType(ColoredBox),
              ),
            )
            .right,
        lessThanOrEqualTo(
          tester.getRect(find.byKey(const ValueKey('font-index:H'))).left,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('font-index:Z')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('font:face:25')).hitTestable(),
        findsOneWidget,
      );
      ads.fail(1);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('font-index:H')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('ad-slot:1')), findsNothing);
      c.setQuery('Family');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('font-index:P')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('ad-slot:2')), findsNothing);
      c.setTab(1);
      await tester.pumpAndSettle();
      expect(find.textContaining('Test ad'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

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
