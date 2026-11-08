# Font V ad readiness — November 8, 2026

The Android and iOS AdMob registrations and native units belong only to Font V. The existing Ultra Notification app is separate.

## Published prerequisites

- App website: https://toolmoa.app/apps/fontv/
- Privacy policy: https://toolmoa.app/apps/fontv/privacy/
- Support: https://toolmoa.app/apps/fontv/support/
- Authorized seller file: https://toolmoa.app/app-ads.txt
- Public support contact: contact@toolmoa.app
- AdMob European consent message `Font V · European consent` is published for the two Font V apps, with consent, do-not-consent and manage-options choices. Default language is English; the available Google message translations do not include Korean. This does not change the app's English/Korean interface.
- AdMob US message `Font V · US privacy choices` is published for the same two apps only, with sale/sharing opt-out choices and Google's applicable-state targeting. The existing UMP integration presents the messages and privacy options.
- Play's privacy policy, no-login declaration, Tools category and developer website/contact have been saved. These do not publish the app itself.

## MediaView correction

Small native templates have been replaced with medium templates. The native view reserves 400 logical pixels, plus an independently scaled advertising label. iOS's medium media area is 16:9; Android's medium template reserves 190dp for media. The integration test loads Google's official native ads and measures the actual native MediaView, rather than the Flutter card.

Both official video creatives loaded and the actual visible MediaViews passed in [native smoke run 42346893552](https://github.com/jhoon-dev/FontV/actions/runs/42346893552): iOS **320 × 180pt**, Android **310.1 × 190.1dp**. Android's install-ad demo requests had failed in the Google APIs emulator without Play Store (`Incorrect native ad response. Click actions were not properly specified`); the Play Store image resolves this. iOS captures the native hierarchy through the integration driver. Android captures its native video surface through adb before Flutter surface conversion, which would hide texture-composed platform views. Buffered end-of-test console output cannot reliably trigger an external screenshot; the capture flow uses live driver output.

[Run 42348362042](https://github.com/jhoon-dev/FontV/actions/runs/42348362042) also passed with live compositor frames enabled in the integration test. The Android capture visibly contains the native video, ad text and CTA.

## Release build 9

- iOS [signed workflow](https://github.com/jhoon-dev/FontV/actions/runs/42345393035) succeeded. Build `d5016f17-2d58-4b81-95ec-91dfe784b754` is `IN_BETA_TESTING` in ToolMoa Internal.
- Android [signed workflow](https://github.com/jhoon-dev/FontV/actions/runs/42345392769) succeeded, including two launches of the minified release APK. The AAB SHA-256 is `4801c6d67080e86fe99c46e5affa5df8916cb2568d33d39d232546070dcd0a2e`.
- Play accepted the same AAB and internal release 5 is active as `9 (2.0.0)`, provided to the existing testers.
- Both workflows were dispatched with `ads_mode=live`, which passes `USE_TEST_ADS=false` into the release build. Dedicated SDK integration tests still use Google's demo units.

## Still required before full ad serving

The Android app is public and linked to AdMob, but app-ads.txt verification has not passed. The iOS public submission is still waiting for Apple review. Both platforms require AdMob readiness approval before full ad serving. Internal TestFlight/Play releases alone do not satisfy the public-store requirement. Do not substitute the original Font V Apple ID or the unrelated notification app.

Google Play's IARC questionnaire explicitly treats use as acceptance of its terms. The user approved the questionnaire and submission in this session. IARC is complete (Everyone/PEGI 3/3+ depending on region); the separate target audience is teens 13+ and adults, since the app is not designed for children. The user supplied the App Store review phone number and email, and those are saved only in App Store Connect, not this public repository.

## Public review progress

- Legacy iOS app `Font V` (Apple ID `899822294`, bundle `com.isdow.apps.FontViewer`): removed from sale in all countries and removed from the active App Store Connect app list on November 8, at the user's request. App Information now offers **Restore App**. Apple says public-store removal can take up to 24 hours. The new app `6831850547` / `app.toolmoa.fontv` is separate.
- Google Play: production build `9 (2.0.0)` and 178 countries/regions are configured. Korean listing text, approved icon, feature graphic and two actual Android screenshots are saved. The manual Data safety declaration and advertising ID declaration are complete. **Twelve changes were submitted to Google for public review on November 8**; the publishing overview confirms they are under review. Managed publishing is disabled, so approval permits automatic publication.
- Subsequent November 8 status check: Google Play confirms the production release is **published at 100%**, with no unpublished changes. The [public Font V listing](https://play.google.com/store/apps/details?id=app.toolmoa.fontv) is available under `jhoon-dev` and exposes the correct developer website `https://toolmoa.app/apps/fontv/`.
- Apple: 175 countries/regions and free pricing are saved. Category, content rights and age questionnaire (4+, ads present) are complete. The seven applicable ad-SDK data types and their purposes/linking/tracking answers were published with the user's explicit confirmation. Actual iPhone screenshots are registered at 1206 × 2622 and 13-inch iPad screenshots at 2048 × 2732. **iOS 2.0.0 (9) was submitted for public review on November 8 at 15:17 KST**, submission `f4046e23-f7e4-4946-8612-9a5a8444409e`; App Store Connect confirms **Waiting for Review**. Release after approval is automatic. [iPad capture run 42453155781](https://github.com/jhoon-dev/FontV/actions/runs/42453155781) passed the real-font integration test and produced the registered screenshots.
- Apple EU DSA: the user supplied contact details and uploaded the requested name/address documents directly to Apple. The business compliance table confirms **In Review** for 27 EU countries. Contact details and verification documents are not stored in this repository.
- AdMob Android: linked the exact public Google Play URL to the existing dedicated app `ca-app-pub-4326793059395006~9676440694`, package `app.toolmoa.fontv`. AdMob still displays the cached store title `app.toolmoa.fontv (unreviewed)`. Initial verification and one recheck after diagnostics failed with an app-ads.txt mismatch message. The app settings confirm Google Play is linked, **Not verified**, **Requires review**; readiness review has **not** been submitted.
- Seller-file diagnostics: both HTTP (redirecting to HTTPS) and HTTPS return status 200 and the exact required ASCII line `google.com, pub-4326793059395006, DIRECT, f08c47fec0942fa0`. The Google-adstxt user agent also receives status 200; there is no restrictive robots.txt. AdMob's crawler table has no records yet and warns that detecting domain changes can take up to seven days. No seller-file correction was indicated by these checks. Recent store-metadata propagation is a possible cause, not a confirmed diagnosis. Google documents up to 24 hours for detecting new developer-website/store-listing data before verification.
- AdMob iOS: the new Apple submission remains **Waiting for Review**, so its dedicated AdMob app is still unlinked and requires review. Neither platform's AdMob verification/readiness approval should be represented as complete.

## Follow-up AdMob diagnosis — November 8, 2026

- Re-running Android app verification replaced the generic seller-details mismatch with the specific error: **developer website not found in the Google Play listing**. A subsequent verification produced the same result. Android remains **Requires review**, with ad serving limited pending verification.
- The public Play listing's expanded App support section already exposes `https://toolmoa.app/apps/fontv/`. Fresh HTTP and HTTPS requests using the `Google-adstxt` user agent both return HTTP 200 at the HTTPS seller-file URL, `text/plain`, and the exact required publisher line. The file contains plain ASCII and a final newline; robots.txt returns 404. These checks do not indicate a seller-file change is needed.
- The account's Policy Center shows **no current policy violations** and **no disapproved apps**. The dedicated iOS AdMob registration still has no linked store and requires review. These are readiness/verification prerequisites, rather than a policy rejection.
- Store metadata propagation is a likely explanation for the discrepancy, but is not confirmed. Google's troubleshooting guide allows up to 24 hours for newly added developer-website/listing data to be detected. Allow that propagation interval before rechecking; if the same error persists, provide Google support with the public listing and seller-file URLs. No app code, seller-file contents, store URL, or unrelated app was changed during this check. Local evidence: ignored `artifacts/admob-check-20261108/verification-error.jpg`.

Sources: [native ad media policy](https://support.google.com/admob/answer/6329638?hl=en), [app readiness](https://support.google.com/admob/answer/10564477), [app verification](https://support.google.com/admob/answer/14538460), [app-ads.txt setup](https://support.google.com/admob/answer/9363762), [official demo units](https://developers.google.com/admob/android/test-ads).
