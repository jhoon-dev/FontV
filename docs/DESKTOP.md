# Font V 데스크톱

Windows와 macOS에서도 기기에 설치된 실제 글꼴을 탐색한다. 기존 900px 이상 분할 화면, 검색, 즐겨찾기, 컬렉션, 비교, 가져오기와 PNG 내보내기를 공유한다. 데스크톱에서는 AdMob을 초기화하지 않는다.

## Windows: MSIX만 배포

- Windows 10 1809 이상, x64.
- Flutter 3.44.2, Visual Studio의 **Desktop development with C++**, MSVC C++ 도구, CMake 도구, Windows SDK가 필요하다.
- Flutter 플러그인 링크 생성을 위해 Windows 개발자 모드를 사용하거나 링크 생성 권한이 있는 셸에서 실행한다.
- DirectWrite로 설치 글꼴을 열거하고 실제 얼굴의 glyph index로 문자 지원을 검사한다. DirectWrite/Direct2D/WIC로 자간·행간·정렬을 적용한 투명 PNG를 만든다. 렌더링과 파일 작업은 별도 직렬 스레드에서 처리한다.
- 가져온 글꼴은 LocalAppData 아래 `ToolMoa/FontV/imports`에 보관한다. MSIX 설치 시에는 Windows의 패키지별 파일 시스템 정책이 적용된다. 시스템에 글꼴을 설치하지 않는다.

개발용 MSIX:

```powershell
./tool/build_windows_msix.ps1 -Mode test
```

산출물은 `artifacts/windows/FontV.msix`와 공개 인증서 `FontV-test.cer`다. 패키징 도구의 공용 테스트 인증서를 사용하는 개발 패키지다. 스크립트는 인증서를 신뢰 저장소에 설치하지 않는다. 테스트 PC에서만 공개 인증서를 로컬 컴퓨터의 **Trusted People**에 수동으로 등록한 뒤 MSIX를 설치한다. 이 패키지는 일반 사용자 배포용이 아니다. EXE 설치 프로그램과 포터블 ZIP은 생성·배포하지 않는다. 빌드 중 만들어지는 내부 실행 파일은 MSIX에 포함된다.

Microsoft Store 제출용:

```powershell
./tool/build_windows_msix.ps1 -Mode store `
  -IdentityName '<Partner Center Package/Identity/Name>' `
  -Publisher '<Partner Center Package/Identity/Publisher>' `
  -PublisherDisplayName '<Partner Center PublisherDisplayName>' `
  -Version '2.0.1.0'
```

Store 모드는 Store에서 서명할 MSIX를 만든다. 저장소의 `app.toolmoa.fontv`와 `CN=ToolMoa`는 로컬 기본값이며 Store에 등록된 ID라고 가정하지 않는다. Store 업로드는 자동 실행하지 않는다. MSIX 버전은 pubspec의 빌드 번호를 자동으로 사용하지 않으므로 업데이트마다 네 자리 `-Version`을 증가시킨다. Store 제출 시 마지막 자리는 `0`으로 유지한다.

외부 배포용 인증서가 있는 경우 `FONTV_MSIX_CERTIFICATE_PATH`, `FONTV_MSIX_CERTIFICATE_PASSWORD` 환경변수를 설정하고 `-Mode signed -Publisher '<인증서 Subject>'`로 만든다. 서명 검증이 성공해야 완료된다. 인증서와 암호는 저장소에 넣지 않는다.

## macOS

- macOS 10.15 이상. 빌드에는 Flutter 3.44.2와 호환 Xcode가 필요하다.
- 앱 이름 `Font V`, 번들 ID `app.toolmoa.fontv`.
- Core Text의 설치 글꼴 descriptor를 사용하며, 기존 iOS와 같은 문자 지원 검사와 렌더링 방식을 사용한다. 글꼴 처리와 PNG 인코딩은 별도 직렬 큐에서 실행한다.
- 앱 샌드박스에서 사용자가 선택한 파일의 읽기·쓰기를 허용한다. 가져온 글꼴은 샌드박스 Application Support의 `FontV-imports`에 저장한다.

```sh
flutter run -d macos
bash tool/build_macos.sh
```

`artifacts/macos/FontV.dmg`에 `Font V.app`과 Applications 바로가기를 넣는다. 기본 산출물은 개발 확인용이며, 일반 배포에 필요한 Developer ID 서명과 Apple 공증을 수행하지 않는다. 정식 배포 전 앱·중첩 프레임워크 서명, notarization, stapling 및 깨끗한 Mac에서 Gatekeeper 설치 검증이 필요하다. iOS 배포 인증서를 macOS Developer ID 인증서로 재사용하지 않는다.

## 공통 동작과 검증

TTF/OTF 가져오기는 파일당 32MB, 전체 100MB, 50개 제한과 SHA-256 중복 제거를 유지한다. PNG 저장은 `file_selector`의 OS 저장 대화상자를 사용한다. 사용자가 취소하면 저장하지 않는다. 파일 공유는 기존 `share_plus`를 사용한다.

```sh
flutter analyze
flutter test
flutter test integration_test/desktop_test.dart -d windows
# Mac에서는 마지막 명령 대신:
flutter test integration_test/desktop_test.dart -d macos
```

`Desktop builds` CI는 각 OS에서 실제 시스템 글꼴, 잘못된 가져오기, 중복 제거, 재조회 후 유지, 한글·보조 평면 문자 지원, PNG 크기·투명도·실제 픽셀, 자간 변화, 즐겨찾기·컬렉션 유지·정리를 검사한다. Windows는 MSIX와 공개 테스트 인증서만, Mac은 개발용 DMG를 아티팩트로 보관한다. CI는 소스에 추가했으며 아직 원격으로 실행하지 않았다.

2026-11-10 로컬 환경에서는 C++ 빌드 도구와 플러그인 심볼릭 링크 권한 부족으로 Windows 빌드가 차단되었다. Windows 호스트에서는 macOS 빌드를 실행할 수 없다. 두 설치 파일의 생성 성공이나 설치 완료를 검증한 상태는 아니다. 패키지 설치 후 파일 선택·취소, PNG 저장·공유, 재실행 후 가져온 글꼴 유지, 업데이트 설치는 두 OS에서 별도로 확인해야 한다.

API 및 패키징 근거: [Flutter 데스크톱](https://docs.flutter.dev/platform-integration/desktop), [MSIX 도구](https://pub.dev/packages/msix), [DirectWrite 문자 간격](https://learn.microsoft.com/en-us/windows/win32/api/dwrite_1/nf-dwrite_1-idwritetextlayout1-setcharacterspacing), [Microsoft Store 버전 규칙](https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/package-version-numbering).
