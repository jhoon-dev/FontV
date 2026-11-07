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
