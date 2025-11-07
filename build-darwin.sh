#!/bin/bash

# Main build script for libjpeg-turbo XCFramework
# This script orchestrates the entire build process

set -e  # Exit on error
set -u  # Exit on undefined variable

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Source other scripts
source "${SCRIPT_DIR}/scripts/common.sh"
source "${SCRIPT_DIR}/scripts/fetch-source.sh"
source "${SCRIPT_DIR}/scripts/build-platforms.sh"
source "${SCRIPT_DIR}/scripts/create-universal.sh"
source "${SCRIPT_DIR}/scripts/create-xcframework.sh"
source "${SCRIPT_DIR}/scripts/create-checksums.sh"
source "${SCRIPT_DIR}/scripts/create-package-swift.sh"
source "${SCRIPT_DIR}/scripts/create-podspec.sh"

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

# Step 5: Create archive
print_step "Creating archive"
create_archive "$VERSION_CLEAN"

# Step 6: Generate checksums
print_step "Generating checksums"
generate_checksums "$VERSION_CLEAN"

# Step 7: Generate Package.swift
print_step "Generating Package.swift"
generate_package_swift "$VERSION_CLEAN"

# Step 8: Generate podspec
print_step "Generating podspec"
generate_podspec "$VERSION_CLEAN"

print_header "Build Complete!"
echo "Output files in build/output/:"
echo "  - libjpeg.xcframework"
echo "  - libturbojpeg.xcframework"
echo "  - libjpeg-turbo-${VERSION_CLEAN}-xcframework.zip"
echo "  - checksums.txt"
echo "  - Package.swift"
echo "  - libjpeg-turbo.podspec"
echo ""
echo "Full path: ${OUTPUT_DIR}"
echo ""
