#!/bin/bash

# Main build script for libjpeg-turbo Linux builds
# This script orchestrates the Linux build process

set -e  # Exit on error
set -u  # Exit on undefined variable

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Source other scripts
source "${SCRIPT_DIR}/scripts/common.sh"
source "${SCRIPT_DIR}/scripts/fetch-source.sh"
source "${SCRIPT_DIR}/scripts/build-linux.sh"
source "${SCRIPT_DIR}/scripts/create-checksums.sh"

# Default build options
VERSION="latest"
WITH_JPEG8=0
WITH_JPEG7=0
WITH_SIMD=1
WITH_ARITH_ENC=1
WITH_ARITH_DEC=1
WITH_TURBOJPEG=1

# Function to display usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] [VERSION]

Build libjpeg-turbo for Linux (x86, x64, armv7, armv8).

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
  -h, --help           Display this help message

Examples:
  $0                              # Show this help message
  $0 latest                       # Build latest version with defaults
  $0 3.0.1                        # Build version 3.0.1
  $0 --jpeg8 3.0.1                # Build v3.0.1 with JPEG8 compatibility
  $0 --no-simd latest             # Build latest without SIMD
  $0 --jpeg8 --no-arith-enc 3.0.1 # Build v3.0.1 with JPEG8, no arithmetic encoding

Build Options:
  JPEG8:        Emulate libjpeg v8 API/ABI (incompatible with v6b)
  JPEG7:        Emulate libjpeg v7 API/ABI (incompatible with v6b)
  SIMD:         Use SIMD optimizations (SSE2, NEON, etc.)
  ARITH_ENC:    Arithmetic encoding support
  ARITH_DEC:    Arithmetic decoding support
  TURBOJPEG:    Include TurboJPEG API library

Prerequisites:
  - CMake
  - GCC/Clang
  - NASM (for SIMD support on x86/x64)

  For cross-compilation:
  - gcc-multilib (for x86 on x64)
  - gcc-arm-linux-gnueabihf (for armv7)
  - gcc-aarch64-linux-gnu (for armv8/aarch64)

Note: The script will automatically detect available compilers and build
      for all supported architectures. If cross-compilation tools are not
      available, it will only build for the native architecture.

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

print_header "Building libjpeg-turbo for Linux"
echo "Version: $VERSION"
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

# Step 2: Build for all available Linux platforms
print_step "Building for all available Linux platforms"
build_all_linux_platforms

# Step 3: Create archive
print_step "Creating archive"
create_linux_archive "$VERSION_CLEAN"

# Step 4: Generate checksums
print_step "Generating checksums"
generate_checksums "$VERSION_CLEAN"

print_header "Build Complete!"
echo "Output files in build/output/:"
echo "  - libjpeg-turbo-${VERSION_CLEAN}-linux.tar.gz"
echo "  - libjpeg-turbo-${VERSION_CLEAN}-linux/ (directory with all binaries)"
echo "  - checksums.txt"
echo ""
echo "Full path: ${OUTPUT_DIR}"
echo ""
