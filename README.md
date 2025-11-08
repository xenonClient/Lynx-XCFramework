# Lynx-Xcframework

[Lynx](https://lynxjs.org) iOS SDK를 XCFramework로 추출해 SPM으로 배포하는 프로젝트.

Lynx는 CocoaPods로만 배포되므로, 이 저장소에서 pod 산출물을 device + simulator
XCFramework로 재패키징하고 GitHub Release로 배포해 SPM(`binaryTarget`) 환경에서
소비할 수 있게 한다.

## SPM으로 사용하기

`Lynx` 제품 하나가 8개 xcframework
(Lynx / LynxBase / LynxService / LynxServiceAPI / PrimJS / SDWebImage /
SDWebImageWebPCoder / libwebp)를 모두 링크/임베드한다. 릴리스 태그 = Lynx 버전.

```swift
dependencies: [
    .package(url: "<이 저장소 URL>", exact: "3.9.0")
],
// 타깃 의존성: .product(name: "Lynx", package: "Lynx-Xcframework")
```

```swift
import Lynx
import LynxService
```

iOS 12.0+, device(arm64) + simulator(arm64/x86_64) 슬라이스 포함.

## 버전 업데이트 (GitHub Actions)

1. **Bump Lynx Version (PR)** 워크플로를 수동 실행 — 최신(또는 지정) Lynx 버전으로
   Podfile을 갱신하는 PR이 생성된다.
2. PR을 머지하면 **Build & Release XCFramework** 워크플로가 자동 실행되어
   XCFramework를 빌드하고 버전 태그로 GitHub Release(zip 8개)를 만든 뒤
   `Package.swift`를 새 checksum으로 갱신한다.

## 로컬 추출

```zsh
pod install    # 최초 1회
./build.sh     # → Results/*.xcframework
```

옵션, 산출물 구성, 배포 자동화 상세, 트러블슈팅은
[`docs/EXTRACTION.md`](docs/EXTRACTION.md) 참고.

## 구성

- `Package.swift` — 8개 바이너리를 GitHub Release 자산 `url:checksum:`으로 선언
  (릴리스 워크플로가 재생성 — 직접 수정 금지)
- `Podfile` — Lynx 버전 고정 (릴리스 버전의 단일 소스 — 나머지 pod는 podspec 제약으로 해석)
- `build.sh` — 아카이브 → create-xcframework → codesign 자동화
- `scripts/` — 버전 조회 / Podfile 갱신 / zip·checksum·매니페스트 생성
- `.github/workflows/` — 버전 업 PR(수동) · 빌드/릴리스(머지 시 자동)
- `Lynx-MiniApp/LynxExtensions/` — 추출 앵커 타깃의 Lynx 확장 샘플 (배포 대상 아님)
- `Results/`, `dist/` — 추출/패키징 산출물 (git-ignored)
