# Font V

**ToolMoa** · Developed by **jhoon-dev**.

A new chapter for the original Font V: a local, offline system font explorer for iOS and Android, built with Flutter.

Browse real device fonts, search families and styles, preview your own text, adjust size and RGB/HEX colors, save favorites, and choose one of the original five color themes.

- Application ID (iOS & Android): `app.toolmoa.fontv` — new store listings
- Android 10+
- iOS 13+; macOS and Xcode required for iOS build verification and signing
- Browser target: explicitly labeled UI demo, not a system font catalog

```sh
flutter pub get
flutter run
flutter analyze
flutter test
flutter build apk --debug
```

See [development and release notes](docs/DEVELOPMENT.md) for architecture, native font behavior, and signing setup, and [verification results](docs/VERIFICATION.md) for completed checks and remaining work. The app is implemented from the original listing and screenshots; the original source code was not recovered.
