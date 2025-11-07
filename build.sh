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

# Parse command line arguments
VERSION="${1:-latest}"

print_header "Building libjpeg-turbo XCFramework"
echo "Version: $VERSION"
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

print_header "Build Complete!"
echo "Output files:"
echo "  - libjpeg.xcframework"
echo "  - libturbojpeg.xcframework"
echo "  - libjpeg-turbo-${VERSION_CLEAN}-xcframework.zip"
echo "  - checksums.txt"
echo "  - Package.swift"
echo ""
