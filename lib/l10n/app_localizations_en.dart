// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsKicker => 'MAKE IT YOURS';

  @override
  String get fonts => 'Fonts';

  @override
  String get favorites => 'Favorites';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'System setting';

  @override
  String get languageDescription =>
      'Follow your device language, or choose English or Korean. Other languages use English.';

  @override
  String get chooseFont => 'Pick a typeface.';

  @override
  String get chooseFontSubtitle =>
      'Explore its character through size and color.';

  @override
  String get catalogKicker => 'A CLOSER LOOK AT LETTERS';

  @override
  String get collectionKicker => 'YOUR COLLECTION';

  @override
  String get catalogHero => 'Every letter,\na new possibility.';

  @override
  String get collectionHero => 'Typefaces you love.';

  @override
  String get browserDemoDescription =>
      'Browser demo · Explore real device fonts in the mobile app.';

  @override
  String catalogSubtitle(int familyCount, int faceCount) {
    return '$familyCount families, $faceCount faces. Find your own combination.';
  }

  @override
  String get searchHint => 'Search fonts and families';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get retry => 'Try again';

  @override
  String get noMatches => 'No matching typefaces.';

  @override
  String get favoritesEmpty => 'Save a typeface you love.';

  @override
  String get searchAdvice => 'Try another name or family.';

  @override
  String get favoritesAdvice => 'Tap a bookmark to collect typefaces here.';

  @override
  String get addFavorite => 'Add to favorites';

  @override
  String get removeFavorite => 'Remove from favorites';

  @override
  String previewSemantics(String name, String sample) {
    return '$name preview: $sample';
  }

  @override
  String get sampleEnglish => 'English sample';

  @override
  String get sampleKorean => 'Korean sample';

  @override
  String get sampleNumbers => 'Number sample';

  @override
  String get customSample => 'Your text';

  @override
  String get fontSize => 'Font size';

  @override
  String points(int count) {
    return '$count points';
  }

  @override
  String get textColor => 'Text color';

  @override
  String get backgroundColor => 'Background';

  @override
  String get resetPreview => 'Reset size and colors';

  @override
  String get copyFontName => 'Copy font name';

  @override
  String get fontNameCopied => 'Font name copied.';

  @override
  String get fallbackHelp =>
      'Unsupported characters may use a fallback font.\nLong text may be clipped by the preview area.';

  @override
  String get previewTitle => 'Typeface preview';

  @override
  String get myFontV => 'Your Font V.';

  @override
  String get theme => 'Theme';

  @override
  String get themeDescription => 'Five familiar colors, a fresh new look.';

  @override
  String get aboutTitle => 'A little tool for exploring letters.';

  @override
  String get aboutBody =>
      'Font V explores typefaces available on your device and previews their size and colors. It does not install or change system fonts.\n\nYour preview text, favorites and settings stay on this device. Font browsing works offline. Ads are provided by Google AdMob and require an internet connection. Available fonts vary by device and OS.';

  @override
  String get browserDemoFooter =>
      'This browser demo offers three sample styles. Real system fonts are available in the iOS and Android apps.';

  @override
  String get sampleDialogTitle => 'Your preview text';

  @override
  String get sampleInputHint => 'Enter your text here.';

  @override
  String get cancel => 'Cancel';

  @override
  String get apply => 'Apply';

  @override
  String get invalidHex => 'Enter a six-digit color code.';

  @override
  String get families => 'Font families';

  @override
  String get expandAll => 'Expand all';

  @override
  String get collapseAll => 'Collapse all';

  @override
  String get expand => 'Expand';

  @override
  String get collapse => 'Collapse';

  @override
  String indexJump(String letter) {
    return 'Jump to fonts starting with $letter';
  }

  @override
  String familySemantics(String family, int count, String action) {
    return '$family, $count styles. $action';
  }

  @override
  String familyStyles(int count, String styles) {
    return '$count styles · $styles';
  }

  @override
  String catalogCounts(int families, int faces) {
    return '$families · $faces faces';
  }

  @override
  String get fontLoadEmpty => 'No device fonts were returned.';

  @override
  String get fontLoadFailed => 'Could not load fonts. Please try again.';

  @override
  String get storageReadFailed =>
      'Could not load settings. Please reopen the app.';

  @override
  String get storageWriteFailed =>
      'Could not save settings. Check available storage.';

  @override
  String get previewRetry => 'Reload preview';

  @override
  String get themePink => 'Pink';

  @override
  String get themeRed => 'Red';

  @override
  String get themeGreen => 'Green';

  @override
  String get themeBrown => 'Brown';

  @override
  String get themePurple => 'Purple';

  @override
  String get adLabel => 'Ad';

  @override
  String get adLoading => 'Loading ad';

  @override
  String get adPrivacy => 'Ad privacy choices';

  @override
  String get privacyUnavailable =>
      'Privacy choices are unavailable right now. Try again later.';
}
