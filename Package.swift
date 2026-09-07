// swift-tools-version: 5.9
//
// ⚠️ scripts/make-manifest.sh가 생성하는 파일 — 직접 수정하지 말 것.
// 바이너리는 GitHub Release(4.0.2) 자산을 가리킨다.
import PackageDescription

let package = Package(
    name: "Lynx",
    platforms: [.iOS(.v12)],
    products: [
        // 바이너리 간 전이 링크가 자동으로 걸리지 않으므로 제품 하나로 전부 묶는다
        .library(
            name: "Lynx",
            targets: [
                "Lynx",
                "LynxBase",
                "LynxService",
                "LynxServiceAPI",
                "PrimJS",
                "SDWebImage",
                "SDWebImageWebPCoder",
                "libwebp",
            ]
        )
    ],
    targets: [
        .binaryTarget(
            name: "Lynx",
            url: "https://github.com/xenonClient/Lynx-XCFramework/releases/download/4.0.2/Lynx.xcframework.zip",
            checksum: "7525ae68a2850342628b04b3c73f172fff4d3400452560adc8c1e58f5a7f7e9c"
        ),
        .binaryTarget(
            name: "LynxBase",
            url: "https://github.com/xenonClient/Lynx-XCFramework/releases/download/4.0.2/LynxBase.xcframework.zip",
            checksum: "1008211279bd5c1d6c906105cb21e5792715562766f9087899e164104123b4f1"
        ),
        .binaryTarget(
            name: "LynxService",
            url: "https://github.com/xenonClient/Lynx-XCFramework/releases/download/4.0.2/LynxService.xcframework.zip",
            checksum: "ea24bc9f3fa5b395cbe4554d738a4f4ff71c6a7760ed870be430168b0740f73a"
        ),
        .binaryTarget(
            name: "LynxServiceAPI",
            url: "https://github.com/xenonClient/Lynx-XCFramework/releases/download/4.0.2/LynxServiceAPI.xcframework.zip",
            checksum: "20cbef4f06a79bc3be9f8c3d58ae38bd2c0f82db6178a51c7d74e3da44cd4a8a"
        ),
        .binaryTarget(
            name: "PrimJS",
            url: "https://github.com/xenonClient/Lynx-XCFramework/releases/download/4.0.2/PrimJS.xcframework.zip",
            checksum: "4b2ead1a677b9488d6c7aeb34004c2d388f45cff2c2664c3b9be0c5e5cac43ad"
        ),
        .binaryTarget(
            name: "SDWebImage",
            url: "https://github.com/xenonClient/Lynx-XCFramework/releases/download/4.0.2/SDWebImage.xcframework.zip",
            checksum: "e8ea5bcac363d9740d526128144d9f848e29e8df95c8a07dd7ece09aceca456b"
        ),
        .binaryTarget(
            name: "SDWebImageWebPCoder",
            url: "https://github.com/xenonClient/Lynx-XCFramework/releases/download/4.0.2/SDWebImageWebPCoder.xcframework.zip",
            checksum: "5da0672b908abf10e72934fbd6da595338a6ec950d2a801d76976daed91cd2ed"
        ),
        .binaryTarget(
            name: "libwebp",
            url: "https://github.com/xenonClient/Lynx-XCFramework/releases/download/4.0.2/libwebp.xcframework.zip",
            checksum: "887eefcb4ccebdd712c550850b4c28b3bac322c2d48b1db9a3fbdc4961b23237"
        ),
    ]
)
