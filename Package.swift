// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Assimp",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Assimp",
            targets: ["Assimp"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Assimp",
            dependencies: ["CAssimp"]),
        .testTarget(
            name: "AssimpTests",
            dependencies: ["Assimp"]),
        .systemLibrary(
            name: "CAssimp",
            path: "Sources/CAssimp",
            pkgConfig: "assimp",
            providers: [
                .brew(["assimp"]),
                .apt(["libassimp-dev"])
            ])
    ]
)
