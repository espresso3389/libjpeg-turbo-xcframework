# libjpeg-turbo Multi-Platform Builder

This project builds libjpeg-turbo for multiple platforms:

- **iOS/macOS**: Universal XCFrameworks for iOS (device and simulator) and macOS (Apple Silicon and Intel)
- **Windows**: DLLs and static libraries for x86, x64, and ARM64
- **Linux**: Shared objects (.so) and static libraries for x86, x64, ARMv7, and ARMv8

## Features

- Multi-platform support (iOS, macOS, Windows, Linux)
- Multiple architecture support per platform
- Builds both `libjpeg` and `libturbojpeg` libraries
- Creates platform-specific distribution packages
- Configurable build options (JPEG7/8 compatibility, SIMD, etc.)
- Can be built locally or via GitHub Actions
- Cross-compilation support for ARM architectures

## Prerequisites

### For macOS/iOS Builds

- macOS with Xcode Command Line Tools installed
- CMake: `brew install cmake`
- NASM: `brew install nasm`
- `jq` (for version detection): `brew install jq`

### For Windows Builds

- Windows 10 or later (for built-in tar command)
- Visual Studio 2017 or later
- CMake: `scoop install cmake` or download from cmake.org
- NASM: `scoop install nasm` (for SIMD support, optional)

### For Linux Builds

- Linux with GCC/Clang
- CMake: `sudo apt-get install cmake` (Ubuntu/Debian) or `sudo yum install cmake` (RHEL/CentOS)
- NASM: `sudo apt-get install nasm` (for SIMD on x86/x64)
- jq: `sudo apt-get install jq`
- For cross-compilation:
  - `sudo apt-get install gcc-multilib g++-multilib` (for x86 on x64)
  - `sudo apt-get install gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf` (for ARMv7)
  - `sudo apt-get install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu` (for ARMv8)

## Building Locally

### Platform-Specific Builds

#### macOS/iOS (XCFrameworks)

Show usage and help:

```bash
./build-darwin.sh
```

Build the latest version:

```bash
./build-darwin.sh latest
```

Build a specific version:

```bash
./build-darwin.sh 3.0.4
```

#### Windows (DLLs and Static Libraries)

On Windows, use the batch script:

```cmd
build-windows.bat latest
build-windows.bat 3.0.4
build-windows.bat --help
```

The Windows build creates binaries for x86, x64, and ARM64 architectures.

#### Linux (Shared Objects and Static Libraries)

On Linux, use the Linux build script:

```bash
./build-linux.sh latest
./build-linux.sh 3.0.4
./build-linux.sh --help
```

The Linux build automatically detects available cross-compilers and builds for all supported architectures (x86, x64, ARMv7, ARMv8).

**Note:** Each platform build must run on the appropriate OS:

- macOS/iOS builds require macOS
- Windows builds require Windows
- Linux builds require Linux (or WSL on Windows)

For available libjpeg-turbo versions, see https://github.com/libjpeg-turbo/libjpeg-turbo/releases.

### Build Options

All build scripts support various configuration options to customize the libjpeg-turbo build:

```bash
./build-darwin.sh [OPTIONS] [VERSION]   # macOS/iOS
./build-linux.sh [OPTIONS] [VERSION]    # Linux
build-windows.bat [OPTIONS] [VERSION]   # Windows
```

#### Available Options

- `--jpeg8` - Build with libjpeg v8 API/ABI compatibility (mutually exclusive with --jpeg7)
- `--jpeg7` - Build with libjpeg v7 API/ABI compatibility (mutually exclusive with --jpeg8)
- `--no-simd` - Disable SIMD extensions (useful for debugging or compatibility)
- `--no-arith-enc` - Disable arithmetic encoding support
- `--no-arith-dec` - Disable arithmetic decoding support
- `--no-turbojpeg` - Disable TurboJPEG API library
- `--ios-target VERSION` - Set iOS deployment target (default: 12.0) *(macOS/iOS only)*
- `--macos-target VERSION` - Set macOS deployment target (default: 11.0) *(macOS/iOS only)*
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

> **Note:** The following examples use `build-darwin.sh`, but the same options work for `build-linux.sh` and `build-windows.bat` (except platform-specific options like `--ios-target` and `--macos-target`).

Build with JPEG8 compatibility:
```bash
./build-darwin.sh --jpeg8 3.0.4
./build-linux.sh --jpeg8 3.0.4
build-windows.bat --jpeg8 3.0.4
```

Build without SIMD optimizations (for debugging):
```bash
./build-darwin.sh --no-simd latest
./build-linux.sh --no-simd latest
build-windows.bat --no-simd latest
```

Build with multiple options:
```bash
./build-darwin.sh --jpeg8 --no-arith-enc 3.0.4
```

Build latest with custom configuration:
```bash
./build-darwin.sh --jpeg7 --no-simd
```

Build with custom deployment targets (macOS/iOS only):
```bash
./build-darwin.sh --ios-target 15.0 --macos-target 12.0 3.0.4
./build-darwin.sh --ios-target 11.0 latest
```

## Building via GitHub Actions

The repository includes GitHub Actions workflows for building on all platforms with custom configurations.

### Available Workflows

1. **Build libjpeg-turbo XCFramework** - Builds iOS/macOS XCFrameworks
2. **Build libjpeg-turbo Windows** - Builds Windows DLLs (x86, x64, ARM64)
3. **Build libjpeg-turbo Linux** - Builds Linux shared objects (x86, x64, ARMv7, ARMv8)

### Triggering a Build

1. Go to the **Actions** tab in your GitHub repository
2. Select the desired workflow
3. Click **Run workflow**
4. Configure build options:
   - **version**: libjpeg-turbo version to build (default: `latest`)
   - **jpeg8**: Build with libjpeg v8 API/ABI compatibility
   - **jpeg7**: Build with libjpeg v7 API/ABI compatibility
   - **enable_simd**: Enable SIMD optimizations (default: `true`)
   - **enable_arith_enc**: Enable arithmetic encoding (default: `true`)
   - **enable_arith_dec**: Enable arithmetic decoding (default: `true`)
   - **enable_turbojpeg**: Enable TurboJPEG API library (default: `true`)
   - **ios_target**: iOS deployment target (default: `12.0`) *(XCFramework workflow only)*
   - **macos_target**: macOS deployment target (default: `11.0`) *(XCFramework workflow only)*

### Workflow Outputs

Each workflow will:

- Build the libraries with your specified configuration
- Upload build artifacts
- Create a GitHub Release with:
  - Platform-specific archive (zip for Windows, tar.gz for Linux, zip for XCFrameworks)
  - Checksums file
  - Build configuration details in release notes
  - Package.Swift and podspec (XCFramework workflow only)

### Output Files

#### macOS/iOS Output (`build/output/`)

- `libjpeg.xcframework` - Standard libjpeg library
- `libturbojpeg.xcframework` - TurboJPEG API library
- `libjpeg-turbo-{version}-xcframework.zip` - Archive of both frameworks
- `checksums.txt` - SHA256 checksums
- `Package.swift` - Swift Package Manager manifest
- `libjpeg-turbo.podspec` - CocoaPods podspec

#### Windows Output (`build/output/`)

- `libjpeg-turbo-{version}-windows.zip` - Archive containing:
  - `x86/` - 32-bit binaries (bin/, lib/, include/)
  - `x64/` - 64-bit binaries (bin/, lib/, include/)
  - `arm64/` - ARM64 binaries (bin/, lib/, include/)
  - `README.txt` - Usage instructions
- `checksums.txt` - SHA256 checksums

#### Linux Output (`build/output/`)

- `libjpeg-turbo-{version}-linux.tar.gz` - Archive containing:
  - `x86/` - 32-bit binaries (lib/, include/, bin/)
  - `x64/` - 64-bit binaries (lib/, include/, bin/)
  - `armv7/` - ARMv7 binaries (lib/, include/, bin/)
  - `armv8/` - ARMv8/AArch64 binaries (lib/, include/, bin/)
  - `README.txt` - Usage instructions
- `checksums.txt` - SHA256 checksums

## Platform Support Summary

| Platform | Architectures | Output Format | Build Script |
|----------|--------------|---------------|--------------|
| **iOS/macOS** | iOS: arm64 (device), arm64/x86_64 (simulator)<br>macOS: arm64, x86_64 | XCFramework | `build-darwin.sh` |
| **Windows** | x86, x64, ARM64 | DLLs + Static libs | `build-windows.bat` |
| **Linux** | x86, x64, ARMv7, ARMv8 | Shared objects + Static libs | `build-linux.sh` |

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

This build system is provided as-is. The libjpeg-turbo library itself is licensed under a BSD-style license. See the [libjpeg-turbo repository](https://github.com/libjpeg-turbo/libjpeg-turbo) for more details.
