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

For available libjpeg-turbo versions, see https://github.com/libjpeg-turbo/libjpeg-turbo/releases.

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
