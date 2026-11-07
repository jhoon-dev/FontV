# 초기 버전 검증 결과

검증일: 2026-11-06 (Asia/Seoul)

## 통과한 검증

- Flutter 3.44.2 / Dart 3.12.2에서 `flutter analyze --no-pub` 오류 및 린트 없음.
- 단위·위젯 테스트 9개 통과: 복합 검색, 즐겨찾기, 설정 복원, 오류 후 재시도, 미리보기 요청 병합·캐시·실패 복구, 휴대폰·태블릿·가로 화면과 큰 글자 레이아웃.
- `flutter build web --no-pub` 성공. 390×844와 1200×900 브라우저 화면 확인. 색상 선택기에서 HEX 입력과 적용 확인.
- Android 디버그 빌드 성공. 최종 설치 파일은 `lib/main.dart`를 진입점으로 별도 빌드한 ARM64 APK이며 통합 테스트용 APK와 구분했다.
- Android 13(API 33) 에뮬레이터에서 통합 테스트 통과: 공개 시스템 폰트 API, 고유 ID, PNG 출력, 서로 다른 폰트의 렌더링 차이, 검색, 즐겨찾기, 설정 저장과 새 컨트롤러에서의 복원.
- 해당 에뮬레이터 카탈로그는 177개 패밀리 / 366개 서체였다. 기기별 수치는 달라진다.
- 통합 테스트에서 폰트 목록과 미리보기 화면 캡처를 저장하고 시각적으로 확인했다.
- 소스 ZIP의 CRC와 iOS·Android 구현 포함 여부를 검사했다. 빌드 산출물, 로컬 설정과 서명 키는 소스 ZIP에서 제외했다.

## 검증의 한계

- iOS 소스와 기존 번들 ID 설정을 준비했지만 이 Windows 환경에서는 Xcode 빌드·서명·아이폰 실행을 하지 못했다. 포함한 macOS CI도 아직 실행하지 않았다.
- Android 실기기 테스트와 스토어 출시용 서명·심사는 진행하지 않았다. 제공 APK는 개발용 디버그 서명이다.
- 에뮬레이터는 기존 스냅샷 버전 불일치로 콜드 부팅에 약 15분이 걸렸다. 자동화 설치가 지연되어 APK를 직접 설치한 뒤 기존 VM 서비스에 테스트 드라이버를 연결했다. 기능 테스트는 통과했지만, 이후 Android 운영체제 자체의 `Process system isn't responding` 대화상자도 관찰했다. 이 환경에서의 프레임 속도와 첫 실행 시간은 앱 성능 기준으로 사용할 수 없다. 검증 종료 후 이 작업에서 실행한 에뮬레이터를 종료했다.
- 통합 테스트의 PNG 렌더링 검증은 비트맵 출력과 차이를 검사한다. 전체 문자·전체 폰트의 시각적 일치나 모든 언어의 글리프 지원을 보장하지 않는다.

## 산출물

- `artifacts/font-v-android-arm64-debug.apk`: Android 10+ / ARM64, 개발용 APK
- `artifacts/font-v-source.zip`: 소스 압축본 (새 작업 후 `tool/archive_source.ps1`로 재생성)
- `artifacts/screenshots/font-v-android-catalog.png`: 실제 시스템 폰트 목록 캡처
- `artifacts/screenshots/font-v-android-preview.png`: 네이티브 폰트 미리보기 캡처

초기 APK(2026-11-06) SHA-256: `323FC1CDE012DCF55AB962D2BE4E8ED34B997CEF22A05C8EFC8AED1518138420`

## 2026-11-07 변경 검증

- 화면·웹 메타데이터·문서의 표시를 ToolMoa / jhoon-dev로 정리했다. 설정 화면에는 `ToolMoa`와 `Developed by jhoon-dev`를 구분해 표시한다.
- iOS 번들 ID, Android applicationId와 namespace를 `app.toolmoa.fontv`로 변경했다. Android 진입점 경로와 Dart·Kotlin·Swift 플랫폼 채널도 함께 변경했다.
- 정적 검사와 기존 테스트 9개가 통과했다. 웹 재빌드와 새 ID의 Android ARM64 APK 빌드가 성공했다.
- APK의 패키지 이름(`app.toolmoa.fontv`), 표시 이름(`Font V`), 최소 API 29, ARM64 라이브러리와 디버그 서명을 확인했다.
- 모바일 크기의 브라우저에서 새 표기를 시각적으로 확인했다.
- 새 ID로 변경한 뒤의 Android 에뮬레이터 재설치·통합 테스트와 iOS Xcode 빌드는 아직 하지 않았다. 앞 절의 통합 테스트는 초기 앱 ID에서의 결과다.
- 기존 스토어 앱 제거와 새 앱 등록·출시는 아직 실행하지 않았다. 새 ID는 기존 iOS 앱 업데이트에 사용할 수 없다.

현재 APK SHA-256: `79BDE4E60091A86B8E97DB95D29F01F01237435579F9B5CC80B207C13C4DA7B6`

## 2026-11-07 내부 테스트 준비

- Google Play에 무료 앱 `app.toolmoa.fontv`를 등록했다. 새 업로드 키로 서명한 AAB `2.0.0 (2)`가 Play Console 검증을 통과했고 내부 테스트 트랙에 게시됐다. 현재 계정 한 명을 포함하는 전용 테스터 목록을 연결한 뒤 트랙이 활성 상태임을 확인했다.
- 테스트 참여: https://play.google.com/apps/internaltest/4701307094679828370
- 출시 AAB SHA-256: `d8de2e23e031ce621915b88d62e2a239e5e4c28a6aef9d617c85c92761a39dde`
- Android 업로드 키와 비밀번호는 `.local/signing/` 및 무시된 `android/key.properties`에만 보관했다. 안전한 별도 백업이 필요하다.
- Apple Developer에 명시적 App ID를 등록하고 App Store Connect에 `Font V - ToolMoa`(Apple ID `6831850547`)를 새로 만들었다. `ToolMoa Internal` 그룹과 현재 계정 테스터를 등록했다. 기존 Font V는 아직 제거하지 않았다.
- PM Canvas의 보호된 macOS CI 재사용을 위한 PR: https://github.com/jhoon-dev/PMCanvas/pull/48 . 공개 저장소에는 암호화된 소스만 전달하며 빌드 진단도 암호화한다. 인증서와 API 키는 기존 보호 환경을 벗어나지 않는다. iOS 빌드·업로드 결과는 아래에 별도로 기록한다.
