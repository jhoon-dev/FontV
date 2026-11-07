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

현재 UI 언어는 한국어다. 다국어 UI, 폰트 파일 가져오기, 기기간 동기화, 상점 결제는 이번 초기 버전에 포함하지 않았다.

## 개발 환경

- Flutter 3.44.2 / Dart 3.12.2 (잠금 파일 포함)
- Android: API 29(Android 10) 이상. Android SDK, JDK 21 이상 필요.
- iOS: iOS 13 이상. 빌드·시뮬레이터·서명에는 macOS와 호환되는 Xcode 필요.
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
| `lib/src/font_service.dart` | 플랫폼 채널, 폰트 모델, 중복 요청 병합과 12MB LRU 캐시 |
| `lib/src/font_preview.dart` | 비동기 렌더링, 변경 지연과 오래된 응답 배제 |
| `android/app/src/main/kotlin/app/toolmoa/fontv/MainActivity.kt` | Android 폰트 목록, OpenType 이름 읽기, 네이티브 PNG 렌더링 |
| `ios/Runner/AppDelegate.swift` | UIKit 폰트 목록, 네이티브 PNG 렌더링 |

채널 이름은 `app.toolmoa.fontv/fonts`. `getFonts`는 `{id, name, family, style}` 목록을 반환한다. `renderPreview`는 fontId, text, size, color(ARGB), width, height, scale을 받고 투명 PNG 바이트를 반환한다. 텍스트는 1,000자, 논리 크기는 각 변 1,600, 배율은 최대 3으로 제한한다. 네이티브 렌더링은 직렬 작업 큐에서 처리하고 채널 응답은 메인 스레드로 돌려준다.

iOS는 `UIFont.familyNames`와 `fontNames(forFamilyName:)`를 사용한다. Android는 공개 API `SystemFonts.getAvailableFonts()`를 사용하고 각 `Font`의 TTC 인덱스와 variation axes를 유지한다. 같은 TTC 파일의 다른 글꼴이 모두 첫 번째 글꼴로 표시되는 오류를 피하기 위해 OS에서 직접 그린다. 지원하지 않는 문자는 OS fallback이 사용된다. 긴 문장은 고정 미리보기 영역에서 잘릴 수 있다. 운영체제·제조사별로 카탈로그가 다르며 다른 앱의 비공개 폰트까지 열람하지 않는다.

## iOS 신규 배포

번들 ID는 **`app.toolmoa.fontv`**다. 앱 버전은 2.0.0, 빌드 번호는 2다. 기존 Font V와 다른 앱 ID이므로 새 App ID와 App Store Connect 앱 등록이 필요하며, 이전 앱의 1.1 초안을 사용하지 않는다. 기존 앱의 판매 중단이나 기록 제거는 이 코드 변경만으로 실행되지 않는다.

Mac에서 다음 작업이 필요하다.

1. `flutter pub get`, `flutter build ios --simulator --debug`로 Swift 컴파일을 확인한다.
2. `ios/Runner.xcworkspace`를 Xcode에서 열어 배포할 Development Team을 선택하고 `app.toolmoa.fontv`를 새 앱으로 등록한다.
3. iPhone/iPad에서 폰트 목록, 미리보기, 키보드, 회전, 설정 복원을 확인한다.
4. 고유 빌드 번호와 최신 스토어 요구사항을 확인하고 Archive/TestFlight로 검증한다.
5. 개인정보·연령 등급·지원 URL·신규 스크린샷과 버전 설명을 준비한 뒤 심사에 제출한다.

Windows에서는 Xcode/Swift iOS 컴파일 및 실제 iPhone 실행을 검증할 수 없다. 포함한 GitHub Actions의 macOS 작업은 저장소에 올려 실행하면 서명 없이 시뮬레이터 빌드를 검증한다. 이 워크플로는 아직 원격 실행하지 않았다.

## Android 배포

패키지 ID는 `app.toolmoa.fontv`다. Play Console에서 새 앱으로 등록한다. iOS 번들 ID와 같은 문자열이지만 플랫폼별 등록과 서명은 별개다.

개발 APK는 디버그 서명이다. 출시용은 `android/key.properties.example`을 `android/key.properties`로 복사하고 업로드 키를 로컬에서 지정한 뒤 `flutter build appbundle --release`로 만든다. 키가 없으면 출시 빌드는 서명하지 않으며 디버그 키로 대체하지 않는다. 키 파일·비밀번호·실제 key.properties는 Git에 넣지 않는다.

## 소스 보관

앱스토어 등록에 소스가 백업되는 것은 아니다. 프로젝트 전체와 잠금 파일을 비공개 Git 원격 저장소에 보관하고, 별도로 백업한다. iOS 서명 자료와 Android 업로드 키는 안전한 별도 위치에 백업한다. 이 작업은 원격 저장소 생성이나 소스 업로드를 자동으로 수행하지 않는다.

## API 근거

- [Flutter 플랫폼 채널](https://docs.flutter.dev/platform-integration/platform-channels)
- [Apple UIFont.familyNames](https://developer.apple.com/documentation/uikit/uifont/familynames)
- [Android SystemFonts](https://developer.android.com/reference/android/graphics/fonts/SystemFonts)
- [Android CustomFallbackBuilder](https://developer.android.com/reference/android/graphics/Typeface.CustomFallbackBuilder)
- [App Store Connect 빌드 업로드](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds)
