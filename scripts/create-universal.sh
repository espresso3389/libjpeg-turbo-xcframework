#!/bin/bash

# Script to create universal (fat) binaries using lipo

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
