# libjpeg-turbo XCFramework Builder

This project builds universal XCFrameworks for libjpeg-turbo that support iOS and macOS platforms.

## Features

- Supports iOS (device and simulator) and macOS (Apple Silicon and Intel)
- Builds both `libjpeg` and `libturbojpeg` libraries
- Creates universal binaries for maximum compatibility
- Can be built locally or via GitHub Actions

## Prerequisites

To build locally, you need:

- macOS with Xcode Command Line Tools installed
- CMake: `brew install cmake`
- NASM: `brew install nasm`
- jq (for version detection): `brew install jq`

## Building Locally

### Quick Start

Build the latest version (default):

```bash
./build.sh
# or explicitly
./build.sh latest
```

Build a specific version:

```bash
./build.sh 3.0.4
```

or with the version tag:

```bash
./build.sh v3.0.4
```

The script will automatically fetch the latest release from GitHub when using `latest` or when no version is specified.

### Cleaning

To remove all build artifacts:

```bash
./clean.sh
```

This removes build directories, intermediate files, and output artifacts.

### Output

After a successful build, all output files will be in `build/output/`:

- `build/output/libjpeg.xcframework` - Standard libjpeg library
- `build/output/libturbojpeg.xcframework` - TurboJPEG API library
- `build/output/libjpeg-turbo-{version}-xcframework.zip` - Archive of both frameworks
- `build/output/checksums.txt` - SHA256 checksums for verification
- `build/output/Package.swift` - Ready-to-use Swift Package Manager manifest
- `build/output/libjpeg-turbo.podspec` - Ready-to-use CocoaPods podspec

## Project Structure

```
.
├── build.sh                          # Main build orchestration script
├── clean.sh                          # Clean all build artifacts
├── scripts/
│   ├── common.sh                     # Shared utilities and variables
│   ├── fetch-source.sh               # Download libjpeg-turbo source
│   ├── build-platforms.sh            # Build for each platform/arch
│   ├── create-universal.sh           # Create universal binaries with lipo
│   ├── create-xcframework.sh         # Generate XCFrameworks
│   ├── create-checksums.sh           # Generate SHA256 checksums
│   ├── create-package-swift.sh       # Generate Package.swift template
│   └── create-podspec.sh             # Generate CocoaPods podspec
└── .github/workflows/
    └── build-libjpeg-turbo-xcframework.yml  # CI/CD workflow
```

## Build Process

The build script performs the following steps:

1. **Fetch Source**: Downloads the specified version of libjpeg-turbo from GitHub
2. **Build Platforms**: Compiles static libraries for each platform and architecture:
   - iOS arm64 (device)
   - iOS Simulator arm64
   - iOS Simulator x86_64
   - macOS arm64 (Apple Silicon)
   - macOS x86_64 (Intel)
3. **Create Universal Binaries**: Uses `lipo` to combine architectures:
   - iOS Simulator: arm64 + x86_64
   - macOS: arm64 + x86_64
4. **Create XCFrameworks**: Packages frameworks for iOS and macOS
5. **Create Archive**: Zips the XCFrameworks
6. **Generate Checksums**: Creates SHA256 checksums for verification
7. **Generate Package.swift**: Creates a Swift Package Manager template
8. **Generate Podspec**: Creates a CocoaPods podspec file

## Debugging

Since all build logic is now in shell scripts, you can:

1. Run individual scripts to test specific steps
2. Add debug output by modifying the scripts
3. Inspect intermediate build artifacts in `build/` directory:
   - `build/source/` - Downloaded libjpeg-turbo source
   - `build/install/` - Built libraries for each platform
   - `build/frameworks/` - Intermediate framework structures
   - `build/output/` - Final XCFrameworks and distribution files
4. Run the entire build locally before pushing to CI

Example: Test only the build step:

```bash
# Source the common utilities
source scripts/common.sh

# Download source
source scripts/fetch-source.sh
fetch_libjpeg_turbo_source "latest"

# Build just one platform
source scripts/build-platforms.sh
build_platform "macos" "arm64" "11.0" "" ""
```

## GitHub Actions

### Triggers

The workflow is triggered:

- Manually via workflow dispatch (can specify version)
- Automatically on push to `main` branch

### Manual Trigger

1. Go to your repository on GitHub
2. Click on "Actions" tab
3. Select "Build libjpeg-turbo XCFramework" workflow
4. Click "Run workflow"
5. Enter the desired libjpeg-turbo version:
   - Leave as "latest" (default) to automatically fetch the most recent release
   - Or specify a version like "3.0.4" or "3.1.0"
6. Click "Run workflow"

The workflow will automatically fetch the latest version from the libjpeg-turbo GitHub releases if you use "latest".

## Output

The workflow produces:
- `libjpeg.xcframework` - Standard libjpeg library
- `libturbojpeg.xcframework` - TurboJPEG library
- `libjpeg-turbo-{version}-xcframework.zip` - Compressed archive of both XCFrameworks
- `checksums.txt` - SHA256 checksums for verification
- `Package.swift` - Ready-to-use Swift Package Manager manifest
- `libjpeg-turbo.podspec` - Ready-to-use CocoaPods podspec

### GitHub Releases

The workflow automatically creates a GitHub release with:
- Tagged with the libjpeg-turbo version (e.g., `3.0.4` or `3.1.0`)
- XCFramework zip file attached
- SHA256 checksums for verification
- Installation instructions and platform support details
- Links to official documentation

**Release is created for:**
- ✅ Manual workflow triggers (workflow_dispatch)
- ✅ Push to main branch (automatic with latest version)

### Downloading from Releases

1. Go to your repository on GitHub
2. Click on "Releases" in the right sidebar
3. Find the version you want
4. Download `libjpeg-turbo-{version}-xcframework.zip`
5. Verify using the SHA256 checksum in `checksums.txt`

## Integrating into Your Xcode Project

### Option 1: Drag and Drop
1. Unzip the downloaded archive
2. Drag `libjpeg.xcframework` and/or `libturbojpeg.xcframework` into your Xcode project
3. In your target's "General" tab, verify they appear under "Frameworks, Libraries, and Embedded Content"
4. Set "Embed" to "Do Not Embed" (since they're static libraries)

### Option 2: Swift Package Manager

The build process automatically generates a ready-to-use `Package.swift` file with the correct repository URL and checksum.

**Setup Steps:**

1. Download `Package.swift` from the GitHub release
2. Commit it to your repository root
3. Tag with the version number (e.g., `3.0.4`)
4. Push to GitHub

**The generated Package.swift looks like:**

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "libjpeg-turbo",
    platforms: [
        .iOS(.v12),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "libjpeg",
            targets: ["libjpeg"]),
        .library(
            name: "libturbojpeg",
            targets: ["libturbojpeg"])
    ],
    targets: [
        .binaryTarget(
            name: "libjpeg",
            url: "https://github.com/YOURUSERNAME/YOURREPO/releases/download/3.0.4/libjpeg-turbo-3.0.4-xcframework.zip",
            checksum: "YOUR_SHA256_CHECKSUM_HERE"
        ),
        .binaryTarget(
            name: "libturbojpeg",
            url: "https://github.com/YOURUSERNAME/YOURREPO/releases/download/3.0.4/libjpeg-turbo-3.0.4-xcframework.zip",
            checksum: "YOUR_SHA256_CHECKSUM_HERE"
        )
    ]
)
```

**To get the checksum:**
1. Download `checksums.txt` from the release
2. Copy the SHA256 hash

**Note:** Swift Package Manager requires the XCFrameworks to be in a zip file, which is why we create one in the workflow.

### Option 3: CocoaPods

The build process automatically generates a ready-to-use `libjpeg-turbo.podspec` file with the correct repository URL and checksum.

**Setup Steps:**

1. Download `libjpeg-turbo.podspec` from the GitHub release
2. Commit it to your repository root
3. Tag with the version number (e.g., `3.0.4`)
4. Push to GitHub

**The generated podspec looks like:**

```ruby
Pod::Spec.new do |s|
  s.name             = 'libjpeg-turbo'
  s.version          = '3.0.4'
  s.summary          = 'libjpeg-turbo XCFramework for iOS and macOS'
  s.description      = <<-DESC
    libjpeg-turbo is a JPEG image codec that uses SIMD instructions to accelerate
    baseline JPEG compression and decompression on x86, x86-64, Arm, PowerPC, and
    MIPS systems. This pod provides prebuilt XCFrameworks for iOS and macOS.
  DESC

  s.homepage         = 'https://github.com/YOURUSERNAME/YOURREPO'
  s.license          = { :type => 'BSD', :file => 'LICENSE.md' }
  s.author           = { 'libjpeg-turbo' => 'information@libjpeg-turbo.org' }
  s.source           = {
    :http => 'https://github.com/YOURUSERNAME/YOURREPO/releases/download/3.0.4/libjpeg-turbo-3.0.4-xcframework.zip',
    :sha256 => 'YOUR_SHA256_CHECKSUM_HERE'
  }

  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '11.0'

  s.vendored_frameworks = 'libjpeg.xcframework', 'libturbojpeg.xcframework'

  s.libraries = 'c++'
end
```

**To publish to CocoaPods Trunk (optional):**

```bash
pod trunk push libjpeg-turbo.podspec
```

Consumers can then add to their `Podfile`:

```ruby
pod 'libjpeg-turbo', :podspec => 'https://raw.githubusercontent.com/YOURUSERNAME/YOURREPO/3.0.4/libjpeg-turbo.podspec'
```

## Usage in Code

### Standard libjpeg
```swift
import libjpeg

// Use standard libjpeg functions
// jpeglib.h functions are available
```

### TurboJPEG
```swift
import libturbojpeg

// Use TurboJPEG API
// turbojpeg.h functions are available
```

### Objective-C
```objc
#import <libjpeg/jpeglib.h>
// or
#import <libturbojpeg/turbojpeg.h>
```

## Customization

You can modify the workflow to:

### Change Deployment Targets
Edit the `-DCMAKE_OSX_DEPLOYMENT_TARGET` flags:
```yaml
-DCMAKE_OSX_DEPLOYMENT_TARGET=12.0  # For iOS
-DCMAKE_OSX_DEPLOYMENT_TARGET=11.0  # For macOS
```

### Add Additional Architectures
To support older iOS devices (armv7), add a build step:
```yaml
- name: Build for iOS armv7
  run: |
    mkdir -p build-ios-armv7
    cd build-ios-armv7
    cmake ../libjpeg-turbo-source \
      -DCMAKE_SYSTEM_NAME=iOS \
      -DCMAKE_OSX_ARCHITECTURES=armv7 \
      -DCMAKE_OSX_DEPLOYMENT_TARGET=9.0 \
      ...
```

### Configure Build Options
Modify CMake flags in each build step:
- `-DWITH_JPEG8=ON` - Enable libjpeg v8 API/ABI
- `-DWITH_SIMD=ON/OFF` - Enable/disable SIMD acceleration
- `-DFLOATTEST=ON` - Build floating-point variant for benchmarking

## Versions

Check available versions at:
https://github.com/libjpeg-turbo/libjpeg-turbo/releases

## Troubleshooting

### Build Fails on iOS
- Ensure you have the latest Xcode command line tools: `xcode-select --install`
- Check that you're using a compatible libjpeg-turbo version

### XCFramework Not Recognized
- Make sure you're using Xcode 11 or later
- Verify the framework is properly embedded in your target settings

### Linking Errors
- Ensure you've set "Do Not Embed" for static libraries
- Add any required system frameworks (often none needed for libjpeg-turbo)

## License

libjpeg-turbo is released under a BSD-style license. See the libjpeg-turbo repository for details.

