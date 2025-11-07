# Building libjpeg-turbo XCFramework for iOS/macOS

This workflow builds libjpeg-turbo as a universal XCFramework supporting:
- iOS (arm64)
- iOS Simulator (arm64 + x86_64)
- macOS (arm64 + x86_64)

## Setup

1. Create a new GitHub repository or use an existing one
2. Copy the `build-libjpeg-turbo-xcframework.yml` file to `.github/workflows/` in your repository
3. Commit and push

## Usage

### Automatic Trigger
The workflow will run automatically on push to the main branch and will build the latest version of libjpeg-turbo.

### Manual Trigger
You can manually trigger the workflow:

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
You can reference the XCFramework directly from GitHub releases. Create a `Package.swift` file:

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
Create or update your `Podspec`:

```ruby
Pod::Spec.new do |s|
  s.name             = 'libjpeg-turbo'
  s.version          = '3.0.4'
  s.summary          = 'libjpeg-turbo XCFramework'
  s.homepage         = 'https://github.com/yourusername/yourrepo'
  s.license          = { :type => 'BSD', :file => 'LICENSE' }
  s.author           = { 'Your Name' => 'your@email.com' }
  s.source           = { :http => 'https://github.com/yourusername/yourrepo/releases/download/v3.0.4/libjpeg-turbo-3.0.4-xcframework.zip' }

  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '11.0'

  s.vendored_frameworks = 'libjpeg.xcframework', 'libturbojpeg.xcframework'
end
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

