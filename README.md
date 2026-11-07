# Font V

**ToolMoa** · Developed by **jhoon-dev**.

A new chapter for the original Font V: a system font explorer for iOS and Android, built with Flutter. Font browsing and previews work offline; optional catalog ads use the internet.

Source and CI: [jhoon-dev/fontv on GitHub](https://github.com/jhoon-dev/fontv). iOS TestFlight signing runs on GitHub's macOS runner; Android release bundles use a Linux runner. Signing credentials are held in protected Actions environments.

Browse real device fonts grouped into collapsible families, jump through the catalog using the right-hand letter index, search families and styles, preview your own text, adjust size and RGB/HEX colors, save favorites, and choose one of the original five color themes.

- Application ID (iOS & Android): `app.toolmoa.fontv` — new store listings
- Android 10+
- iOS 15+; macOS and Xcode required for iOS build verification and signing
- Browser target: explicitly labeled UI demo, not a system font catalog
- English and Korean UI: follows the device language by default, with a saved override in Settings
- AdMob native ads between every eight font families; internal builds use official Google test ads

```sh
flutter pub get
flutter run
flutter analyze
flutter test
flutter build apk --debug
```

See [development and release notes](docs/DEVELOPMENT.md) for architecture, native font behavior, and signing setup, and [verification results](docs/VERIFICATION.md) for completed checks and remaining work. The app is implemented from the original listing and screenshots; the original source code was not recovered.
