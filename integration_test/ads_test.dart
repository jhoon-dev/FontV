import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:font_v/src/ads.dart';
import 'package:font_v/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// This isolated SDK smoke test always uses Google's official test ad unit.
// The shipped app goes through UMP in AdsController before requesting ads.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native small template loads inside a 320px feed card', (
    tester,
  ) async {
    expect(AdsController.useTestAds, true);
    await MobileAds.instance.initialize();
    String? failure;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 165,
              child: NativeAdCard(
                adUnitId: AdsController().nativeUnitId,
                onUnavailable: () =>
                    failure = 'Official test native ad failed to load',
              ),
            ),
          ),
        ),
      ),
    );
    for (
      var i = 0;
      i < 180 && find.byType(AdWidget).evaluate().isEmpty && failure == null;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(failure, isNull);
    expect(find.byType(AdWidget), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });
}
