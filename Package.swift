// swift-tools-version: 5.9
//
// ⚠️ scripts/make-manifest.sh가 생성하는 파일 — 직접 수정하지 말 것.
// 바이너리는 GitHub Release(4.0.3) 자산을 가리킨다.
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
            url: "https://github.com/xenonClient/Lynx-XCFramework/releases/download/4.0.3/Lynx.xcframework.zip",
            checksum: "d3e887e91eb8d50777b5a1b0c06324b1e1c383f08bce9bdea6c414e3a294dce2"
        ),
        .binaryTarget(
            name: "LynxBase",
            url: "https://github.com/xenonClient/Lynx-XCFramework/releases/download/4.0.3/LynxBase.xcframework.zip",
            checksum: "cc5d2f028afaed5d509f55e9d865f59430538ac10993abc37c645a3b80b13d6d"
        ),
        .binaryTarget(
            name: "LynxService",
            url: "https://github.com/xenonClient/Lynx-XCFramework/releases/download/4.0.3/LynxService.xcframework.zip",
            checksum: "fbb707fb0bf1fffb4e2aad33d95d6c80c59eb0a91d2426709847cd509f6140fd"
        ),
        .binaryTarget(
            name: "LynxServiceAPI",
            url: "https://github.com/xenonClient/Lynx-XCFramework/releases/download/4.0.3/LynxServiceAPI.xcframework.zip",
            checksum: "4f15cd3e285b26b2adbb629504bd93bf97c11b92afb0940d96fc31d011ad1eea"
        ),
        .binaryTarget(
            name: "PrimJS",
            url: "https://github.com/xenonClient/Lynx-XCFramework/releases/download/4.0.3/PrimJS.xcframework.zip",
            checksum: "e304197cfb3b8914d4ec53d413e9f99bd012b5dbf60c5d4825a4a6feae5ad7cd"
        ),
        .binaryTarget(
            name: "SDWebImage",
            url: "https://github.com/xenonClient/Lynx-XCFramework/releases/download/4.0.3/SDWebImage.xcframework.zip",
            checksum: "d7cd80e220af4595568a8e5fc542d52e43db339cdb5e4643b0475543df5602b0"
        ),
        .binaryTarget(
            name: "SDWebImageWebPCoder",
            url: "https://github.com/xenonClient/Lynx-XCFramework/releases/download/4.0.3/SDWebImageWebPCoder.xcframework.zip",
            checksum: "2cf7b8ffdee33084ab124d02c7eb4c33a2a585183edee62837f6171250b56552"
        ),
        .binaryTarget(
            name: "libwebp",
            url: "https://github.com/xenonClient/Lynx-XCFramework/releases/download/4.0.3/libwebp.xcframework.zip",
            checksum: "285ea11d32536a4fbb2c12a1d0de62bfd98b4e714137db4e201d78f71bbb4763"
        ),
    ]
)
