# Font V

**ToolMoa** · Developed by **jhoon-dev**.

A new chapter for the original Font V: a system font explorer for iOS, Android, Windows and macOS, built with Flutter. Font browsing and previews work offline; mobile catalog ads use the internet.

Source and CI: [jhoon-dev/fontv on GitHub](https://github.com/jhoon-dev/fontv). iOS TestFlight signing runs on GitHub's macOS runner; Android release bundles use a Linux runner. Signing credentials are held in protected Actions environments.

Browse real device fonts grouped into collapsible families, jump through the catalog using the right-hand letter index, search families and styles, preview your own text, adjust size and RGB/HEX colors, save favorites, and choose one of the original five color themes.

- Compare 2–4 font faces side by side using shared text and typography controls.
- Filter fonts covering all 11,172 modern Hangul syllables and inspect missing characters without counting system fallback as font support.
- Adjust letter spacing, line height and alignment alongside size and colors.
- Create, rename and remove named collections; keep their font memberships locally.
- Export the preview as a PNG with optional font details and transparency; save through the system file picker or share sheet.
- Import single TTF/OTF files into app-local storage (32 MB/file, 100 MB total, 50 files). SHA-256 IDs deduplicate files; removal cleans saved references while preserving the original source file.

- Application ID (iOS & Android): `app.toolmoa.fontv` — new store listings
- Android 10+
- iOS 15+; macOS and Xcode required for iOS build verification and signing
- Windows 10 1809+ (x64): MSIX distribution only; desktop C++ tooling required
- macOS 10.15+: native desktop target and development DMG packaging; Xcode required
- Browser target: explicitly labeled UI demo, not a system font catalog
- English and Korean UI: follows the device language by default, with a saved override in Settings
- AdMob native ads between every eight font families; manual release workflows select `test` (default) or Font V's `live` ad units

```sh
flutter pub get
flutter run
flutter analyze
flutter test
flutter build apk --debug
```

Desktop packaging and native checks: [Windows MSIX / macOS instructions](docs/DESKTOP.md). Windows and macOS native integration checks pass on GitHub Actions. The Windows MSIX has also been installed and exercised on Windows 11, including font import, transparent PNG saving and persistence after restart. Desktop ads are disabled.

`Font toolkit native checks` runs the real font-file import/coverage/render/export integration test on iOS and Android and captures the comparison UI. Its small renamed Noto Sans KR test fixture is licensed under SIL OFL 1.1 in `test/fixtures/OFL.txt` and is not bundled into normal app builds.

See [development and release notes](docs/DEVELOPMENT.md) for architecture, native font behavior, and signing setup, and [verification results](docs/VERIFICATION.md) for completed checks and remaining work. The app is implemented from the original listing and screenshots; the original source code was not recovered.

App information: [Font V](https://toolmoa.app/apps/fontv/), [privacy policy](https://toolmoa.app/apps/fontv/privacy/), and [support](https://toolmoa.app/apps/fontv/support/). Static sources are in `site/`; they deploy only to `/apps/fontv/` and the domain-root `app-ads.txt`, preserving the existing ToolMoa website.
