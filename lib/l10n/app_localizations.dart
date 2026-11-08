import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @appSupport.
  ///
  /// In en, this message translates to:
  /// **'Help and support'**
  String get appSupport;

  /// No description provided for @openLinkError.
  ///
  /// In en, this message translates to:
  /// **'Could not open this page. Please try again later.'**
  String get openLinkError;

  /// No description provided for @settingsKicker.
  ///
  /// In en, this message translates to:
  /// **'MAKE IT YOURS'**
  String get settingsKicker;

  /// No description provided for @fonts.
  ///
  /// In en, this message translates to:
  /// **'Fonts'**
  String get fonts;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'System setting'**
  String get systemLanguage;

  /// No description provided for @languageDescription.
  ///
  /// In en, this message translates to:
  /// **'Follow your device language, or choose English or Korean. Other languages use English.'**
  String get languageDescription;

  /// No description provided for @chooseFont.
  ///
  /// In en, this message translates to:
  /// **'Pick a typeface.'**
  String get chooseFont;

  /// No description provided for @chooseFontSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explore its character through size and color.'**
  String get chooseFontSubtitle;

  /// No description provided for @catalogKicker.
  ///
  /// In en, this message translates to:
  /// **'A CLOSER LOOK AT LETTERS'**
  String get catalogKicker;

  /// No description provided for @collectionKicker.
  ///
  /// In en, this message translates to:
  /// **'YOUR COLLECTION'**
  String get collectionKicker;

  /// No description provided for @catalogHero.
  ///
  /// In en, this message translates to:
  /// **'Every letter,\na new possibility.'**
  String get catalogHero;

  /// No description provided for @collectionHero.
  ///
  /// In en, this message translates to:
  /// **'Typefaces you love.'**
  String get collectionHero;

  /// No description provided for @browserDemoDescription.
  ///
  /// In en, this message translates to:
  /// **'Browser demo · Explore real device fonts in the mobile app.'**
  String get browserDemoDescription;

  /// No description provided for @catalogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{familyCount} families, {faceCount} faces. Find your own combination.'**
  String catalogSubtitle(int familyCount, int faceCount);

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search fonts and families'**
  String get searchHint;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No matching typefaces.'**
  String get noMatches;

  /// No description provided for @favoritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Save a typeface you love.'**
  String get favoritesEmpty;

  /// No description provided for @searchAdvice.
  ///
  /// In en, this message translates to:
  /// **'Try another name or family.'**
  String get searchAdvice;

  /// No description provided for @favoritesAdvice.
  ///
  /// In en, this message translates to:
  /// **'Tap a bookmark to collect typefaces here.'**
  String get favoritesAdvice;

  /// No description provided for @addFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addFavorite;

  /// No description provided for @removeFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFavorite;

  /// No description provided for @previewSemantics.
  ///
  /// In en, this message translates to:
  /// **'{name} preview: {sample}'**
  String previewSemantics(String name, String sample);

  /// No description provided for @sampleEnglish.
  ///
  /// In en, this message translates to:
  /// **'English sample'**
  String get sampleEnglish;

  /// No description provided for @sampleKorean.
  ///
  /// In en, this message translates to:
  /// **'Korean sample'**
  String get sampleKorean;

  /// No description provided for @sampleNumbers.
  ///
  /// In en, this message translates to:
  /// **'Number sample'**
  String get sampleNumbers;

  /// No description provided for @customSample.
  ///
  /// In en, this message translates to:
  /// **'Your text'**
  String get customSample;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get fontSize;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'{count} points'**
  String points(int count);

  /// No description provided for @textColor.
  ///
  /// In en, this message translates to:
  /// **'Text color'**
  String get textColor;

  /// No description provided for @backgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get backgroundColor;

  /// No description provided for @resetPreview.
  ///
  /// In en, this message translates to:
  /// **'Reset size and colors'**
  String get resetPreview;

  /// No description provided for @copyFontName.
  ///
  /// In en, this message translates to:
  /// **'Copy font name'**
  String get copyFontName;

  /// No description provided for @fontNameCopied.
  ///
  /// In en, this message translates to:
  /// **'Font name copied.'**
  String get fontNameCopied;

  /// No description provided for @fallbackHelp.
  ///
  /// In en, this message translates to:
  /// **'Unsupported characters may use a fallback font.\nLong text may be clipped by the preview area.'**
  String get fallbackHelp;

  /// No description provided for @previewTitle.
  ///
  /// In en, this message translates to:
  /// **'Typeface preview'**
  String get previewTitle;

  /// No description provided for @myFontV.
  ///
  /// In en, this message translates to:
  /// **'Your Font V.'**
  String get myFontV;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeDescription.
  ///
  /// In en, this message translates to:
  /// **'Five familiar colors, a fresh new look.'**
  String get themeDescription;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'A little tool for exploring letters.'**
  String get aboutTitle;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Font V explores typefaces available on your device and previews their size and colors. It does not install or change system fonts.\n\nYour preview text, favorites and settings stay on this device. Font browsing works offline. Ads are provided by Google AdMob and require an internet connection. Available fonts vary by device and OS.'**
  String get aboutBody;

  /// No description provided for @browserDemoFooter.
  ///
  /// In en, this message translates to:
  /// **'This browser demo offers three sample styles. Real system fonts are available in the iOS and Android apps.'**
  String get browserDemoFooter;

  /// No description provided for @sampleDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Your preview text'**
  String get sampleDialogTitle;

  /// No description provided for @sampleInputHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your text here.'**
  String get sampleInputHint;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @invalidHex.
  ///
  /// In en, this message translates to:
  /// **'Enter a six-digit color code.'**
  String get invalidHex;

  /// No description provided for @families.
  ///
  /// In en, this message translates to:
  /// **'Font families'**
  String get families;

  /// No description provided for @expandAll.
  ///
  /// In en, this message translates to:
  /// **'Expand all'**
  String get expandAll;

  /// No description provided for @collapseAll.
  ///
  /// In en, this message translates to:
  /// **'Collapse all'**
  String get collapseAll;

  /// No description provided for @expand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expand;

  /// No description provided for @collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// No description provided for @indexJump.
  ///
  /// In en, this message translates to:
  /// **'Jump to fonts starting with {letter}'**
  String indexJump(String letter);

  /// No description provided for @familySemantics.
  ///
  /// In en, this message translates to:
  /// **'{family}, {count} styles. {action}'**
  String familySemantics(String family, int count, String action);

  /// No description provided for @familyStyles.
  ///
  /// In en, this message translates to:
  /// **'{count} styles · {styles}'**
  String familyStyles(int count, String styles);

  /// No description provided for @catalogCounts.
  ///
  /// In en, this message translates to:
  /// **'{families} · {faces} faces'**
  String catalogCounts(int families, int faces);

  /// No description provided for @fontLoadEmpty.
  ///
  /// In en, this message translates to:
  /// **'No device fonts were returned.'**
  String get fontLoadEmpty;

  /// No description provided for @fontLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load fonts. Please try again.'**
  String get fontLoadFailed;

  /// No description provided for @storageReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load settings. Please reopen the app.'**
  String get storageReadFailed;

  /// No description provided for @storageWriteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save settings. Check available storage.'**
  String get storageWriteFailed;

  /// No description provided for @previewRetry.
  ///
  /// In en, this message translates to:
  /// **'Reload preview'**
  String get previewRetry;

  /// No description provided for @themePink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get themePink;

  /// No description provided for @themeRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get themeRed;

  /// No description provided for @themeGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get themeGreen;

  /// No description provided for @themeBrown.
  ///
  /// In en, this message translates to:
  /// **'Brown'**
  String get themeBrown;

  /// No description provided for @themePurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get themePurple;

  /// No description provided for @adLabel.
  ///
  /// In en, this message translates to:
  /// **'Ad'**
  String get adLabel;

  /// No description provided for @adLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading ad'**
  String get adLoading;

  /// No description provided for @adPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Ad privacy choices'**
  String get adPrivacy;

  /// No description provided for @privacyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Privacy choices are unavailable right now. Try again later.'**
  String get privacyUnavailable;

  /// No description provided for @compare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get compare;

  /// No description provided for @compareSelect.
  ///
  /// In en, this message translates to:
  /// **'Choose fonts to compare'**
  String get compareSelect;

  /// No description provided for @compareHint.
  ///
  /// In en, this message translates to:
  /// **'Choose 2–4 faces from the list. Tap again to remove.'**
  String get compareHint;

  /// No description provided for @compareLimit.
  ///
  /// In en, this message translates to:
  /// **'You can compare up to four fonts.'**
  String get compareLimit;

  /// No description provided for @compareNeedTwo.
  ///
  /// In en, this message translates to:
  /// **'Select at least two fonts to compare.'**
  String get compareNeedTwo;

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get clearSelection;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @addToCompare.
  ///
  /// In en, this message translates to:
  /// **'Add to comparison'**
  String get addToCompare;

  /// No description provided for @removeFromCompare.
  ///
  /// In en, this message translates to:
  /// **'Remove from comparison'**
  String get removeFromCompare;

  /// No description provided for @hangulOnly.
  ///
  /// In en, this message translates to:
  /// **'Korean support'**
  String get hangulOnly;

  /// No description provided for @hangulFilterHelp.
  ///
  /// In en, this message translates to:
  /// **'Shows fonts containing all 11,172 modern Hangul syllables. Jamo and historic characters may differ.'**
  String get hangulFilterHelp;

  /// No description provided for @checkingFonts.
  ///
  /// In en, this message translates to:
  /// **'Checking character support…'**
  String get checkingFonts;

  /// No description provided for @coverageTitle.
  ///
  /// In en, this message translates to:
  /// **'Character support'**
  String get coverageTitle;

  /// No description provided for @coverageComplete.
  ///
  /// In en, this message translates to:
  /// **'All printable characters in this text are supported.'**
  String get coverageComplete;

  /// No description provided for @coverageMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing characters (a fallback font may be used)'**
  String get coverageMissing;

  /// No description provided for @coverageHelp.
  ///
  /// In en, this message translates to:
  /// **'Checks the font’s own character map, before fallback. This does not guarantee shaping of every character sequence.'**
  String get coverageHelp;

  /// No description provided for @coverageError.
  ///
  /// In en, this message translates to:
  /// **'Could not check character support. Try again.'**
  String get coverageError;

  /// No description provided for @deviceFeature.
  ///
  /// In en, this message translates to:
  /// **'Available in the iOS and Android apps.'**
  String get deviceFeature;

  /// No description provided for @letterSpacing.
  ///
  /// In en, this message translates to:
  /// **'Letter spacing'**
  String get letterSpacing;

  /// No description provided for @lineHeight.
  ///
  /// In en, this message translates to:
  /// **'Line height'**
  String get lineHeight;

  /// No description provided for @alignment.
  ///
  /// In en, this message translates to:
  /// **'Alignment'**
  String get alignment;

  /// No description provided for @alignLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get alignLeft;

  /// No description provided for @alignCenter.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get alignCenter;

  /// No description provided for @alignRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get alignRight;

  /// No description provided for @collections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get collections;

  /// No description provided for @newCollection.
  ///
  /// In en, this message translates to:
  /// **'New collection'**
  String get newCollection;

  /// No description provided for @collectionName.
  ///
  /// In en, this message translates to:
  /// **'Collection name'**
  String get collectionName;

  /// No description provided for @collectionNameHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter a unique name, up to 40 characters.'**
  String get collectionNameHelp;

  /// No description provided for @collectionEmpty.
  ///
  /// In en, this message translates to:
  /// **'Create a collection for your next project.'**
  String get collectionEmpty;

  /// No description provided for @collectionManage.
  ///
  /// In en, this message translates to:
  /// **'Manage collections'**
  String get collectionManage;

  /// No description provided for @addToCollection.
  ///
  /// In en, this message translates to:
  /// **'Add to collection'**
  String get addToCollection;

  /// No description provided for @collectionChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose collections for this font.'**
  String get collectionChoose;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteCollectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete collection?'**
  String get deleteCollectionTitle;

  /// No description provided for @deleteCollectionBody.
  ///
  /// In en, this message translates to:
  /// **'Only the collection will be removed. Your fonts and favorites stay saved.'**
  String get deleteCollectionBody;

  /// No description provided for @collectionNoFonts.
  ///
  /// In en, this message translates to:
  /// **'No fonts in this collection yet.'**
  String get collectionNoFonts;

  /// No description provided for @collectionAdvice.
  ///
  /// In en, this message translates to:
  /// **'Open a font and use “Add to collection”.'**
  String get collectionAdvice;

  /// No description provided for @importFonts.
  ///
  /// In en, this message translates to:
  /// **'Import font file'**
  String get importFonts;

  /// No description provided for @importedFonts.
  ///
  /// In en, this message translates to:
  /// **'Imported fonts'**
  String get importedFonts;

  /// No description provided for @importHelp.
  ///
  /// In en, this message translates to:
  /// **'Open a TTF or OTF file to preview it in Font V. Files stay on this device. Up to 32 MB per file, 100 MB total and 50 files.'**
  String get importHelp;

  /// No description provided for @importEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your imported fonts will appear here.'**
  String get importEmpty;

  /// No description provided for @importInvalid.
  ///
  /// In en, this message translates to:
  /// **'This is not a valid single TTF or OTF font.'**
  String get importInvalid;

  /// No description provided for @importTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Choose a font file smaller than 32 MB.'**
  String get importTooLarge;

  /// No description provided for @importLimit.
  ///
  /// In en, this message translates to:
  /// **'The imported font limit is 50 files or 100 MB. Remove a file to continue.'**
  String get importLimit;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not import the font. Check the file and available storage.'**
  String get importFailed;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Font imported. It is now in your font list.'**
  String get importSuccess;

  /// No description provided for @removeImportedTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove imported font?'**
  String get removeImportedTitle;

  /// No description provided for @removeImportedBody.
  ///
  /// In en, this message translates to:
  /// **'Remove this app’s copy and its collection, favorite and comparison entries. The original file stays in its original location.'**
  String get removeImportedBody;

  /// No description provided for @exportImage.
  ///
  /// In en, this message translates to:
  /// **'Save or share image'**
  String get exportImage;

  /// No description provided for @exportInfo.
  ///
  /// In en, this message translates to:
  /// **'Include font details'**
  String get exportInfo;

  /// No description provided for @exportTransparent.
  ///
  /// In en, this message translates to:
  /// **'Transparent background'**
  String get exportTransparent;

  /// No description provided for @exportHelp.
  ///
  /// In en, this message translates to:
  /// **'Export the preview area as a PNG. Long text is clipped to the preview area.'**
  String get exportHelp;

  /// No description provided for @saveImage.
  ///
  /// In en, this message translates to:
  /// **'Save PNG to Files'**
  String get saveImage;

  /// No description provided for @shareImage.
  ///
  /// In en, this message translates to:
  /// **'Share PNG'**
  String get shareImage;

  /// No description provided for @imageSaved.
  ///
  /// In en, this message translates to:
  /// **'Image saved.'**
  String get imageSaved;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not export the image. Please try again.'**
  String get exportFailed;

  /// No description provided for @previewOptions.
  ///
  /// In en, this message translates to:
  /// **'Preview options'**
  String get previewOptions;

  /// No description provided for @fontsUnit.
  ///
  /// In en, this message translates to:
  /// **'fonts'**
  String get fontsUnit;

  /// No description provided for @importedLabel.
  ///
  /// In en, this message translates to:
  /// **'Imported'**
  String get importedLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
