# Font V 검증 기록

## 2026-11-08 새 기능 포함 내부 테스트 빌드 10

- 소스 `9de6789`에서 `2.0.0 (10)`을 서명 빌드했다. 폰트 비교, 한글 필터·문자 검사, PNG 저장·공유, 컬렉션, 자간·행간·정렬, TTF/OTF 가져오기를 모두 포함한다. 기존 Font V 전용 운영 광고 설정을 사용했다.
- [iOS 서명·검증·업로드 CI](https://github.com/jhoon-dev/FontV/actions/runs/42468739044)가 성공했다. Apple 처리 후 빌드 `46aabc44-86a0-4a25-b4c3-915b67d2e65e`가 `IN_BETA_TESTING` 상태이며, App Store Connect의 기존 `ToolMoa Internal` 그룹에서도 `2.0.0 (10)`의 ‘테스트 중’을 확인했다. 한국어 테스트 안내를 저장했다.
- [Android 서명·출시 시작 검사 CI](https://github.com/jhoon-dev/FontV/actions/runs/42468742686)가 성공했다. 최적화된 출시 APK를 Android 에뮬레이터에서 두 차례 실행한 뒤 제공된 AAB를 사용했다. 내려받은 ZIP 무결성과 이전 빌드 9와 동일한 업로드 인증서도 확인했다.
- AAB SHA-256: `2052fbe4f6d7c4241f457e2ba7badfbadc7cac49005538292738ca829d796214`.
- Play Console이 버전 코드 10, 버전 이름 2.0.0, 최소 API 29, 타겟 SDK 36, ABI 3개를 수락했다. 기존 지원 기기의 감소는 없었다. 한국어·영어 출시 노트를 등록하고 기존 내부 트랙에 게시한 뒤 ‘최신 출시 버전: 10 (2.0.0)’, ‘활성’, ‘내부 테스터에게 제공됨’을 확인했다. [기존 내부 테스트 참여 링크](https://play.google.com/apps/internaltest/4701307094679828370)를 유지한다.
- 새 로컬 파일·컬렉션·이미지 내보내기 설명을 포함한 개인정보처리방침을 [기존 공개 URL](https://toolmoa.app/apps/fontv/privacy/)에 배포했다. HTTP 200과 저장소 원본의 정확한 일치를 확인했다.
- 이번 배포는 기존 내부 테스터 대상이다. App Store 공개 심사 빌드와 Google Play 프로덕션 트랙은 변경하지 않았다. 배포 상태 증빙은 무시된 `artifacts/internal-build10/`에 보관한다.

## 2026-11-08 폰트 활용 기능 6종

- 폰트 2–4개 비교, 한글 필터·문자 지원 검사, PNG 저장·공유, 이름 있는 컬렉션, 자간·행간·정렬, TTF/OTF 가져오기를 추가했다. 영문·한국어 UI와 기존 설정 복원을 유지한다.
- 기능 코드에서 정적 분석 오류·린트가 없고 단위·위젯 테스트 30개가 통과했다. 320px 화면과 1.5배 시스템 글자에서도 비교 미리보기의 시작 위치가 같고 overflow가 없는지 검사한다.
- 로컬 Android 디버그·출시 최적화 빌드와 웹 빌드가 성공했다. 출시 빌드는 `--no-pub`로 이전 디버그용 플러그인 등록 정보를 재사용하면 integration_test 누락 오류가 발생해, 일반 `flutter build apk --release --target-platform android-arm64`로 등록 정보를 재생성하고 성공했다. 기존 출시 CI도 일반 빌드 명령을 사용한다. 출시 APK의 실기기 실행 검증과 빌드 성공은 구분한다. PNG 테스트는 실제 픽셀의 투명도·배경색·정보 영역 크기를 확인한다.
- 양 플랫폼 네이티브 통합 검증은 [첫 실행](https://github.com/jhoon-dev/FontV/actions/runs/42461599211)에서 모두 성공했다. iOS 시뮬레이터와 Android API 36 에뮬레이터에서 실제 테스트 폰트 가져오기·중복 방지·재목록·문자 검사·한글 필터·자간/정렬에 따른 PNG 차이·보이는 픽셀·설정/컬렉션 복원·삭제 후 참조 정리를 검사했다. 테스트 폰트는 한글 일부만 포함하며, 이 폰트가 전체 한글 지원 필터에 잘못 포함되지 않는지도 확인한다.
- [화면 정렬·PNG 미리보기 후속 검증](https://github.com/jhoon-dev/FontV/actions/workflows/toolkit-smoke.yml)은 같은 네이티브 검증에 내보내기 화면의 실제 PNG 미리보기 확인과 캡처를 추가한다. Image 위젯 생성만으로 준비 완료를 판정하지 않고 RawImage의 실제 디코딩된 이미지와 다음 프레임을 기다린다. 해당 실행의 아티팩트에는 플랫폼별 비교 화면과 내보내기 화면이 저장된다.
- iOS 후속 검증은 [실행 42463737536](https://github.com/jhoon-dev/FontV/actions/runs/42463737536)에서 성공했고 비교·내보내기 캡처의 실제 문장과 정보 표시를 확인했다. 같은 실행의 Android 작업은 컴파일러 JAR 다운로드 HTTP 504로 두 번 중단됐다. CI 초기화 스크립트로 해당 컴파일러 모듈만 Google의 Maven Central 미러를 먼저 사용하도록 했다. 앱뿐 아니라 Flutter SDK의 포함 빌드에도 적용하며 모든 Android 빌드 워크플로에서 공통 작업을 사용한다. 미러의 2.3.20 JAR는 Central의 공개 체크섬과 일치했으며 SHA-256은 `976f989d0b5f5d80e8e8a8ad4b73da0bfc27fdd965b9fa38362b2be79ecc1337`이다.
- Flutter SDK가 쓰는 2.2.20 컴파일러도 미러 파일과 Central의 공개 체크섬이 일치했다(SHA-256 `1c6c3f810bfe6a41abcbc34b3a2ef639f1e3f4aeed3a953a4b0974eea4f41889`). 초기화 스크립트로 앱과 Flutter 포함 빌드 설정을 함께 평가하는 `gradlew help`가 성공했다.
- 최종 앱 기능 코드의 [iOS·Android 통합 검증 42466373934](https://github.com/jhoon-dev/FontV/actions/runs/42466373934)은 양쪽 모두 성공했고, Android PNG 내보내기 캡처에서도 실제 문장·폰트 정보가 표시됨을 확인했다. 별도 기본 빌드 CI에서 Gradle 배포 ZIP의 HTTP 504가 재발해, 공식 release API로 같은 ZIP를 wrapper 캐시에 준비하도록 보강했다. ZIP의 SHA-256은 공식 배포 체크섬과 일치했고, 빈 wrapper 캐시에 설치한 Gradle의 `--version` 출력이 9.1.0임을 확인했다.
- 테스트에서 운영체제 파일 저장 대화상자와 외부 공유 대상 앱을 직접 조작하지는 않는다. 네이티브 저장·공유 연결은 구현됐으며 기기별 공급자·대상 앱의 동작은 실기기 확인이 필요하다. 문자 지원 검사는 폰트 자체의 문자 매핑이며, 모든 조합 문자·언어의 조판 결과를 보장하지 않는다.
- 이 기록은 소스 구현과 검증에 관한 것이다. 새 기능을 포함한 TestFlight·Google Play 배포는 별도로 수행한다. 기존 빌드 9의 스토어 상태와 구분한다.

## 초기 버전 검증 결과

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

## GitHub 이전 및 iOS 내부 배포 결과

- 사용자 요청에 따라 소스와 전체 Git 이력을 공개 저장소 https://github.com/jhoon-dev/fontv 로 이전했다. 이전 전후 main 커밋 일치를 확인했고 Git 이력에 실제 서명 키 파일·key.properties·개인 키 본문이 포함되지 않았음을 검사했다. 현재 로컬 origin은 GitHub만 가리킨다.
- GitLab `toolmoa/fontv`(프로젝트 ID 18)는 GitHub 이전 검증 후 사용자의 실행 직전 승인으로 즉시 영구 삭제했다. 삭제 대기 목록에서 사라진 것을 확인했다. 이슈·MR·포크는 각각 0개였다.
- 첫 iOS 서명 빌드는 공유 macOS CI에서 분석과 테스트 9개, Xcode Archive, IPA 내보내기, Apple 업로드 검증 및 실제 업로드까지 성공했다. 업로드 뒤 상태 조회에서 발생한 일시적 EPIPE 연결 오류는 후속 CI에서 연결 재사용 방지와 GET 재시도로 처리했다.
- TestFlight `2.0.0 (2)`는 `ToolMoa Internal` 그룹(테스터 1명)에 연결됐고 초대 발송을 확인했다. 새 Font V 저장소의 전용 CI에서도 기존 빌드를 조회해 `IN_BETA_TESTING` 상태를 확인했다: https://github.com/jhoon-dev/fontv/actions/runs/42333273054 .
- Apple Distribution P12·비밀번호와 App Store Connect API 키는 암호화 전송으로 Font V 전용 `apple-testflight` 환경에 이전했다. Android 업로드 키는 `android-internal` 환경에 저장했다. 두 환경은 main 브랜치에서만 사용할 수 있다. 공개 소스·로그·아티팩트에 평문 서명 자료를 넣지 않았다.
- 일회성 암호화 전송 아티팩트와 PM Canvas의 임시 Font V 전송 키는 제거했고, 공유 저장소에 추가했던 Font V 전용 워크플로는 비활성화했다. 이후 빌드는 Font V 저장소에서 직접 실행한다.
- GitHub의 자동 검증에서 Android 디버그 빌드, iOS 시뮬레이터 빌드가 통과했다. 새 `Android internal bundle` 작업도 업로드 키로 AAB 빌드 및 jarsigner 검증에 성공했다: https://github.com/jhoon-dev/fontv/actions/runs/42333083450 .
- iPhone/iPad와 Android 실기기에서의 최종 사용성 확인은 내부 테스트 참가자가 수행해야 한다. 스토어 프로덕션 심사는 제출하지 않았다.

## 전용 CI 빌드 3 배포

- iOS `2.0.0 (3)`는 Font V 자체 macOS 워크플로에서 분석·테스트·서명 IPA·Apple 업로드와 내부 그룹 배포까지 통과했다: https://github.com/jhoon-dev/fontv/actions/runs/42333299950 . 결과 JSON의 상태는 `IN_BETA_TESTING`이며 빌드 ID는 `9d852f25-a5d6-4923-a69b-2a2c9e298e89`다. 테스트 안내도 등록했다.
- Android `2.0.0 (3)`은 Font V 자체 Linux 워크플로에서 AAB 빌드와 JAR 서명 검증에 성공했다. 서명 인증서가 최초 Play 업로드 키와 동일한지도 다운로드한 PKCS#7 서명에서 대조했다.
- Play Console에서 AAB 3을 수락했고 기존 내부 테스터 목록을 유지한 채 새 버전을 게시했다. 트랙은 활성 상태이며 `최신 출시 버전: 3 (2.0.0)` 및 `내부 테스터에게 제공됨`을 확인했다. 참여 링크는 이전과 같다.
- CI AAB SHA-256: `c1799883440866c2a78dcbc45a7adad8555baf80fe23081c6d7feb4b02ad1197`.
- 서명 자료와 복호화 키를 제외한 소스 ZIP은 `tool/archive_source.ps1`로 재생성한다. 현재 키는 GitHub 보호 환경과 무시된 로컬 보관 위치에만 존재한다.

## 빌드 6 변경 및 로컬 검증

- iOS Debug·Profile·Release 최소 배포 타겟을 13.0에서 15.0으로 올렸다. 서명 CI는 아카이브의 실제 `MinimumOSVersion`이 15.0인지, 포함된 프레임워크의 최소 버전이 앱보다 높지 않은지도 검사한다. iOS 13·14는 이 빌드부터 지원하지 않는다.
- 목록을 패밀리별로 묶고 Regular를 우선 표시한다. 여러 스타일은 기본적으로 접으며 개별/전체 펼치기를 지원한다. 검색은 일치하는 서체만 자동으로 펼치고, 즐겨찾기는 저장한 서체만 묶는다.
- 오른쪽에 영문·한글 초성·기타 문자 인덱스를 추가했다. 탭/드래그로 이동하며 펼친 묶음 수와 글자 확대를 반영해 이동 위치를 계산한다. 인덱스와 북마크 영역은 겹치지 않는다.
- 아이콘은 대문자 F를 사용한 `Font V` 한 줄 배치다. 같은 서체·Regular 굵기·크기·기준선으로 전체 문구를 한 번에 그려 F와 V의 대문자 높이를 맞췄다. 글자를 각각 확대하지 않는다. iOS·Android·웹 아이콘을 동일한 생성기로 갱신했고 iOS 대형 아이콘은 알파 채널 없는 RGB PNG임을 확인했다.
- 단위·위젯 테스트 13개 통과. 추가 검증은 비연속 스타일 묶음과 정렬, 한글 초성, 접기/펼치기와 필터, 1.6배 글자 환경에서 펼친 목록의 Z 탭·A 드래그 복귀·검색 후 이동을 포함한다. 390×844 화면의 대표 데이터로 접힌/펼친/끝 문자 이동 화면을 캡처해 확인했다. 이 캡처는 레이아웃 검증용 데모 데이터다.
- 웹 빌드 성공. 네이티브 서명 빌드와 내부 배포 결과는 후속 기록을 따른다.

## 빌드 6 및 빌드 7 로컬 검증

- 승인된 대문자 `Font V` 아이콘을 포함한 iOS 빌드 6은 서명·아카이브·Apple 업로드 후 `IN_BETA_TESTING`에 도달했다. 아카이브의 실제 최소 iOS 버전은 15.0이다: https://github.com/jhoon-dev/fontv/actions/runs/42336899893 . Android AAB 6도 서명 빌드에 성공했으나 Play에는 게시하지 않았다.
- 빌드 7은 우상단 플랫폼 칩을 제거하고 영어·한국어 UI를 추가했다. 기기 언어 기본값과 미지원 언어의 영어 대체, 설정에서 즉시 전환·저장을 검증했다. 기존 한국어 테스트는 한국어 설정을 명시하고, 뒤로 가기는 번역된 툴팁 대신 실제 BackButton을 사용한다.
- AdMob에 `Font V - Android`, `Font V - iOS`를 새로 등록하고 각 앱의 전용 네이티브 광고 단위를 생성했다. 무적알림 앱과 광고 단위는 재사용하지 않았다. 공개 스토어에 아직 연결하지 않은 상태로 검토 필요/게재 제한을 확인했다. 내부 빌드는 Google 공식 테스트 단위를 사용한다.
- 전체 목록에 패밀리 8개마다 광고를 삽입한다. 위젯 테스트에서는 광고 대역을 사용해 패밀리 경계, 오른쪽 인덱스 이동, 실패 슬롯 제거, 검색·즐겨찾기의 광고 제외와 인덱스 영역 분리를 확인했다. 대역 테스트는 실제 광고 수신을 입증하지 않으므로 별도 네이티브 SDK smoke test를 추가했다.
- 단위·위젯 테스트 총 18개, 정적 분석, 웹 빌드 통과. 390×844의 한국어·영어 설정 및 접힌/펼친/인덱스 이동 화면도 캡처했다. 이 UI 캡처의 폰트 목록은 레이아웃 검증용 대표 데이터다.
- iOS SPM이 `build/ios/SourcePackages/` 아래에 복사한 외부 패키지의 자체 테스트가 앱 분석에 섞이는 문제는 생성 폴더 `build/**`를 제외하도록 수정했다. 앱 소스 및 테스트에 대한 lint 규칙은 유지한다.

## Android 출시 크래시 재현 및 빌드 8

- Play에 배포한 AAB 7을 그대로 다운로드해 bundletool로 설치 APK를 만들고 Android 13에서 실행했다. `InitializationProvider → WorkManager → WorkDatabase` 초기화 중 앱이 종료되는 것을 재현했다: https://github.com/jhoon-dev/fontv/actions/runs/42341494112 . 광고 앱 ID는 정상적으로 포함돼 있었다.
- 광고 SDK의 전이 의존성인 WorkManager 2.7.0 / Room 2.2.5의 오래된 소비자 규칙은 클래스만 보존한다. R8 full mode에서 `WorkDatabase_Impl`과 InputMerger 구현의 인자 없는 생성자가 제거된 것을 실제 매핑 파일에서 확인했다. `android/app/proguard-rules.pro`에 이 두 유형의 반사 생성자를 보존하는 규칙을 추가했다. 전체 최적화를 끄지 않았다. 빌드 8의 매핑에는 해당 생성자가 다시 존재한다.
- Android 서명 워크플로는 이제 AAB와 같은 출시 설정의 APK를 빌드한 뒤, 실제 Android에서 두 번 실행해 프로세스·포그라운드 유지와 앱 로그를 검사한다. 검사를 통과해야 Play용 AAB 아티팩트를 업로드한다. 별도 `Android release runtime`은 성공한 AAB를 직접 설치 가능한 APK로 변환해 재검증하며 기본 입력은 최신 성공 빌드를 선택한다.
- 펼친 패밀리는 테마 색의 폴더 헤더로 표시하고 하위 서체는 들여쓰기와 연결선, 흰색 카드로 구분했다. 하위 항목의 주제목은 Regular·Bold 같은 스타일이고 보조 줄에는 전체 서체 이름을 표시한다. 제목 14–15pt, 보조 글자 12pt로 키웠고 문자 인덱스도 11pt로 올렸다. 전체 설정·설명 라벨의 작은 글자도 확대했다.
- 정적 분석, 단위·위젯 테스트 18개와 웹 빌드 통과. 1.6배 글자 환경의 목록과 빠른 이동을 포함하며, 대표 데이터의 펼친 그룹 및 한국어·영어 설정 캡처도 확인했다.
- iOS 빌드 7은 최소 iOS 15를 유지해 Apple 검증·업로드·내부 그룹 배포에 성공했다: https://github.com/jhoon-dev/fontv/actions/runs/42340802362 . Google UMP의 `100.0` 리소스 스텁은 동적 참조가 없고 원본 정적 SDK 객체가 iOS 12를 지원함을 함께 확인하는 방식으로 검사한다. 실제 로드하는 프레임워크의 OS 요구 버전 검사는 유지한다.

### 빌드 8 CI 최종 결과

- 기본 분석·테스트·Android 디버그 및 iOS 시뮬레이터 빌드: https://github.com/jhoon-dev/fontv/actions/runs/42342340752 — 성공.
- Android 서명 AAB·출시 APK와 실제 두 차례 시작 검사: https://github.com/jhoon-dev/fontv/actions/runs/42342113867 — 성공. AAB SHA-256은 `21eaa646eeadf48ce4bc2687edf83d13c25e7d3f4b10f43ea5408270a3e15851`이다.
- 배포 AAB를 변환해 Android 10(API 29)·13(API 33)·16(API 36)에서 각각 두 번 실행하고 목록을 스크롤한 검사: https://github.com/jhoon-dev/fontv/actions/runs/42342978869 — 세 환경 모두 성공. 이전 AAB 7로 실패했던 동일 실행 경로가 수정 빌드에서 통과했다.
- iOS Google 공식 네이티브 테스트 광고를 320px 템플릿에 실제 로드하고 표시한 검사: https://github.com/jhoon-dev/fontv/actions/runs/42342119807 — 성공. 표시 중의 시뮬레이터 화면도 보관했다. SDK 초기화는 화면을 먼저 만든 뒤 실제 비동기 실행으로 호출하며 테스트와 단계 모두 제한 시간을 둔다.
- iOS 서명·Apple 검증·업로드·내부 테스트: https://github.com/jhoon-dev/fontv/actions/runs/42342116875 — 성공. 빌드 `c09ed159-7d27-429a-9d73-888b3ebd9ec8`의 상태는 `IN_BETA_TESTING`이며 `ToolMoa Internal` 그룹에 연결했다. 한국어 테스트 안내를 저장했다.
- Node 20 기반 Actions는 Node 24 기반 공식 버전으로 갱신하고 SHA를 고정했다. 과거 실패·취소 이력은 보존하며 수정 후 5개 워크플로의 최신 실행은 모두 성공이다.
- Play Console에서 동일한 CI AAB 8을 수락했고 내부 테스트 트랙의 `최신 출시 버전: 8 (2.0.0)`, `활성`, `내부 테스터에게 제공됨`을 확인했다. 기존 테스터 목록을 유지했으며 한국어·영어 출시 안내를 등록했다. 참여 링크는 https://play.google.com/apps/internaltest/4701307094679828370 이다. 광고 포함 선언도 저장했다. App Store/Play 프로덕션 심사와 AdMob의 공개 스토어 연결·게재 검토는 아직 수행하지 않았고 내부 빌드는 테스트 광고를 사용한다.
