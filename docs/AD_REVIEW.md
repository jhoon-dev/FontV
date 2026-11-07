# Font V ad readiness — November 7, 2026

The Android and iOS AdMob registrations and native units belong only to Font V. The existing Ultra Notification app is separate.

## Published prerequisites

- App website: https://toolmoa.app/apps/fontv/
- Privacy policy: https://toolmoa.app/apps/fontv/privacy/
- Support: https://toolmoa.app/apps/fontv/support/
- Authorized seller file: https://toolmoa.app/app-ads.txt
- Public support contact: contact@toolmoa.app
- AdMob European consent message `Font V · European consent` is published for the two Font V apps, with consent, do-not-consent and manage-options choices. Default language is English; the available Google message translations do not include Korean. This does not change the app's English/Korean interface.
- Play's privacy policy, no-login declaration, Tools category and developer website/contact have been saved. These do not publish the app itself.

## MediaView correction

Small native templates have been replaced with medium templates. The native view reserves 400 logical pixels, plus an independently scaled advertising label. iOS's medium media area is 16:9; Android's medium template reserves 190dp for media. The integration test loads Google's official native ads and measures the actual native MediaView, rather than the Flutter card.

Both official video creatives loaded and the actual visible MediaViews passed in [native smoke run 42346893552](https://github.com/jhoon-dev/FontV/actions/runs/42346893552): iOS **320 × 180pt**, Android **310.1 × 190.1dp**. Android's install-ad demo requests had failed in the Google APIs emulator without Play Store (`Incorrect native ad response. Click actions were not properly specified`); the Play Store image resolves this. iOS captures the native hierarchy through the integration driver. Android captures its native video surface through adb before Flutter surface conversion, which would hide texture-composed platform views. Buffered end-of-test console output cannot reliably trigger an external screenshot; the capture flow uses live driver output.

## Release build 9

- iOS [signed workflow](https://github.com/jhoon-dev/FontV/actions/runs/42345393035) succeeded. Build `d5016f17-2d58-4b81-95ec-91dfe784b754` is `IN_BETA_TESTING` in ToolMoa Internal.
- Android [signed workflow](https://github.com/jhoon-dev/FontV/actions/runs/42345392769) succeeded, including two launches of the minified release APK. The AAB SHA-256 is `4801c6d67080e86fe99c46e5affa5df8916cb2568d33d39d232546070dcd0a2e`.
- Play accepted the same AAB and internal release 5 is active as `9 (2.0.0)`, provided to the existing testers.
- Both workflows were dispatched with `ads_mode=live`, which passes `USE_TEST_ADS=false` into the release build. Dedicated SDK integration tests still use Google's demo units.

## Still required before full ad serving

Both apps still need public store listings, matching developer website domains, app-ads.txt verification and AdMob readiness approval. Internal TestFlight/Play releases alone do not satisfy the public-store requirement. Store metadata, required disclosures, age ratings, screenshots and public review must be completed before linking the new listings; do not substitute the original Font V Apple ID or the unrelated notification app.

Google Play's IARC questionnaire explicitly treats use as acceptance of its terms. The user approved the questionnaire and submission in this session. IARC is complete (Everyone/PEGI 3/3+ depending on region); the separate target audience is teens 13+ and adults, since the app is not designed for children. The user supplied the App Store review phone number and email, and those are saved only in App Store Connect, not this public repository. The iOS 2.0.0 draft contains Korean metadata, support/marketing/privacy URLs and build 9, but is not submitted for public review.

Sources: [native ad media policy](https://support.google.com/admob/answer/6329638?hl=en), [app readiness](https://support.google.com/admob/answer/10564477), [app verification](https://support.google.com/admob/answer/14538460), [app-ads.txt setup](https://support.google.com/admob/answer/9363762), [official demo units](https://developers.google.com/admob/android/test-ads).
