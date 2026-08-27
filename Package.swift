// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "CSAPIService",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Keep the module name compatible with the CocoaPods integration.
        .library(
            name: "APIService",
            targets: ["APIService"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/Alamofire/Alamofire.git",
            exact: "5.8.1"
        ),
        .package(
            url: "https://github.com/hyperoslo/Cache.git",
            exact: "6.0.0"
        )
    ],
    targets: [
        .target(
            name: "APIService",
            dependencies: [
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "Cache", package: "Cache")
            ],
            path: "APIService/Classes"
        )
    ],
    swiftLanguageVersions: [.v5]
)
