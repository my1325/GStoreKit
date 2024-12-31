// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GStoreKit",
    platforms: [.iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(name: "StoreKitCore", targets: ["StoreKitCore"]),
        .library(name: "CombineStoreKit", targets: ["CombineStoreKit"]),
        .library(name: "AsyncStoreKit", targets: ["AsyncStoreKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/CombineCommunity/CombineExt.git", .upToNextMajor(from: "1.8.1"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(name: "StoreKitCore", path: "StoreKitCore"),
        .target(name: "CombineStoreKit", dependencies: ["CombineExt", "StoreKitCore"], path: "CombineStoreKit"),
        .target(name: "AsyncStoreKit", dependencies: ["StoreKitCore"], path: "AsyncStoreKit")
    ]
)
