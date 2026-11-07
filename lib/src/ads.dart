import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'localization.dart';

/// Consent is refreshed at each launch. Font browsing never waits for the SDK.
class AdsController extends ChangeNotifier {
  AdsController({this.enabled = true});
  final bool enabled;
  bool _ready = false;
  bool _initialized = false;
  bool _disposed = false;
  bool _privacyRequired = false;
  int revision = 0;
  final _failedSlots = <int>{};
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  bool get canShowAds => enabled && supported && _ready;
  bool get privacyOptionsRequired => enabled && supported && _privacyRequired;
  bool showSlot(int slot) => canShowAds && !_failedSlots.contains(slot);
  static const useTestAds = bool.fromEnvironment(
    'USE_TEST_ADS',
    defaultValue: true,
  );
  String get nativeUnitId => defaultTargetPlatform == TargetPlatform.iOS
      ? (useTestAds
            ? 'ca-app-pub-3940256099942544/3986624511'
            : const String.fromEnvironment(
                'ADMOB_IOS_NATIVE_AD_UNIT_ID',
                defaultValue: 'ca-app-pub-4326793059395006/2754799967',
              ))
      : (useTestAds
            ? 'ca-app-pub-3940256099942544/2247696110'
            : const String.fromEnvironment(
                'ADMOB_ANDROID_NATIVE_AD_UNIT_ID',
                defaultValue: 'ca-app-pub-4326793059395006/3113892614',
              ));

  Future<void> start() async {
    if (!enabled || !supported) return;
    final completed = Completer<void>();
    void done() {
      if (!completed.isCompleted) completed.complete();
    }

    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          ConsentForm.loadAndShowConsentFormIfRequired((_) async {
            await _refresh();
            done();
          });
        },
        (_) async {
          await _refresh();
          done();
        },
      );
      await completed.future.timeout(
        const Duration(seconds: 45),
        onTimeout: () {},
      );
    } catch (_) {
      /* Unavailable ads must not affect the catalog. */
    }
  }

  Future<void> _refresh() async {
    if (_disposed) return;
    try {
      _privacyRequired =
          await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
      final allowed = await ConsentInformation.instance.canRequestAds();
      if (allowed && !_initialized) {
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(maxAdContentRating: MaxAdContentRating.g),
        );
        await MobileAds.instance.initialize();
        _initialized = true;
      }
      _ready = allowed && _initialized && nativeUnitId.isNotEmpty;
    } catch (_) {
      _ready = false;
    }
    if (!_disposed) notifyListeners();
  }

  Future<bool> openPrivacyOptions() async {
    if (!privacyOptionsRequired) return false;
    final done = Completer<bool>();
    try {
      ConsentForm.showPrivacyOptionsForm((error) async {
        revision++;
        _failedSlots.clear();
        await _refresh();
        if (!done.isCompleted) done.complete(error == null);
      });
    } catch (_) {
      return false;
    }
    return done.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () => false,
    );
  }

  Widget buildSlot(BuildContext context, int slot) => NativeAdCard(
    key: ValueKey('native-ad:$slot:$revision'),
    adUnitId: nativeUnitId,
    onUnavailable: () {
      if (_disposed) return;
      _failedSlots.add(slot);
      notifyListeners();
    },
  );

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class NativeAdCard extends StatefulWidget {
  const NativeAdCard({
    super.key,
    required this.adUnitId,
    required this.onUnavailable,
  });
  final String adUnitId;
  final VoidCallback onUnavailable;
  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  NativeAd? _ad;
  bool _loaded = false;
  @override
  void initState() {
    super.initState();
    _ad = NativeAd(
      adUnitId: widget.adUnitId,
      request: const AdRequest(nonPersonalizedAds: true),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: Colors.white,
        cornerRadius: 14,
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF242329),
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF78767E),
          size: 11,
        ),
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: const Color(0xFFD9437B),
          size: 12,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          unawaited(ad.dispose());
          _ad = null;
          if (mounted) widget.onUnavailable();
        },
      ),
    );
    unawaited(
      _ad!.load().catchError((Object _) {
        if (mounted) widget.onUnavailable();
      }),
    );
  }

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 5),
            child: Text(
              context.l10n.adLabel,
              style: const TextStyle(
                color: Color(0xFF78767E),
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ),
          Expanded(
            child: _loaded && _ad != null
                ? AdWidget(ad: _ad!)
                : Semantics(
                    label: context.l10n.adLoading,
                    child: const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    ),
  );

  @override
  void dispose() {
    unawaited(_ad?.dispose());
    _ad = null;
    super.dispose();
  }
}
