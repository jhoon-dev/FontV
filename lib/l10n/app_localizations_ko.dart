// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get settingsKicker => '내 취향에 맞게';

  @override
  String get fonts => '폰트';

  @override
  String get favorites => '즐겨찾기';

  @override
  String get settings => '설정';

  @override
  String get language => '언어';

  @override
  String get systemLanguage => '시스템 설정';

  @override
  String get languageDescription =>
      '기기 언어를 따르거나 영어·한국어를 직접 선택하세요. 그 외 언어는 영어로 표시합니다.';

  @override
  String get chooseFont => '서체를 골라보세요.';

  @override
  String get chooseFontSubtitle => '크기와 색을 바꾸며 글자의 표정을 살펴보세요.';

  @override
  String get catalogKicker => '글자를 더 가까이';

  @override
  String get collectionKicker => '나만의 컬렉션';

  @override
  String get catalogHero => '글자마다,\n새로운 가능성.';

  @override
  String get collectionHero => '마음에 담은 서체.';

  @override
  String get browserDemoDescription => '브라우저 데모 · 실제 기기의 폰트는 모바일 앱에서 확인하세요.';

  @override
  String catalogSubtitle(int familyCount, int faceCount) {
    return '$familyCount개 패밀리, $faceCount개 서체. 나만의 조합을 찾아보세요.';
  }

  @override
  String get searchHint => '폰트 이름, 패밀리 검색';

  @override
  String get clearSearch => '검색 지우기';

  @override
  String get retry => '다시 시도';

  @override
  String get noMatches => '일치하는 서체가 없어요.';

  @override
  String get favoritesEmpty => '마음에 드는 서체를 저장해보세요.';

  @override
  String get searchAdvice => '다른 이름이나 패밀리로 검색해보세요.';

  @override
  String get favoritesAdvice => '서체 옆의 북마크를 누르면 여기에 모여요.';

  @override
  String get addFavorite => '즐겨찾기 추가';

  @override
  String get removeFavorite => '즐겨찾기 해제';

  @override
  String previewSemantics(String name, String sample) {
    return '$name 미리보기: $sample';
  }

  @override
  String get sampleEnglish => '영문 샘플';

  @override
  String get sampleKorean => '한글 샘플';

  @override
  String get sampleNumbers => '숫자 샘플';

  @override
  String get customSample => '직접 입력';

  @override
  String get fontSize => '글자 크기';

  @override
  String points(int count) {
    return '$count 포인트';
  }

  @override
  String get textColor => '글자색';

  @override
  String get backgroundColor => '배경색';

  @override
  String get resetPreview => '크기·색상 초기화';

  @override
  String get copyFontName => '폰트 이름 복사';

  @override
  String get fontNameCopied => '폰트 이름을 복사했어요.';

  @override
  String get fallbackHelp =>
      '지원하지 않는 글자는 기기의 대체 폰트로 표시될 수 있어요.\n긴 문장은 미리보기 영역 밖에서 잘릴 수 있어요.';

  @override
  String get previewTitle => '서체 미리보기';

  @override
  String get myFontV => '나의 Font V.';

  @override
  String get theme => '테마';

  @override
  String get themeDescription => '오래전의 다섯 가지 색, 오늘의 새로운 모습.';

  @override
  String get aboutTitle => '글자를 탐색하는 작은 도구.';

  @override
  String get aboutBody =>
      'Font V는 기기에 있는 서체를 살펴보고, 크기와 색을 바꿔보는 앱입니다. 기기의 시스템 폰트를 설치하거나 변경하지 않습니다.\n\n미리보기 문구·즐겨찾기·설정은 이 기기에 저장되며 폰트 탐색은 오프라인으로 사용할 수 있습니다. 광고는 Google AdMob에서 제공하고 네트워크 연결을 사용합니다. 폰트 목록은 기기와 OS에 따라 다릅니다.';

  @override
  String get browserDemoFooter =>
      '브라우저에서는 3가지 데모 서체만 제공합니다. 실제 시스템 폰트 열람은 iOS·Android 앱에서 지원합니다.';

  @override
  String get sampleDialogTitle => '나만의 미리보기 문장';

  @override
  String get sampleInputHint => '여기에 문장을 입력하세요.';

  @override
  String get cancel => '취소';

  @override
  String get apply => '적용';

  @override
  String get invalidHex => '6자리 색상 코드를 입력하세요.';

  @override
  String get families => '폰트 패밀리';

  @override
  String get expandAll => '모두 펼치기';

  @override
  String get collapseAll => '모두 접기';

  @override
  String get expand => '펼치기';

  @override
  String get collapse => '접기';

  @override
  String indexJump(String letter) {
    return '$letter 시작 폰트로 이동';
  }

  @override
  String familySemantics(String family, int count, String action) {
    return '$family, $count개 서체, $action';
  }

  @override
  String familyStyles(int count, String styles) {
    return '$count개 서체 · $styles';
  }

  @override
  String catalogCounts(int families, int faces) {
    return '$families개 · $faces서체';
  }

  @override
  String get fontLoadEmpty => '기기의 폰트 목록을 가져오지 못했어요.';

  @override
  String get fontLoadFailed => '폰트를 불러오지 못했어요. 다시 시도해주세요.';

  @override
  String get storageReadFailed => '설정을 불러오지 못했어요. 앱을 다시 열어주세요.';

  @override
  String get storageWriteFailed => '설정을 저장하지 못했어요. 저장 공간을 확인해주세요.';

  @override
  String get previewRetry => '미리보기 다시 불러오기';

  @override
  String get themePink => '핑크';

  @override
  String get themeRed => '레드';

  @override
  String get themeGreen => '그린';

  @override
  String get themeBrown => '브라운';

  @override
  String get themePurple => '퍼플';

  @override
  String get adLabel => '광고';

  @override
  String get adLoading => '광고 불러오는 중';

  @override
  String get adPrivacy => '광고 개인정보 설정';

  @override
  String get privacyUnavailable => '지금은 개인정보 설정을 열 수 없어요. 잠시 후 다시 시도해 주세요.';
}
