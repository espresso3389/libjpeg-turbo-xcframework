#!/bin/bash

# Unified build script for libjpeg-turbo Linux
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
ARCH="auto"  # auto, x86, x64, armv7, armv8

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

# Get number of CPU cores
get_cpu_count() {
    nproc 2>/dev/null || echo "4"
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
# Build Functions
# =============================================================================

detect_native_arch() {
    local arch=$(uname -m)
    case "$arch" in
        x86_64)
            echo "x64"
            ;;
        i686|i386)
            echo "x86"
            ;;
        aarch64|arm64)
            echo "armv8"
            ;;
        armv7l)
            echo "armv7"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

build_linux_platform() {
    local arch="$1"

    local build_name="linux-${arch}"
    local build_path="${BUILD_DIR}/${build_name}"
    local install_path="${INSTALL_DIR}/${build_name}"

    echo "Building for Linux ${arch}..."

    mkdir -p "$build_path"
    cd "$build_path"

    local cmake_args=(
        "$SOURCE_DIR"
        "-DCMAKE_INSTALL_PREFIX=${install_path}"
        "-DCMAKE_BUILD_TYPE=Release"
        "-DENABLE_SHARED=ON"
        "-DENABLE_STATIC=ON"
    )

    # Add libjpeg-turbo specific build options
    cmake_args+=("-DWITH_JPEG8=${WITH_JPEG8}")
    cmake_args+=("-DWITH_JPEG7=${WITH_JPEG7}")
    cmake_args+=("-DWITH_SIMD=${WITH_SIMD}")
    cmake_args+=("-DWITH_ARITH_ENC=${WITH_ARITH_ENC}")
    cmake_args+=("-DWITH_ARITH_DEC=${WITH_ARITH_DEC}")
    cmake_args+=("-DWITH_TURBOJPEG=${WITH_TURBOJPEG}")

    # Set architecture-specific flags
    case "$arch" in
        x86)
            cmake_args+=("-DCMAKE_C_FLAGS=-m32")
            cmake_args+=("-DCMAKE_CXX_FLAGS=-m32")
            ;;
    esac

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

build_for_architecture() {
    local target_arch="$1"

    # Clean build, install, and output directories (but preserve source)
    rm -rf "$BUILD_DIR" "$INSTALL_DIR" "$OUTPUT_DIR"
    mkdir -p "$BUILD_DIR" "$INSTALL_DIR" "$OUTPUT_DIR"

    build_linux_platform "$target_arch"

    print_success "Build complete for ${target_arch}"
}

# =============================================================================
# Packaging Functions
# =============================================================================

create_linux_archive() {
    local version="$1"
    local arch="$2"
    local archive_name="libjpeg-turbo-${version}-linux-${arch}"
    local archive_path="${OUTPUT_DIR}/${archive_name}"

    print_step "Creating Linux archive"

    # Create archive directory structure
    mkdir -p "${archive_path}"/{lib,include,bin}

    local arch_dir="${INSTALL_DIR}/linux-${arch}"

    # Copy shared libraries
    if [ -d "${arch_dir}/lib" ]; then
        find "${arch_dir}/lib" -name "*.so*" -exec cp -P {} "${archive_path}/lib/" \; 2>/dev/null || true
        find "${arch_dir}/lib" -name "*.a" -exec cp {} "${archive_path}/lib/" \; 2>/dev/null || true
    fi

    # Copy headers
    if [ -d "${arch_dir}/include" ]; then
        cp -r "${arch_dir}/include"/* "${archive_path}/include/" 2>/dev/null || true
    fi

    # Copy binaries
    if [ -d "${arch_dir}/bin" ]; then
        cp -r "${arch_dir}/bin"/* "${archive_path}/bin/" 2>/dev/null || true
    fi

    # Create README for the archive
    cat > "${archive_path}/README.txt" << EOF
libjpeg-turbo ${version} - Linux ${arch} Binaries
=================================================

This archive contains pre-built libjpeg-turbo libraries for Linux ${arch}.

Directory Structure:
-------------------
  lib/      - Shared (.so) and static (.a) libraries
  include/  - Header files
  bin/      - Utility executables

Build Configuration:
-------------------
JPEG8 Compatibility:      ${WITH_JPEG8}
JPEG7 Compatibility:      ${WITH_JPEG7}
SIMD Optimizations:       ${WITH_SIMD}
Arithmetic Encoding:      ${WITH_ARITH_ENC}
Arithmetic Decoding:      ${WITH_ARITH_DEC}
TurboJPEG API:           ${WITH_TURBOJPEG}

Usage:
------
1. Copy the .so files to your library path or application directory
2. Link against the libraries when building your application:
   - For libjpeg: -ljpeg
   - For libturbojpeg: -lturbojpeg
3. Include the header files in your project

You may need to add the library directory to LD_LIBRARY_PATH:
  export LD_LIBRARY_PATH=/path/to/libs:\$LD_LIBRARY_PATH

For more information, visit: https://libjpeg-turbo.org/
EOF

    # Create tar.gz archive
    cd "${OUTPUT_DIR}"
    if command -v tar &> /dev/null; then
        tar -czf "${archive_name}.tar.gz" "${archive_name}"
        print_success "Created ${archive_name}.tar.gz"
    else
        print_warning "tar command not found, archive directory created but not compressed"
    fi

    cd "$PROJECT_ROOT"
}

generate_checksums() {
    local version="$1"
    local arch="$2"
    local archive_name="libjpeg-turbo-${version}-linux-${arch}.tar.gz"

    echo "Generating SHA256 checksums..."
    cd "$OUTPUT_DIR"

    sha256sum "$archive_name" > checksums.txt

    echo ""
    echo "Checksums:"
    cat checksums.txt
    echo ""

    print_success "Generated checksums.txt"
    cd "$PROJECT_ROOT"
}

# =============================================================================
# Main Execution
# =============================================================================

# Function to display usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] [VERSION]

Build libjpeg-turbo for Linux.

Arguments:
  VERSION              Version to build (required)
                       Examples: latest, 3.0.1, 2.1.5
                       Use 'latest' to build the most recent release

Options:
  --arch ARCH          Architecture to build (default: auto-detect)
                       Options: x86, x64, armv7, armv8
  --jpeg8              Build with libjpeg v8 API/ABI compatibility
                       (mutually exclusive with --jpeg7)
  --jpeg7              Build with libjpeg v7 API/ABI compatibility
                       (mutually exclusive with --jpeg8)
  --no-simd            Disable SIMD extensions
  --no-arith-enc       Disable arithmetic encoding support
  --no-arith-dec       Disable arithmetic decoding support
  --no-turbojpeg       Disable TurboJPEG API library
  -h, --help           Display this help message

Examples:
  $0 latest                       # Build latest version for native arch
  $0 --arch x64 3.0.1             # Build version 3.0.1 for x64
  $0 --jpeg8 --arch armv8 3.0.1   # Build v3.0.1 with JPEG8 for ARM64
  $0 --no-simd latest             # Build latest without SIMD

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
        --arch)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: --arch requires an architecture argument"
                exit 1
            fi
            ARCH="$2"
            shift 2
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

# Determine architecture
if [ "$ARCH" = "auto" ]; then
    ARCH=$(detect_native_arch)
    echo "Auto-detected architecture: $ARCH"
fi

print_header "Building libjpeg-turbo for Linux"
echo "Version: $VERSION"
echo "Architecture: $ARCH"
echo ""
echo "Build Configuration:"
echo "  WITH_JPEG8:              $WITH_JPEG8"
echo "  WITH_JPEG7:              $WITH_JPEG7"
echo "  WITH_SIMD:               $WITH_SIMD"
echo "  WITH_ARITH_ENC:          $WITH_ARITH_ENC"
echo "  WITH_ARITH_DEC:          $WITH_ARITH_DEC"
echo "  WITH_TURBOJPEG:          $WITH_TURBOJPEG"
echo ""

# Step 1: Determine and fetch version
print_step "Determining version and downloading source"
fetch_libjpeg_turbo_source "$VERSION"

# Step 2: Build for specified architecture
print_step "Building for $ARCH"
build_for_architecture "$ARCH"

# Step 3: Create archive
print_step "Creating archive"
create_linux_archive "$VERSION_CLEAN" "$ARCH"

# Step 4: Generate checksums
print_step "Generating checksums"
generate_checksums "$VERSION_CLEAN" "$ARCH"

print_header "Build Complete!"
echo "Output files in build/output/:"
echo "  - libjpeg-turbo-${VERSION_CLEAN}-linux-${ARCH}.tar.gz"
echo "  - checksums.txt"
echo ""
echo "Full path: ${OUTPUT_DIR}"
echo ""
