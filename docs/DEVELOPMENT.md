# Font V 개발 안내

## 앱 표기

설정 화면에는 **ToolMoa**와 **Developed by jhoon-dev**를 구분해 표시한다. 별도 역할 라벨이나 이전 개발자명·도메인은 노출하지 않는다. iOS·Android 앱 ID는 모두 **`app.toolmoa.fontv`**이고, 기존 앱 업데이트가 아닌 새 앱 등록으로 배포한다.

## 제품 범위

기존 iOS Font V(Apple ID `899822294`)의 설명과 등록 스크린샷을 참고해 새로 구현한 Flutter 앱이다. 원본 소스를 복구한 프로젝트가 아니다. iOS와 Android에서 각 기기에 설치된 시스템 폰트를 탐색한다. 폰트 설치, 삭제, 기기 전체의 글꼴 변경은 하지 않는다.

- 시스템 폰트 목록과 패밀리·이름·스타일 검색
- 실제 OS 폰트로 그리는 영문·한글·숫자 미리보기와 직접 입력
- 12–96pt 크기, 글자색·배경색, RGB·HEX 색상 입력
- 즐겨찾기와 다섯 가지 테마(핑크·레드·그린·브라운·퍼플)
- 기기 내부 설정 저장, 오프라인 동작, 태블릿 분할 화면

UI는 기기 언어를 따라 영어·한국어로 표시하며 다른 언어는 영어로 표시한다. 설정에서 시스템 설정·English·한국어를 고를 수 있고 선택은 저장된다. ARB는 `lib/l10n/`에서 관리하며 `flutter gen-l10n`으로 생성한다. 폰트 파일 가져오기, 기기간 동기화, 상점 결제는 포함하지 않았다.

## 목록 광고

Google Mobile Ads 공식 플러그인의 작은 네이티브 템플릿을 사용한다. 전체 목록에서 패밀리 8개마다 광고를 삽입하고 검색·즐겨찾기·372px 미만 화면에서는 표시하지 않는다. 광고 실패 시 해당 슬롯을 제거한다. 오른쪽 인덱스는 광고의 다른 높이까지 반영한다. 앱 시작 시 UMP 동의를 갱신하고 광고 요청 가능 여부를 확인한 뒤 SDK를 초기화한다. 필요한 지역에서는 설정에 광고 개인정보 선택 메뉴가 나타난다. 비개인화 광고 요청을 사용하며 광고가 실패해도 폰트 탐색은 동작한다.

AdMob의 무적알림 앱과 별개로 새 Font V 앱 두 개와 전용 광고 단위를 생성했다. 아래 ID는 공개 SDK 설정값이며 서명 비밀이 아니다.

| 플랫폼 | AdMob 앱 ID | 네이티브 단위 ID |
|---|---|---|
| Android | `ca-app-pub-4326793059395006~9676440694` | `ca-app-pub-4326793059395006/3113892614` |
| iOS | `ca-app-pub-4326793059395006~6572811382` | `ca-app-pub-4326793059395006/2754799967` |

`USE_TEST_ADS`는 기본 true로 Google 공식 샘플 광고를 요청한다. 실제 광고 전환은 공개 스토어 등록 연결·AdMob 검토·개인정보처리방침과 스토어 데이터 수집/광고 선언을 완료한 후 `--dart-define=USE_TEST_ADS=false`를 지정한다. 필요하면 `ADMOB_ANDROID_NATIVE_AD_UNIT_ID` 또는 `ADMOB_IOS_NATIVE_AD_UNIT_ID`로 전용 단위를 덮어쓸 수 있다. 내부 테스트에서 실제 광고를 클릭하지 않는다. 웹 데모에는 AdMob을 초기화하지 않는다.

## 개발 환경

- Flutter 3.44.2 / Dart 3.12.2 (잠금 파일 포함)
- Android: API 29(Android 10) 이상. Android SDK, JDK 21 이상 필요.
- iOS: iOS 15 이상. 빌드·시뮬레이터·서명에는 macOS와 호환되는 Xcode 필요.
- 웹은 화면 검토용 데모이며, 기본 서체의 Regular·Bold·Italic 세 가지 데모 스타일만 제공한다. 웹의 폰트 목록을 모바일 시스템 폰트 목록으로 간주하면 안 된다.

```sh
flutter pub get
flutter run -d <device-id>
flutter run -d chrome          # 브라우저 데모
flutter analyze
flutter test
flutter test integration_test/app_test.dart -d <android-or-ios-device-id>
flutter build apk --debug
```

## 구조

| 위치 | 역할 |
|---|---|
| `lib/src/app.dart` | 폰트 목록, 상세 미리보기, 설정과 반응형 레이아웃 |
| `lib/src/controller.dart` | 검색, 즐겨찾기, 설정, 저장 순서 관리 |
| `lib/src/font_catalog.dart` | 패밀리 접기·펼치기, 전체 펼치기, 오른쪽 문자 인덱스 탭·드래그와 빠른 스크롤 |
| `lib/src/font_catalog_model.dart` | 검색·즐겨찾기로 필터링된 서체의 패밀리 묶음, 영문·한글 초성·기타 문자 인덱스 |
| `lib/src/font_service.dart` | 플랫폼 채널, 폰트 모델, 중복 요청 병합과 12MB LRU 캐시 |
| `lib/src/font_preview.dart` | 비동기 렌더링, 변경 지연과 오래된 응답 배제 |
| `android/app/src/main/kotlin/app/toolmoa/fontv/MainActivity.kt` | Android 폰트 목록, OpenType 이름 읽기, 네이티브 PNG 렌더링 |
| `ios/Runner/AppDelegate.swift` | UIKit 폰트 목록, 네이티브 PNG 렌더링 |

채널 이름은 `app.toolmoa.fontv/fonts`. `getFonts`는 `{id, name, family, style}` 목록을 반환한다. `renderPreview`는 fontId, text, size, color(ARGB), width, height, scale을 받고 투명 PNG 바이트를 반환한다. 텍스트는 1,000자, 논리 크기는 각 변 1,600, 배율은 최대 3으로 제한한다. 네이티브 렌더링은 직렬 작업 큐에서 처리하고 채널 응답은 메인 스레드로 돌려준다.

iOS는 `UIFont.familyNames`와 `fontNames(forFamilyName:)`를 사용한다. Android는 공개 API `SystemFonts.getAvailableFonts()`를 사용하고 각 `Font`의 TTC 인덱스와 variation axes를 유지한다. 같은 TTC 파일의 다른 글꼴이 모두 첫 번째 글꼴로 표시되는 오류를 피하기 위해 OS에서 직접 그린다. 지원하지 않는 문자는 OS fallback이 사용된다. 긴 문장은 고정 미리보기 영역에서 잘릴 수 있다. 운영체제·제조사별로 카탈로그가 다르며 다른 앱의 비공개 폰트까지 열람하지 않는다.

목록은 같은 패밀리의 Regular·Bold·Italic 등을 기본적으로 접어서 보여준다. 검색 시에는 일치하는 스타일만 묶고 자동으로 펼치며, 즐겨찾기에서는 저장한 스타일만 포함한다. 오른쪽 인덱스는 현재 목록에 존재하는 문자만 보여주며 탭과 세로 드래그를 지원한다. 묶음 펼침과 글자 확대에 맞춰 행 위치를 다시 계산해 중간 폰트 미리보기를 모두 만들지 않고 목표 문자로 이동한다. 아이콘은 기존 분홍 배경에 `Font V`를 한 줄로 배치한다. 한 번의 텍스트 윤곽 생성으로 동일한 서체·Regular 굵기·글자 크기·기준선을 적용하며, 글자를 따로 확대하지 않는다. `tool/generate_icons.ps1`에서 iOS·Android·웹 크기를 함께 생성한다.

## Android 출시 실행 검증

Android 출시 최적화에는 `android/app/proguard-rules.pro`를 적용한다. 광고 SDK의 전이 의존성인 Room/WorkManager가 반사로 호출하는 생성자를 보존해야 한다. 디버그 실행만으로 이 문제를 검증할 수 없으므로 `Android internal bundle`은 최적화된 출시 APK를 에뮬레이터에서 두 번 실행한 후에만 AAB를 제공한다. SDK 업데이트 후에도 이 실행 검사를 유지한다.

## iOS 신규 배포

번들 ID는 **`app.toolmoa.fontv`**다. 앱 버전은 2.0.0, 최초 내부 테스트 빌드 번호는 2다. 새 App ID와 App Store Connect 앱 `Font V - ToolMoa`(Apple ID `6831850547`)를 등록했다. 이전 앱의 1.1 초안은 사용하지 않는다. 기존 앱의 판매 중단이나 기록 제거는 별도 작업이다.

Mac에서 다음 작업이 필요하다.

1. `flutter pub get`, `flutter build ios --simulator --debug`로 Swift 컴파일을 확인한다.
2. `ios/Runner.xcworkspace`를 Xcode에서 열어 배포할 Development Team을 선택하고 `app.toolmoa.fontv`를 새 앱으로 등록한다.
3. iPhone/iPad에서 폰트 목록, 미리보기, 키보드, 회전, 설정 복원을 확인한다.
4. 고유 빌드 번호와 최신 스토어 요구사항을 확인하고 Archive/TestFlight로 검증한다.
5. 개인정보·연령 등급·지원 URL·신규 스크린샷과 버전 설명을 준비한 뒤 심사에 제출한다.

Windows에서는 Xcode/Swift iOS 컴파일 및 실제 iPhone 실행을 검증할 수 없다. 현재 소스와 CI는 공개 GitHub 저장소 [jhoon-dev/fontv](https://github.com/jhoon-dev/fontv)에 있다. `iOS TestFlight` 수동 워크플로는 GitHub macOS Runner와 Font V 전용 `apple-testflight` 보호 환경을 사용한다. 기존 Apple Distribution 인증서와 App Store Connect API 키를 암호화 전송으로 이 환경에 이전했다. 프로비저닝 프로필은 Font V App ID용으로 별도 검증한다. 현재 API 키는 프로필 생성 POST 권한이 없어 Apple Developer 화면에서 `Font V ToolMoa App Store`를 발급했다. 프로필 만료·인증서 교체 시 같은 방식으로 새 프로필을 준비한다. `tool/ios_ci.mjs`가 분석·테스트·IPA 빌드·Apple 검증 및 업로드·내부 그룹 배포를 수행한다. 프로덕션 심사는 제출하지 않는다.

GitHub Actions에서 `iOS TestFlight` → `Run workflow`를 선택하고 `main`과 고유한 `build_number`를 지정한다. `distribute_only`는 이미 업로드한 빌드의 처리 상태와 내부 그룹 연결만 확인할 때 사용한다. 새 빌드에는 이 옵션을 끈다. 보호 환경은 `main`에서만 사용할 수 있으며, 서명 비밀번호·P12·P8은 소스에 넣지 않는다. 임시 키체인과 프로비저닝 프로필은 빌드 후 지운다.

공개 Actions에는 `tool/run_ios_ci.mjs`가 암호화한 진단과 비밀값 없는 상태 JSON만 남긴다. `FontV-iOS-encrypted-result` 아티팩트를 다운로드한 뒤 Font V 작업 폴더에서 `node tool/read_ci_diagnostics.mjs <다운로드 경로>/diagnostics.enc.json`으로 확인한다. 로컬 진단 키 `.local/ci/source-key.txt`와 보호 환경의 `FONTV_DIAGNOSTICS_KEY`는 같은 값이며 Git에 포함하지 않는다. 복호화한 로그는 로컬에만 보관하고 공개 이슈나 PR에 그대로 붙이지 않는다. 실행 결과와 실기기 검증 여부는 `VERIFICATION.md`를 따른다.

## Android 배포

패키지 ID는 `app.toolmoa.fontv`다. Play Console에 무료 앱으로 새로 등록했고 `2.0.0 (2)`를 내부 테스트 트랙에 게시했다. iOS 번들 ID와 같은 문자열이지만 플랫폼별 등록과 서명은 별개다.

개발 APK는 디버그 서명이다. 출시용은 `android/key.properties.example`을 `android/key.properties`로 복사하고 업로드 키를 로컬에서 지정한 뒤 `flutter build appbundle --release`로 만든다. 키가 없으면 출시 빌드는 서명하지 않으며 디버그 키로 대체하지 않는다. 키 파일·비밀번호·실제 key.properties는 Git에 넣지 않는다.

GitHub의 `Android internal bundle` 수동 워크플로는 `android-internal` 보호 환경의 업로드 키로 AAB를 서명한다. 고유한 `build_number`를 지정하면 분석·테스트·서명 검증 후 `FontV-Play-internal-AAB` 아티팩트를 만든다. Google Play 업로드는 Play Console 내부 테스트 트랙에서 수행하며, 현재 자동 업로드용 서비스 계정은 등록하지 않았다. Runner의 키 파일과 key.properties는 작업 후 지운다.

## 소스 보관

앱스토어 등록에 소스가 백업되는 것은 아니다. 프로젝트 전체와 잠금 파일은 GitHub `jhoon-dev/fontv`에 커밋·푸시하고, 별도로 백업한다. GitLab 프로젝트는 Git 이력 이전과 GitHub 커밋 일치 확인 후 사용자 승인으로 영구 삭제했다. iOS 서명 자료, Android 업로드 키와 CI 진단 암호화 키는 안전한 별도 위치에 백업한다. 이 자료를 소스 ZIP이나 Git에 포함하지 않는다.

## API 근거

- [Flutter 플랫폼 채널](https://docs.flutter.dev/platform-integration/platform-channels)
- [Apple UIFont.familyNames](https://developer.apple.com/documentation/uikit/uifont/familynames)
- [Android SystemFonts](https://developer.android.com/reference/android/graphics/fonts/SystemFonts)
- [Android CustomFallbackBuilder](https://developer.android.com/reference/android/graphics/Typeface.CustomFallbackBuilder)
- [App Store Connect 빌드 업로드](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds)
