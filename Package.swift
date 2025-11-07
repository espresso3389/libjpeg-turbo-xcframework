// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "libjpeg-turbo",
    platforms: [
        .iOS(.v12),
        .macOS(.v11)
    ],
    products: [
        // Standard libjpeg library
        .library(
            name: "libjpeg",
            targets: ["libjpeg"]),
        // TurboJPEG API library
        .library(
            name: "libturbojpeg",
            targets: ["libturbojpeg"])
    ],
    targets: [
        // Binary target pointing to GitHub release
        // Update the URL and checksum for each new release
        .binaryTarget(
            name: "libjpeg",
            url: "https://github.com/YOURUSERNAME/YOURREPO/releases/download/3.0.4/libjpeg-turbo-3.0.4-xcframework.zip",
            checksum: "REPLACE_WITH_SHA256_CHECKSUM_FROM_RELEASE"
        ),
        .binaryTarget(
            name: "libturbojpeg",
            url: "https://github.com/YOURUSERNAME/YOURREPO/releases/download/3.0.4/libjpeg-turbo-3.0.4-xcframework.zip",
            checksum: "REPLACE_WITH_SHA256_CHECKSUM_FROM_RELEASE"
        )
    ]
)

// INSTRUCTIONS:
// 1. Replace YOURUSERNAME/YOURREPO with your GitHub repository
// 2. Replace 3.0.4 with your release version
// 3. Get the SHA256 checksum from checksums.txt in the release
// 4. Update both targets with the same URL and checksum
// 5. Commit this file to your repository
//
// Users can then add this package to their project:
// dependencies: [
//     .package(url: "https://github.com/YOURUSERNAME/YOURREPO", from: "3.0.4")
// ]
