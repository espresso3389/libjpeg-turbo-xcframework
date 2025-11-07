#!/bin/bash

# Script to build libjpeg-turbo for different platforms and architectures

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

    # Add system name for iOS builds
    if [ "$platform" = "ios" ] || [ "$platform" = "ios-simulator" ]; then
        cmake_args+=("-DCMAKE_SYSTEM_NAME=iOS")
        # Set CMAKE_SYSTEM_PROCESSOR to fix "string no output variable specified" error
        # See: https://github.com/libjpeg-turbo/libjpeg-turbo/issues
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
        cd "$SCRIPT_DIR"
        return 1
    fi

    if ! make -j$(get_cpu_count); then
        print_error "Build failed for ${build_name}"
        cd "$SCRIPT_DIR"
        return 1
    fi

    if ! make install; then
        print_error "Installation failed for ${build_name}"
        cd "$SCRIPT_DIR"
        return 1
    fi

    print_success "Built ${build_name}"
    cd "$SCRIPT_DIR"
}

build_all_platforms() {
    # Clean build, install, and output directories (but preserve source)
    rm -rf "$BUILD_DIR" "$INSTALL_DIR" "$FRAMEWORKS_DIR" "$OUTPUT_DIR"
    mkdir -p "$BUILD_DIR" "$INSTALL_DIR" "$OUTPUT_DIR"

    # Build iOS arm64 (device)
    build_platform "ios" "arm64" "12.0" "-fembed-bitcode" ""

    # Build iOS Simulator arm64
    build_platform "ios-simulator" "arm64" "12.0" "" "iphonesimulator"

    # Build iOS Simulator x86_64
    build_platform "ios-simulator" "x86_64" "12.0" "" "iphonesimulator"

    # Build macOS arm64
    build_platform "macos" "arm64" "11.0" "" ""

    # Build macOS x86_64
    build_platform "macos" "x86_64" "11.0" "" ""

    print_success "All platforms built successfully"
}
