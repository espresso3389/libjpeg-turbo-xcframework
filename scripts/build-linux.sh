#!/bin/bash

# Script to build libjpeg-turbo for Linux platforms and architectures

build_linux_platform() {
    local arch="$1"
    local cross_compile="$2"
    local cmake_toolchain="$3"

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
    cmake_args+=("-DWITH_JPEG8=${WITH_JPEG8:-0}")
    cmake_args+=("-DWITH_JPEG7=${WITH_JPEG7:-0}")
    cmake_args+=("-DWITH_SIMD=${WITH_SIMD:-1}")
    cmake_args+=("-DWITH_ARITH_ENC=${WITH_ARITH_ENC:-1}")
    cmake_args+=("-DWITH_ARITH_DEC=${WITH_ARITH_DEC:-1}")
    cmake_args+=("-DWITH_TURBOJPEG=${WITH_TURBOJPEG:-1}")

    # Add cross-compilation settings if specified
    if [ -n "$cmake_toolchain" ]; then
        cmake_args+=("-DCMAKE_TOOLCHAIN_FILE=${cmake_toolchain}")
    elif [ -n "$cross_compile" ]; then
        cmake_args+=("-DCMAKE_C_COMPILER=${cross_compile}gcc")
        cmake_args+=("-DCMAKE_CXX_COMPILER=${cross_compile}g++")
        cmake_args+=("-DCMAKE_SYSTEM_NAME=Linux")

        # Set system processor for different architectures
        case "$arch" in
            x86)
                cmake_args+=("-DCMAKE_SYSTEM_PROCESSOR=i686")
                cmake_args+=("-DCMAKE_C_FLAGS=-m32")
                cmake_args+=("-DCMAKE_CXX_FLAGS=-m32")
                ;;
            x64)
                cmake_args+=("-DCMAKE_SYSTEM_PROCESSOR=x86_64")
                ;;
            armv7)
                cmake_args+=("-DCMAKE_SYSTEM_PROCESSOR=armv7")
                ;;
            armv8|arm64)
                cmake_args+=("-DCMAKE_SYSTEM_PROCESSOR=aarch64")
                ;;
        esac
    else
        # Native build - set appropriate flags for x86 if needed
        if [ "$arch" = "x86" ]; then
            cmake_args+=("-DCMAKE_C_FLAGS=-m32")
            cmake_args+=("-DCMAKE_CXX_FLAGS=-m32")
        fi
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

build_all_linux_platforms() {
    # Clean build, install, and output directories (but preserve source)
    rm -rf "$BUILD_DIR" "$INSTALL_DIR" "$OUTPUT_DIR"
    mkdir -p "$BUILD_DIR" "$INSTALL_DIR" "$OUTPUT_DIR"

    local native_arch=$(detect_native_arch)
    echo "Detected native architecture: $native_arch"
    echo ""

    # Determine which architectures to build
    # If cross-compilation tools are available, build for all architectures
    # Otherwise, only build for native architecture

    local build_x86=false
    local build_x64=false
    local build_armv7=false
    local build_armv8=false

    # Check for cross-compilation tools
    local has_multilib=false
    local has_arm_cross=false

    if [ "$native_arch" = "x64" ]; then
        # Check for multilib support (x86 on x64)
        if command -v gcc &> /dev/null && gcc -m32 -x c /dev/null -o /dev/null 2>/dev/null; then
            has_multilib=true
        fi
    fi

    # Check for ARM cross-compilers
    if command -v arm-linux-gnueabihf-gcc &> /dev/null; then
        has_arm_cross=true
    fi

    if command -v aarch64-linux-gnu-gcc &> /dev/null; then
        has_arm_cross=true
    fi

    # Determine what to build
    case "$native_arch" in
        x64)
            build_x64=true
            if [ "$has_multilib" = true ]; then
                build_x86=true
                echo "Multilib support detected, will build x86 in addition to x64"
            fi
            ;;
        x86)
            build_x86=true
            ;;
        armv8)
            build_armv8=true
            ;;
        armv7)
            build_armv7=true
            ;;
    esac

    if [ "$has_arm_cross" = true ]; then
        echo "ARM cross-compilation tools detected"
        if command -v arm-linux-gnueabihf-gcc &> /dev/null; then
            build_armv7=true
            echo "Will build armv7"
        fi
        if command -v aarch64-linux-gnu-gcc &> /dev/null; then
            build_armv8=true
            echo "Will build armv8"
        fi
    fi

    echo ""

    # Build for detected/available architectures
    if [ "$build_x86" = true ]; then
        build_linux_platform "x86" "" ""
    else
        print_warning "Skipping x86 build (not native and no cross-compilation available)"
    fi

    if [ "$build_x64" = true ]; then
        build_linux_platform "x64" "" ""
    else
        print_warning "Skipping x64 build (not native and no cross-compilation available)"
    fi

    if [ "$build_armv7" = true ]; then
        if command -v arm-linux-gnueabihf-gcc &> /dev/null; then
            build_linux_platform "armv7" "arm-linux-gnueabihf-" ""
        else
            print_warning "Skipping armv7 build (not native and no cross-compiler available)"
        fi
    else
        print_warning "Skipping armv7 build (not native and no cross-compilation available)"
    fi

    if [ "$build_armv8" = true ]; then
        if [ "$native_arch" = "armv8" ]; then
            build_linux_platform "armv8" "" ""
        elif command -v aarch64-linux-gnu-gcc &> /dev/null; then
            build_linux_platform "armv8" "aarch64-linux-gnu-" ""
        else
            print_warning "Skipping armv8 build (not native and no cross-compiler available)"
        fi
    else
        print_warning "Skipping armv8 build (not native and no cross-compilation available)"
    fi

    print_success "All available Linux platforms built successfully"
}

create_linux_archive() {
    local version="$1"
    local archive_name="libjpeg-turbo-${version}-linux"
    local archive_path="${OUTPUT_DIR}/${archive_name}"

    print_step "Creating Linux archive"

    # Create archive directory structure
    mkdir -p "${archive_path}"

    # Copy files for each built architecture
    for arch_dir in "${INSTALL_DIR}"/linux-*; do
        if [ -d "$arch_dir" ]; then
            local arch=$(basename "$arch_dir" | sed 's/linux-//')
            mkdir -p "${archive_path}/${arch}"/{lib,include,bin}

            # Copy shared libraries
            if [ -d "${arch_dir}/lib" ]; then
                find "${arch_dir}/lib" -name "*.so*" -exec cp -P {} "${archive_path}/${arch}/lib/" \; 2>/dev/null || true
                find "${arch_dir}/lib" -name "*.a" -exec cp {} "${archive_path}/${arch}/lib/" \; 2>/dev/null || true
            fi

            # Copy headers
            if [ -d "${arch_dir}/include" ]; then
                cp -r "${arch_dir}/include"/* "${archive_path}/${arch}/include/" 2>/dev/null || true
            fi

            # Copy binaries
            if [ -d "${arch_dir}/bin" ]; then
                cp -r "${arch_dir}/bin"/* "${archive_path}/${arch}/bin/" 2>/dev/null || true
            fi
        fi
    done

    # Create README for the archive
    cat > "${archive_path}/README.txt" << EOF
libjpeg-turbo ${version} - Linux Binaries
==========================================

This archive contains pre-built libjpeg-turbo libraries for Linux.

Directory Structure:
-------------------
Each architecture directory (x86, x64, armv7, armv8) contains:
  lib/      - Shared (.so) and static (.a) libraries
  include/  - Header files
  bin/      - Utility executables

Build Configuration:
-------------------
JPEG8 Compatibility:      ${WITH_JPEG8:-0}
JPEG7 Compatibility:      ${WITH_JPEG7:-0}
SIMD Optimizations:       ${WITH_SIMD:-1}
Arithmetic Encoding:      ${WITH_ARITH_ENC:-1}
Arithmetic Decoding:      ${WITH_ARITH_DEC:-1}
TurboJPEG API:           ${WITH_TURBOJPEG:-1}

Usage:
------
1. Copy the appropriate architecture's .so files to your library path
   or application directory
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

    cd "$SCRIPT_DIR"
}
