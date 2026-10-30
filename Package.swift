// swift-tools-version: 5.9
//
// ⚠️ scripts/make-manifest.sh가 생성하는 파일 — 직접 수정하지 말 것.
// 바이너리는 GitHub Release(4.2.0) 자산을 가리킨다.
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
            url: "https://github.com/xenonClient/Lynx-XCFramework/releases/download/4.2.0/Lynx.xcframework.zip",
            checksum: "1044630f67157ef23acf45fc68da9fd49aba86bf7b7ece65d7f48ad9096bc9ca"
        ),
        .binaryTarget(
            name: "LynxBase",
            url: "https://github.com/xenonClient/Lynx-XCFramework/releases/download/4.2.0/LynxBase.xcframework.zip",
            checksum: "8d5ad22358cfdf29c86479e80cef4965298ae344a22ad79330243a2da7054d9b"
        ),
        .binaryTarget(
            name: "LynxService",
            url: "https://github.com/xenonClient/Lynx-XCFramework/releases/download/4.2.0/LynxService.xcframework.zip",
            checksum: "dfa8b82abe06a632ab5d7892ad3acbaeb0daf46ea161c218d7218093532fe22a"
        ),
        .binaryTarget(
            name: "LynxServiceAPI",
            url: "https://github.com/xenonClient/Lynx-XCFramework/releases/download/4.2.0/LynxServiceAPI.xcframework.zip",
            checksum: "f2615f9f0ff1ce191c28da35739c21ba77b527949b63d16463a999f184cf81e2"
        ),
        .binaryTarget(
            name: "PrimJS",
            url: "https://github.com/xenonClient/Lynx-XCFramework/releases/download/4.2.0/PrimJS.xcframework.zip",
            checksum: "b27b663f356b8914208537b829ed3d63f6cefa399e0387c2c7ba32e4a95e9f4b"
        ),
        .binaryTarget(
            name: "SDWebImage",
            url: "https://github.com/xenonClient/Lynx-XCFramework/releases/download/4.2.0/SDWebImage.xcframework.zip",
            checksum: "2e46c0851ae4592a5018b94a0079d0540996ca75897ffbd42fed6c56132c8b7b"
        ),
        .binaryTarget(
            name: "SDWebImageWebPCoder",
            url: "https://github.com/xenonClient/Lynx-XCFramework/releases/download/4.2.0/SDWebImageWebPCoder.xcframework.zip",
            checksum: "49af29505abd4e95a34a5b3efe0d28ccdcaea0504ef596a8283399d8459539c5"
        ),
        .binaryTarget(
            name: "libwebp",
            url: "https://github.com/xenonClient/Lynx-XCFramework/releases/download/4.2.0/libwebp.xcframework.zip",
            checksum: "d5f6214501f71a51cec960f9cf0d80f97ee053bdbaf1f9a7baad777b5dfcebf3"
        ),
    ]
)
