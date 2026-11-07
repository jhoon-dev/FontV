import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:font_v/src/ads.dart';
import 'package:font_v/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// This isolated SDK smoke test always uses Google's official test ad unit.
// The shipped app goes through UMP in AdsController before requesting ads.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native media is at least 120 x 120 at the minimum feed width',
    (tester) async {
      expect(AdsController.useTestAds, true);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: Text('Initializing test ad SDK'))),
        ),
      );
      debugPrint('Font V smoke: initializing Google Mobile Ads');
      await tester.runAsync(
        () => MobileAds.instance.initialize().timeout(
          const Duration(seconds: 45),
        ),
      );
      debugPrint('Font V smoke: requesting official native test ad');
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
                height: NativeAdCard.extent(TextScaler.noScaling),
                child: NativeAdCard(
                  adUnitId: defaultTargetPlatform == TargetPlatform.iOS
                      ? 'ca-app-pub-3940256099942544/2521693316'
                      : 'ca-app-pub-3940256099942544/1044960115',
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
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
      List<dynamic>? media;
      Object? inspectionError;
      for (var attempt = 0; attempt < 15; attempt++) {
        try {
          media = await const MethodChannel(
            'app.toolmoa.fontv/fonts',
          ).invokeListMethod<dynamic>('inspectNativeAdMedia');
          if (media != null && media.isNotEmpty) break;
        } on PlatformException catch (error) {
          inspectionError = error;
        }
        await tester.pump(const Duration(seconds: 1));
      }
      debugPrint('Font V native inspection: $inspectionError');
      expect(
        media,
        isNotEmpty,
        reason: 'Measure the actual native MediaView, not its Flutter parent',
      );
      for (final frame in media!) {
        debugPrint('Font V native MediaView: $frame');
        expect(frame['width'] as num, greaterThanOrEqualTo(120));
        expect(frame['height'] as num, greaterThanOrEqualTo(120));
        expect(frame['visible'], true);
      }
      debugPrint('Font V smoke: native ad rendered');
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Converting Flutter's surface hides texture-composed native video.
        // The CI host captures adb's screen while this real-time window is open.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 5)),
        );
      } else {
        await binding.takeScreenshot(
          'font-v-${defaultTargetPlatform.name}-native-video',
        );
      }
      await tester.pump(const Duration(seconds: 5));
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
