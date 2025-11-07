#!/bin/bash

# Unified build script for libjpeg-turbo Darwin (macOS/iOS) XCFramework
# This script is fully self-contained with all utilities and functions included

set -e  # Exit on error
set -u  # Exit on undefined variable

# =============================================================================
# Setup and Global Variables
# =============================================================================

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directories - all build artifacts go inside build/
BUILD_ROOT="${PROJECT_ROOT}/build"
SOURCE_DIR="${BUILD_ROOT}/source"
BUILD_DIR="${BUILD_ROOT}/cmake-build"
INSTALL_DIR="${BUILD_ROOT}/install"
FRAMEWORKS_DIR="${BUILD_ROOT}/frameworks"
OUTPUT_DIR="${BUILD_ROOT}/output"

# Global variables
VERSION_CLEAN=""

# Default build options
VERSION="latest"
WITH_JPEG8=0
WITH_JPEG7=0
WITH_SIMD=1
WITH_ARITH_ENC=1
WITH_ARITH_DEC=1
WITH_TURBOJPEG=1
IOS_DEPLOYMENT_TARGET="12.0"
MACOS_DEPLOYMENT_TARGET="11.0"

# =============================================================================
# Common Utility Functions
# =============================================================================

# Print a header
print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# Print a step
print_step() {
    echo ""
    echo -e "${GREEN}▶ $1${NC}"
    echo ""
}

# Print an error
print_error() {
    echo -e "${RED}✗ Error: $1${NC}" >&2
}

# Print a warning
print_warning() {
    echo -e "${YELLOW}⚠ Warning: $1${NC}"
}

# Print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# =============================================================================
# Source Fetching Functions
# =============================================================================

fetch_libjpeg_turbo_source() {
    local input_version="$1"

    if [ "$input_version" = "latest" ]; then
        echo "Fetching latest release version..."

        # Prepare curl command with optional authentication
        local curl_cmd="curl -s"
        if [ -n "${GITHUB_TOKEN:-}" ]; then
            curl_cmd="$curl_cmd -H \"Authorization: Bearer $GITHUB_TOKEN\""
        fi

        LATEST_VERSION=$(eval "$curl_cmd https://api.github.com/repos/libjpeg-turbo/libjpeg-turbo/releases/latest" | jq -r .tag_name)
        if [ -z "$LATEST_VERSION" ] || [ "$LATEST_VERSION" = "null" ]; then
            print_error "Failed to fetch latest version"
            exit 1
        fi
        echo "Latest version: $LATEST_VERSION"
        VERSION="$LATEST_VERSION"
    else
        echo "Using specified version: $input_version"
        VERSION="$input_version"
    fi

    # Remove 'v' prefix if present
    VERSION_CLEAN=$(echo "$VERSION" | sed 's/^v//')
    export VERSION_CLEAN

    echo "Downloading libjpeg-turbo version: $VERSION"

    # Create build root directory if it doesn't exist
    mkdir -p "$BUILD_ROOT"

    cd "$BUILD_ROOT"
    curl -L "https://github.com/libjpeg-turbo/libjpeg-turbo/archive/refs/tags/${VERSION}.tar.gz" -o libjpeg-turbo.tar.gz

    # Remove old source if exists
    if [ -d "$SOURCE_DIR" ]; then
        rm -rf "$SOURCE_DIR"
    fi

    echo "Extracting source..."
    tar -xzf libjpeg-turbo.tar.gz
    mv "libjpeg-turbo-${VERSION_CLEAN}" source
    rm libjpeg-turbo.tar.gz

    cd "$PROJECT_ROOT"

    print_success "Source downloaded and extracted to $SOURCE_DIR"
}

# =============================================================================
# Helper Functions
# =============================================================================

get_cpu_count() {
    sysctl -n hw.ncpu 2>/dev/null || echo "4"
}

get_git_repo_url() {
    # Try to get the GitHub repository URL from git remote
    local remote_url=$(git -C "$PROJECT_ROOT" config --get remote.origin.url 2>/dev/null || echo "")

    if [ -z "$remote_url" ]; then
        echo ""
        return
    fi

    # Convert SSH URL to HTTPS format
    if [[ "$remote_url" =~ ^git@github\.com:(.+)\.git$ ]]; then
        echo "https://github.com/${BASH_REMATCH[1]}"
    elif [[ "$remote_url" =~ ^https://github\.com/(.+)\.git$ ]]; then
        echo "https://github.com/${BASH_REMATCH[1]}"
    elif [[ "$remote_url" =~ ^https://github\.com/(.+)$ ]]; then
        echo "https://github.com/${BASH_REMATCH[1]}"
    else
        echo ""
    fi
}

# =============================================================================
# Build Functions
# =============================================================================

build_platform() {
    local platform="$1"
    local arch="$2"
    local deployment_target="$3"
    local extra_flags="$4"
    local sysroot_flag="$5"

    local build_name="${platform}-${arch}"
    local build_path="${BUILD_DIR}/${build_name}"
    local install_path="${INSTALL_DIR}/${build_name}"

    echo "Building for ${platform} ${arch}..."

    mkdir -p "$build_path"
    cd "$build_path"

    local cmake_args=(
        "$SOURCE_DIR"
        "-DCMAKE_OSX_ARCHITECTURES=${arch}"
        "-DCMAKE_OSX_DEPLOYMENT_TARGET=${deployment_target}"
        "-DCMAKE_INSTALL_PREFIX=${install_path}"
        "-DCMAKE_BUILD_TYPE=Release"
        "-DENABLE_SHARED=OFF"
        "-DENABLE_STATIC=ON"
    )

    # Add libjpeg-turbo specific build options
    cmake_args+=("-DWITH_JPEG8=${WITH_JPEG8}")
    cmake_args+=("-DWITH_JPEG7=${WITH_JPEG7}")
    cmake_args+=("-DWITH_SIMD=${WITH_SIMD}")
    cmake_args+=("-DWITH_ARITH_ENC=${WITH_ARITH_ENC}")
    cmake_args+=("-DWITH_ARITH_DEC=${WITH_ARITH_DEC}")
    cmake_args+=("-DWITH_TURBOJPEG=${WITH_TURBOJPEG}")

    # Add system name for iOS builds
    if [ "$platform" = "ios" ] || [ "$platform" = "ios-simulator" ]; then
        cmake_args+=("-DCMAKE_SYSTEM_NAME=iOS")
        cmake_args+=("-DCMAKE_SYSTEM_PROCESSOR=${arch}")
    fi

    # Add sysroot for simulator builds
    if [ -n "$sysroot_flag" ]; then
        cmake_args+=("-DCMAKE_OSX_SYSROOT=${sysroot_flag}")
    fi

    # Add extra C flags if specified
    if [ -n "$extra_flags" ]; then
        cmake_args+=("-DCMAKE_C_FLAGS=${extra_flags}")
    fi

    if ! cmake "${cmake_args[@]}"; then
        print_error "CMake configuration failed for ${build_name}"
        cd "$PROJECT_ROOT"
        return 1
    fi

    if ! make -j$(get_cpu_count); then
        print_error "Build failed for ${build_name}"
        cd "$PROJECT_ROOT"
        return 1
    fi

    if ! make install; then
        print_error "Installation failed for ${build_name}"
        cd "$PROJECT_ROOT"
        return 1
    fi

    print_success "Built ${build_name}"
    cd "$PROJECT_ROOT"
}

build_all_platforms() {
    # Clean build, install, and output directories (but preserve source)
    rm -rf "$BUILD_DIR" "$INSTALL_DIR" "$FRAMEWORKS_DIR" "$OUTPUT_DIR"
    mkdir -p "$BUILD_DIR" "$INSTALL_DIR" "$OUTPUT_DIR"

    # Build iOS arm64 (device)
    build_platform "ios" "arm64" "$IOS_DEPLOYMENT_TARGET" "" ""

    # Build iOS Simulator arm64
    build_platform "ios-simulator" "arm64" "$IOS_DEPLOYMENT_TARGET" "" "iphonesimulator"

    # Build iOS Simulator x86_64
    build_platform "ios-simulator" "x86_64" "$IOS_DEPLOYMENT_TARGET" "" "iphonesimulator"

    # Build macOS arm64
    build_platform "macos" "arm64" "$MACOS_DEPLOYMENT_TARGET" "" ""

    # Build macOS x86_64
    build_platform "macos" "x86_64" "$MACOS_DEPLOYMENT_TARGET" "" ""

    print_success "All platforms built successfully"
}

# =============================================================================
# Universal Binary Functions
# =============================================================================

create_universal_binary() {
    local platform="$1"
    local lib_name="$2"
    shift 2
    local arch_dirs=("$@")

    local output_dir="${INSTALL_DIR}/${platform}"
    mkdir -p "${output_dir}/lib"

    local lipo_args=()
    for arch_dir in "${arch_dirs[@]}"; do
        lipo_args+=("${INSTALL_DIR}/${arch_dir}/lib/${lib_name}")
    done

    echo "Creating universal binary for ${platform} ${lib_name}..."
    lipo -create "${lipo_args[@]}" -output "${output_dir}/lib/${lib_name}"

    print_success "Created universal ${lib_name} for ${platform}"
}

create_universal_binaries() {
    # Create universal binary for iOS Simulator (arm64 + x86_64)
    create_universal_binary "ios-simulator" "libjpeg.a" "ios-simulator-arm64" "ios-simulator-x86_64"
    create_universal_binary "ios-simulator" "libturbojpeg.a" "ios-simulator-arm64" "ios-simulator-x86_64"

    # Copy headers from arm64 build (they're the same for all architectures)
    cp -R "${INSTALL_DIR}/ios-simulator-arm64/include" "${INSTALL_DIR}/ios-simulator/"
    print_success "Copied headers for iOS Simulator"

    # Create universal binary for macOS (arm64 + x86_64)
    create_universal_binary "macos" "libjpeg.a" "macos-arm64" "macos-x86_64"
    create_universal_binary "macos" "libturbojpeg.a" "macos-arm64" "macos-x86_64"

    # Copy headers from arm64 build
    cp -R "${INSTALL_DIR}/macos-arm64/include" "${INSTALL_DIR}/macos/"
    print_success "Copied headers for macOS"

    print_success "All universal binaries created"
}

# =============================================================================
# XCFramework Functions
# =============================================================================

create_framework() {
    local platform="$1"
    local framework_name="$2"
    local lib_name="$3"
    local header_pattern="$4"

    local framework_path="${FRAMEWORKS_DIR}/${platform}/${framework_name}"
    mkdir -p "${framework_path}/Headers"

    # Copy the library
    if [ "$platform" = "ios" ]; then
        # For iOS device, use the arm64 build
        cp "${INSTALL_DIR}/ios-arm64/lib/${lib_name}" "${framework_path}/${framework_name%.framework}"

        # Copy headers from iOS arm64 build
        if [ "$header_pattern" = "all" ]; then
            cp "${INSTALL_DIR}/ios-arm64/include"/*.h "${framework_path}/Headers/"
        else
            cp "${INSTALL_DIR}/ios-arm64/include/${header_pattern}" "${framework_path}/Headers/"
        fi
    elif [ "$platform" = "ios-simulator" ]; then
        # For iOS simulator, use the universal binary (arm64 + x86_64)
        cp "${INSTALL_DIR}/ios-simulator/lib/${lib_name}" "${framework_path}/${framework_name%.framework}"

        # Copy headers from iOS simulator build
        if [ "$header_pattern" = "all" ]; then
            cp "${INSTALL_DIR}/ios-simulator/include"/*.h "${framework_path}/Headers/"
        else
            cp "${INSTALL_DIR}/ios-simulator/include/${header_pattern}" "${framework_path}/Headers/"
        fi
    else
        # For macOS, use the universal binary
        cp "${INSTALL_DIR}/macos/lib/${lib_name}" "${framework_path}/${framework_name%.framework}"

        # Copy headers from macOS build
        if [ "$header_pattern" = "all" ]; then
            cp "${INSTALL_DIR}/macos/include"/*.h "${framework_path}/Headers/"
        else
            cp "${INSTALL_DIR}/macos/include/${header_pattern}" "${framework_path}/Headers/"
        fi
    fi

    print_success "Created framework for ${platform}: ${framework_name}"
}

create_xcframeworks() {
    # Clean frameworks directory
    rm -rf "$FRAMEWORKS_DIR"
    mkdir -p "$FRAMEWORKS_DIR"

    # Create libjpeg frameworks for iOS, iOS Simulator, and macOS
    echo "Creating libjpeg frameworks..."
    create_framework "ios" "libjpeg.framework" "libjpeg.a" "all"
    create_framework "ios-simulator" "libjpeg.framework" "libjpeg.a" "all"
    create_framework "macos" "libjpeg.framework" "libjpeg.a" "all"

    # Create libjpeg XCFramework
    echo "Creating libjpeg.xcframework..."
    xcodebuild -create-xcframework \
        -framework "${FRAMEWORKS_DIR}/ios/libjpeg.framework" \
        -framework "${FRAMEWORKS_DIR}/ios-simulator/libjpeg.framework" \
        -framework "${FRAMEWORKS_DIR}/macos/libjpeg.framework" \
        -output "${OUTPUT_DIR}/libjpeg.xcframework"
    print_success "Created libjpeg.xcframework"

    # Create libturbojpeg frameworks for iOS, iOS Simulator, and macOS
    echo "Creating libturbojpeg frameworks..."
    create_framework "ios" "libturbojpeg.framework" "libturbojpeg.a" "turbojpeg.h"
    create_framework "ios-simulator" "libturbojpeg.framework" "libturbojpeg.a" "turbojpeg.h"
    create_framework "macos" "libturbojpeg.framework" "libturbojpeg.a" "turbojpeg.h"

    # Create libturbojpeg XCFramework
    echo "Creating libturbojpeg.xcframework..."
    xcodebuild -create-xcframework \
        -framework "${FRAMEWORKS_DIR}/ios/libturbojpeg.framework" \
        -framework "${FRAMEWORKS_DIR}/ios-simulator/libturbojpeg.framework" \
        -framework "${FRAMEWORKS_DIR}/macos/libturbojpeg.framework" \
        -output "${OUTPUT_DIR}/libturbojpeg.xcframework"
    print_success "Created libturbojpeg.xcframework"
}

# Archive creation removed - GitHub Actions will handle packaging

# Podspec generation removed - GitHub Actions will handle it

# =============================================================================
# Main Execution
# =============================================================================

# Function to display usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] [VERSION]

Build libjpeg-turbo XCFramework for iOS and macOS.

Arguments:
  VERSION              Version to build (required)
                       Examples: latest, 3.0.1, 2.1.5
                       Use 'latest' to build the most recent release

Options:
  --jpeg8              Build with libjpeg v8 API/ABI compatibility
                       (mutually exclusive with --jpeg7)
  --jpeg7              Build with libjpeg v7 API/ABI compatibility
                       (mutually exclusive with --jpeg8)
  --no-simd            Disable SIMD extensions (useful for debugging)
  --no-arith-enc       Disable arithmetic encoding support
  --no-arith-dec       Disable arithmetic decoding support
  --no-turbojpeg       Disable TurboJPEG API library
  --ios-target VERSION Set iOS deployment target (default: 12.0)
  --macos-target VERSION
                       Set macOS deployment target (default: 11.0)
  -h, --help           Display this help message

Examples:
  $0                              # Show this help message
  $0 latest                       # Build latest version with defaults
  $0 3.0.1                        # Build version 3.0.1
  $0 --jpeg8 3.0.1                # Build v3.0.1 with JPEG8 compatibility
  $0 --no-simd latest             # Build latest without SIMD
  $0 --jpeg8 --no-arith-enc 3.0.1 # Build v3.0.1 with JPEG8, no arithmetic encoding
  $0 --ios-target 15.0 3.0.1      # Build v3.0.1 with iOS 15.0 minimum target
  $0 --macos-target 12.0 latest   # Build latest with macOS 12.0 minimum target

Build Options:
  JPEG8:        Emulate libjpeg v8 API/ABI (incompatible with v6b)
  JPEG7:        Emulate libjpeg v7 API/ABI (incompatible with v6b)
  SIMD:         Use SIMD optimizations (SSE2, NEON, etc.)
  ARITH_ENC:    Arithmetic encoding support
  ARITH_DEC:    Arithmetic decoding support
  TURBOJPEG:    Include TurboJPEG API library

EOF
    exit 0
}

# Show usage if no arguments provided
if [[ $# -eq 0 ]]; then
    show_usage
fi

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            ;;
        --jpeg8)
            WITH_JPEG8=1
            WITH_JPEG7=0
            shift
            ;;
        --jpeg7)
            WITH_JPEG7=1
            WITH_JPEG8=0
            shift
            ;;
        --no-simd)
            WITH_SIMD=0
            shift
            ;;
        --no-arith-enc)
            WITH_ARITH_ENC=0
            shift
            ;;
        --no-arith-dec)
            WITH_ARITH_DEC=0
            shift
            ;;
        --no-turbojpeg)
            WITH_TURBOJPEG=0
            shift
            ;;
        --ios-target)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: --ios-target requires a version argument"
                exit 1
            fi
            IOS_DEPLOYMENT_TARGET="$2"
            shift 2
            ;;
        --macos-target)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: --macos-target requires a version argument"
                exit 1
            fi
            MACOS_DEPLOYMENT_TARGET="$2"
            shift 2
            ;;
        -*)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
        *)
            VERSION="$1"
            shift
            ;;
    esac
done

print_header "Building libjpeg-turbo XCFramework"
echo "Version: $VERSION"
echo ""
echo "Build Configuration:"
echo "  WITH_JPEG8:              $WITH_JPEG8"
echo "  WITH_JPEG7:              $WITH_JPEG7"
echo "  WITH_SIMD:               $WITH_SIMD"
echo "  WITH_ARITH_ENC:          $WITH_ARITH_ENC"
echo "  WITH_ARITH_DEC:          $WITH_ARITH_DEC"
echo "  WITH_TURBOJPEG:          $WITH_TURBOJPEG"
echo "  iOS Deployment Target:   $IOS_DEPLOYMENT_TARGET"
echo "  macOS Deployment Target: $MACOS_DEPLOYMENT_TARGET"
echo ""

# Step 1: Determine and fetch version
print_step "Determining version and downloading source"
fetch_libjpeg_turbo_source "$VERSION"

# Step 2: Build for all platforms
print_step "Building for all platforms"
build_all_platforms

# Step 3: Create universal binaries
print_step "Creating universal binaries"
create_universal_binaries

# Step 4: Create XCFrameworks
print_step "Creating XCFrameworks"
create_xcframeworks

print_header "Build Complete!"
echo "Output files in build/output/:"
echo "  - libjpeg.xcframework/"
echo "  - libturbojpeg.xcframework/"
echo ""
echo "Full path: ${OUTPUT_DIR}"
echo "Note: GitHub Actions will create the zip archive and podspec from these files"
echo ""
