# Lynx XCFramework 추출 · 배포 가이드

Lynx iOS SDK는 CocoaPods로만 배포된다. 이 저장소는 pod 산출물을 XCFramework로 재패키징해
CocoaPods 없는 환경(SPM `binaryTarget`, Tuist xcframework 의존성)에서 소비할 수 있게 한다.

## 1. 파이프라인

`./build.sh` 하나가 전 과정을 자동화한다:

1. **아카이브 ×2** — `Lynx-XcFramework.xcworkspace`의 `Lynx-XcFramework` scheme을
   `generic/platform=iOS`와 `generic/platform=iOS Simulator` 두 destination으로 아카이브한다.
   - `SKIP_INSTALL=NO` + `BUILD_LIBRARY_FOR_DISTRIBUTION=YES` + `ONLY_ACTIVE_ARCH=NO`
   - 서명 비활성 (`CODE_SIGNING_ALLOWED=NO`) — 프레임워크만 뽑을 것이므로 아카이브 서명은 생략
   - 산출: `build/ios_device.xcarchive`, `build/ios_sim.xcarchive` (+ 각 `.log`)
2. **create-xcframework** — 각 아카이브의 `Products/Library/Frameworks/<F>.framework`를
   `FRAMEWORKS` 배열 항목별로 병합해 `Results/<F>.xcframework`를 만든다.
3. **PrivateHeaders 제거** (`SLIM_HEADERS=1`, 기본) — 서명 직전에 슬라이스별
   `PrivateHeaders/`를 지운다. 어느 프레임워크에도 `module.private.modulemap`이 없어서
   모듈로는 노출되지 않는 헤더들이다 (Lynx 909개 6.3MB, LynxBase 137개 1.7MB,
   LynxService 12KB, SDWebImage 84KB — 슬라이스당 ~8MB). 앱 바이너리 크기와는 무관하고
   배포 용량만 줄인다: `Lynx.xcframework.zip` 13.98MB → 10.93MB (-22%).

   호환성은 실측으로 확인했다. `@import Lynx`(Swift/ObjC 경로)는 제거 전후 모두 컴파일된다.
   public 헤더 4개 — `LynxContext+Internal.h`, `LynxBackgroundRuntime+Internal.h`,
   `LynxTemplateData+Converter.h`, `LynxUIRendererProtocol.h` — 가 `#if defined(__cplusplus)`
   블록에서 private 헤더를 include하지만, `core/shell/ios/js_proxy_darwin.h`처럼 소스트리
   상대경로를 쓰기 때문에 flat한 `PrivateHeaders/` 레이아웃에서는 **제거 전에도 똑같이
   `file not found`로 실패한다** (pod 빌드 안에서만 `HEADER_SEARCH_PATHS`로 해석되는 경로다).
   즉 소비 측에서 원래 도달할 수 없던 헤더들이라 제거해도 달라지는 것이 없다.

   > 그래도 소비 측 빌드가 깨지면 `SLIM_HEADERS=0`으로 되돌린다.
4. **codesign** — 완성된 xcframework에만 서명한다 (`SIGN_IDENTITY`, 기본 `TFLQDNW4Z9`).
5. 마지막에 xcframework별 슬라이스 목록을 출력한다. 정상 산출물은
   `ios-arm64`(실기기) + `ios-arm64_x86_64-simulator` 두 슬라이스를 가진다.

`pod install`/`pod update` 단계에서는 Podfile의 `post_install`이 Lynx 타깃의 `.cc`/`.c`/`.cpp`
소스에 `-fvisibility=hidden`을 붙이고 `EXPORT_SYMBOLS_FOR_DEVTOOL`을 0으로 내린다.
Lynx는 원래 hidden 전제로 공개 API에만 `LYNX_EXPORT`를 붙여 놓았는데(80곳) podspec에 그 설정이
없어서 엔진 내부 C++ 심볼 1만여 개가 그대로 export되고, 그 탓에 `DEAD_CODE_STRIPPING`과 thin LTO가
무력화된다. `.m`/`.mm`을 제외하는 이유는 ObjC 클래스 심볼까지 hidden 되면 소비 측이 상속하는
`LynxUI`·`LynxPropsProcessor`·`LynxCustomMeasureShadowNode` 등 8개 클래스의 링크가 깨지기 때문이고,
Lynx 타깃에만 거는 이유는 Lynx가 LynxBase/PrimJS의 C++ 심볼 375개를 프레임워크 너머로 쓰기 때문이다.
끄려면 `HIDE_SYMBOLS=0 pod update`.

옵션 (환경변수):

| 변수 | 기본값 | 설명 |
|---|---|---|
| `PLATFORMS` | `both` | `device` / `sim` — 한쪽 슬라이스만 빌드 (sim은 로컬 반복용) |
| `SIGN_IDENTITY` | `TFLQDNW4Z9` | 빈 값이면 서명 생략 |
| `INCLUDE_DSYM` | `0` | `1`이면 dSYM 동봉 — 크래시 심볼리케이션 가능하지만 77MB → ~860MB |
| `REUSE_ARCHIVE` | `0` | `1`이면 기존 `build/*.xcarchive` 재사용, xcframework만 재생성 |
| `SLIM_HEADERS` | `1` | `0`이면 `PrivateHeaders/`를 남긴다 (기본은 제거 — 아래 참고) |

## 2. 산출물

`Results/`에 8개가 생긴다. 전부 배포 대상이다:

```
Lynx.xcframework                  ← LynxBase / LynxServiceAPI / PrimJS 링크
LynxBase.xcframework
LynxServiceAPI.xcframework
LynxService.xcframework           ← Lynx / SDWebImage / SDWebImageWebPCoder 링크
PrimJS.xcframework
SDWebImage.xcframework
SDWebImageWebPCoder.xcframework   ← libwebp 링크
libwebp.xcframework
```

추출 앵커인 `Lynx-XcFramework` framework 타깃은 xcframework로 만들지 않는다. 이 타깃의
소스는 `Lynx-XcFramework/Anchor.swift` 하나뿐이다 — 아카이브 시 모든 pod가 함께 빌드되게
하는 앵커 역할만 하며, 소스가 하나도 없으면 프레임워크 링크가 실패할 수 있어 유지한다.
산출물 자체는 소비 측에 불필요하고, `MACH_O_TYPE=staticlib`이라 LTO를 켜면 바이너리가
Mach-O가 아닌 LLVM 비트코드로 남아 `create-xcframework`가 아키텍처를 읽지 못한다
(`Unknown header: 0xb17c0de`).

## 3. SPM 배포 (GitHub Release + binaryTarget)

저장소 루트의 `Package.swift`가 이 저장소를 SPM 패키지로 만든다:

- 8개 xcframework를 `.binaryTarget(name:url:checksum:)`으로 선언 (`Lynx_XcFramework` 제외).
  url은 GitHub Release 자산(`releases/download/<버전>/<F>.xcframework.zip`)을 가리킨다.
- `Lynx` 라이브러리 제품 하나가 8개 타깃을 전부 포함 — 바이너리 간 전이 링크가 자동으로
  걸리지 않으므로, 제품 하나로 묶어 소비 측이 항상 전체를 링크/임베드하게 한다.
- 바이너리는 저장소에 커밋하지 않는다 (`Results/`·`dist/` git-ignored).
  `Package.swift`는 릴리스 워크플로가 `scripts/make-manifest.sh`로 재생성해 커밋한다 —
  **직접 수정하지 말 것.**

소비 측 사용법 (릴리스 태그 = Lynx 버전):

```swift
// 소비 패키지/프로젝트의 의존성 선언
.package(url: "<이 저장소 URL>", exact: "3.9.0")
// 타깃 의존성
.product(name: "Lynx", package: "Lynx-Xcframework")
```

```swift
import Lynx
import LynxService
import SDWebImage
// 8개 모듈 모두 import 가능
```

검증된 사항: `platforms: [.iOS(.v12)]`, 시뮬레이터(`generic/platform=iOS Simulator`)와
실기기(`generic/platform=iOS`) 빌드 모두 통과.

## 4. GitHub Actions 배포 자동화

`.github/workflows/`의 워크플로 두 개가 2단계 릴리스 흐름을 구성한다:
**버전 업 PR(수동) → 머지 시 빌드/릴리스(자동)**.

### auto-update-lynx.yml — "Bump Lynx Version (PR)" (수동 실행)

Actions 탭에서 버전을 입력해 실행한다 (비우면 CocoaPods trunk 최신 정식 버전).

1. `scripts/latest-pod-version.sh`로 대상 버전 결정. Podfile이 이미 그 버전이면 종료.
2. 같은 버전의 열린 PR(`bump-lynx-<버전>` 브랜치)이 있으면 종료.
3. `scripts/set-lynx-version.sh`로 Podfile의 **Lynx 버전만** 갱신 후 PR 생성.
   PrimJS / LynxService / SDWebImage 등 나머지 pod의 버전은 손으로 정하지 않는다 —
   머지 후 빌드 워크플로의 `pod update`가 podspec 의존성 제약을 해석해 결정하고
   `Podfile.lock`에 기록한다 (예: Lynx 3.9.0 → PrimJS/quickjs `3.8.0-alpha.6` 정확 고정,
   LynxService/Image → SDWebImage `5.15.5`).

> 저장소 설정 필요: Settings → Actions → General →
> **"Allow GitHub Actions to create and approve pull requests"** 활성화.
> 꺼져 있으면 `gh pr create`가 권한 오류로 실패한다.

### update-lynx.yml — "Build & Release XCFramework" (PR 머지 시 자동)

main에 `Podfile` 변경이 push되면 실행된다 (버전 업 PR 머지 포함, `workflow_dispatch` 재실행 가능).

1. Podfile에서 Lynx 버전을 읽는다. 같은 버전의 릴리스가 이미 있으면 종료 (멱등).
2. 임시 키체인에 서명 인증서를 설치한다 (아래 Secrets). secret이 없으면 서명 없이 진행.
3. `pod update` → `./build.sh` (xcframework에 `TFLQDNW4Z9`로 codesign).
   `pod install`이 아니라 `pod update`인 이유: install은 Podfile.lock에 잠긴 버전을
   요구사항에 합류시켜, Lynx 버전이 바뀌면 이전 lock의 PrimJS 버전과 충돌한다.
4. `scripts/make-manifest.sh` — `dist/*.zip` 생성 + checksum 계산 + `Package.swift` 재생성
5. `Podfile.lock`/`Package.swift` 커밋·푸시
6. 버전 태그로 GitHub Release 생성, zip 8개 업로드

서명용 Repository secrets (Settings → Secrets and variables → Actions):

| Secret | 내용 |
|---|---|
| `SIGNING_CERTIFICATE_P12` | 서명 인증서 `.p12`의 base64 (`base64 -i cert.p12`) |
| `P12_PASSWORD` | `.p12` 내보낼 때 지정한 암호 |
| `KEYCHAIN_PASSWORD` | CI 임시 키체인 암호 (임의 값) |

인증서가 만료되면 서명 스텝에서 실패한다 — Keychain Access에서 새 인증서를 `.p12`로
내보내 `SIGNING_CERTIFICATE_P12`/`P12_PASSWORD`만 갱신하면 된다.

동작 특성:

- 봇이 GITHUB_TOKEN으로 푸시하는 매니페스트 커밋은 워크플로를 재트리거하지 않는다 (루프 없음).
- 저장소를 GitHub에 **처음 push하면** diff를 계산할 수 없는 push라 경로 필터와 무관하게 1회
  실행되어, 현재 Podfile 버전의 부트스트랩 릴리스가 만들어지고 `Package.swift`가
  path 기반에서 url 기반으로 교체된다. 그 전까지는 원격 SPM 소비가 불가능하다.
- 빌드 실패 시 `build/*.log`가 `build-logs` artifact로 업로드된다.
- macOS 러너 라벨(`macos-26`)을 쓸 수 없는 환경이면 `update-lynx.yml`에서 `macos-15`로 낮춘다.

로컬에서 스크립트를 단독 실행할 수도 있다:

```zsh
scripts/latest-pod-version.sh Lynx            # CocoaPods trunk 최신 정식 버전 조회
scripts/set-lynx-version.sh 3.9.0             # Podfile의 Lynx 버전 갱신
scripts/make-manifest.sh 3.9.0 <owner/repo>   # dist/ zip + Package.swift 생성 (Results/ 필요)
```

## 5. 트러블슈팅

- **`building for iOS, but linking in object file built for iOS Simulator`** (소비 측):
  device 슬라이스 없이 배포됐다. `PLATFORMS` 지정 없이 `./build.sh`로 재추출한다.
- **`BUILD_LIBRARY_FOR_DISTRIBUTION` 관련 아카이브 실패**: Lynx는 C++ 기반이라 module
  stability가 보장되지 않는다. 해당 옵션을 제거하고 Xcode 버전을 고정해 빌드하되,
  이 경우 소비 측 Xcode 버전을 일치시켜야 한다.
- **`⚠︎ <F>: ios_xxx.xcarchive에 없음`**: 해당 pod가 framework를 산출하지 않았다.
  `Podfile`의 `use_frameworks!` 유지 여부와 pod subspec 구성을 확인한다.
- **아카이브는 성공했는데 xcframework 구성만 바꾸고 싶을 때**: `REUSE_ARCHIVE=1 ./build.sh`
  (아카이브 수 분 절약).
- **소비 측 checksum 불일치**: 릴리스 자산과 `Package.swift`가 다른 실행에서 나온 경우다.
  해당 버전 릴리스를 지우고 `update-lynx.yml`을 재실행해 자산과 매니페스트를 같은 실행에서
  다시 만든다.
- **`Specs satisfying the … dependency were found, but they required a higher minimum
  deployment target`** (버전 업 후 pod install 시): 실제 배포 타깃 문제가 아니라, 이전
  `Podfile.lock`에 잠긴 버전(예: PrimJS 3.6.1)과 새 Lynx podspec의 요구(예: PrimJS
  3.8.0-alpha.6)가 충돌한 것이다. `pod install` 대신 `pod update`를 실행한다.
