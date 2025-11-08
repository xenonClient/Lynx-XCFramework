// swift-tools-version: 5.9
//
// Lynx XCFramework SPM 패키지.
// build.sh가 Results/에 추출한 바이너리를 binaryTarget으로 노출한다.
// Lynx_MiniApp.xcframework(추출 앵커 타깃 자체 산출물)는 배포 대상이 아니다.
import PackageDescription

let frameworks = [
    "Lynx",
    "LynxBase",
    "LynxService",
    "LynxServiceAPI",
    "PrimJS",
    "SDWebImage",
    "SDWebImageWebPCoder",
    "libwebp",
]

let package = Package(
    name: "Lynx",
    platforms: [.iOS(.v12)],
    products: [
        // 8개 바이너리를 한 번에 링크/임베드하는 통합 라이브러리.
        // (Lynx → LynxBase/LynxServiceAPI/PrimJS, LynxService → Lynx/SDWebImage/…
        //  전이 링크가 바이너리 간에 자동으로 걸리지 않으므로 전부 함께 제공한다)
        .library(name: "Lynx", targets: frameworks)
    ],
    targets: frameworks.map {
        .binaryTarget(name: $0, path: "Results/\($0).xcframework")
    }
)
