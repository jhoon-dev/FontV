# Font V icons

Regenerate the existing wordmark with:

```powershell
./tool/generate_icons.ps1
./tool/generate_desktop_icons.ps1
```

- Windows ICO/MSIX, macOS asset catalog, website and ordinary web icons use transparent rounded corners (22% radius). macOS also has an 8% transparent margin.
- Android has an opaque background and a separate foreground in its adaptive icon; the launcher applies its own mask. Rounded PNGs are the fallback. The foreground stays inside the adaptive safe zone.
- iOS and `app-store-icon.png` (1024 px) are opaque: Apple applies its own corner mask.
- `google-play-icon.png` (512 px) is opaque and full-bleed: Google Play applies its own corners and shadow. Upload this file to each localized listing.
- Web maskable icons remain opaque with the wordmark inside the safe circle.

Keep the pink `#D9437B` background and the existing single-run Segoe UI Regular wordmark.

Platform references: [Apple app icons](https://developer.apple.com/design/human-interface-guidelines/app-icons), [Google Play icon specifications](https://developer.android.com/distribute/google-play/resources/icon-design-specifications), [Android adaptive icons](https://developer.android.com/develop/ui/views/launch/icon_design_adaptive).
