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

Show usage and help:

```bash
./build.sh
```

Build the latest version:

```bash
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

The script will automatically fetch the latest release from GitHub when using `latest`.

For available libjpeg-turbo versions, see https://github.com/libjpeg-turbo/libjpeg-turbo/releases.

### Build Options

The build script supports various configuration options to customize the libjpeg-turbo build:

```bash
./build.sh [OPTIONS] [VERSION]
```

#### Available Options

- `--jpeg8` - Build with libjpeg v8 API/ABI compatibility (mutually exclusive with --jpeg7)
- `--jpeg7` - Build with libjpeg v7 API/ABI compatibility (mutually exclusive with --jpeg8)
- `--no-simd` - Disable SIMD extensions (useful for debugging or compatibility)
- `--no-arith-enc` - Disable arithmetic encoding support
- `--no-arith-dec` - Disable arithmetic decoding support
- `--no-turbojpeg` - Disable TurboJPEG API library
- `--ios-target VERSION` - Set iOS deployment target (default: 12.0)
- `--macos-target VERSION` - Set macOS deployment target (default: 11.0)
- `-h, --help` - Display help message with all options

#### Build Option Details

| Option | Default | Description |
|--------|---------|-------------|
| JPEG8 | OFF | Emulate libjpeg v8 API/ABI (incompatible with v6b) |
| JPEG7 | OFF | Emulate libjpeg v7 API/ABI (incompatible with v6b) |
| SIMD | ON | Use SIMD optimizations (NEON on ARM, SSE2 on x86) |
| ARITH_ENC | ON | Arithmetic encoding support |
| ARITH_DEC | ON | Arithmetic decoding support |
| TURBOJPEG | ON | Include TurboJPEG API library |

#### Examples

Build with JPEG8 compatibility:
```bash
./build.sh --jpeg8 3.0.4
```

Build without SIMD optimizations (for debugging):
```bash
./build.sh --no-simd latest
```

Build with multiple options:
```bash
./build.sh --jpeg8 --no-arith-enc 3.0.4
```

Build latest with custom configuration:
```bash
./build.sh --jpeg7 --no-simd
```

Build with custom deployment targets:
```bash
./build.sh --ios-target 15.0 --macos-target 12.0 3.0.4
```

Build for older iOS versions:
```bash
./build.sh --ios-target 11.0 latest
```

### Cleaning

To remove all build artifacts:

```bash
./clean.sh
```

This removes build directories, intermediate files, and output artifacts.

## Building via GitHub Actions

The repository includes a GitHub Actions workflow that can build XCFrameworks with custom configurations.

### Triggering a Build

1. Go to the **Actions** tab in your GitHub repository
2. Select **Build libjpeg-turbo XCFramework** workflow
3. Click **Run workflow**
4. Configure build options:
   - **version**: libjpeg-turbo version to build (default: `latest`)
   - **jpeg8**: Build with libjpeg v8 API/ABI compatibility
   - **jpeg7**: Build with libjpeg v7 API/ABI compatibility
   - **enable_simd**: Enable SIMD optimizations (default: `true`)
   - **enable_arith_enc**: Enable arithmetic encoding (default: `true`)
   - **enable_arith_dec**: Enable arithmetic decoding (default: `true`)
   - **enable_turbojpeg**: Enable TurboJPEG API library (default: `true`)
   - **ios_target**: iOS deployment target (default: `12.0`)
   - **macos_target**: macOS deployment target (default: `11.0`)

### Workflow Outputs

The workflow will:
- Build the XCFrameworks with your specified configuration
- Upload build artifacts
- Create a GitHub Release with:
  - XCFramework zip archive
  - Checksums file
  - Package.swift for Swift Package Manager
  - libjpeg-turbo.podspec for CocoaPods
  - Build configuration details in release notes

### Output

After a successful build, all output files will be in `build/output/`:

- `build/output/libjpeg.xcframework` - Standard libjpeg library
- `build/output/libturbojpeg.xcframework` - TurboJPEG API library
- `build/output/libjpeg-turbo-{version}-xcframework.zip` - Archive of both frameworks
- `build/output/checksums.txt` - SHA256 checksums for verification
- `build/output/Package.swift` - Ready-to-use Swift Package Manager manifest
- `build/output/libjpeg-turbo.podspec` - Ready-to-use CocoaPods podspec
