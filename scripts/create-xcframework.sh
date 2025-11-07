#!/bin/bash

# Script to create XCFrameworks

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
        -output "${SCRIPT_DIR}/libjpeg.xcframework"
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
        -output "${SCRIPT_DIR}/libturbojpeg.xcframework"
    print_success "Created libturbojpeg.xcframework"
}

create_archive() {
    local version="$1"
    local archive_name="libjpeg-turbo-${version}-xcframework.zip"

    echo "Creating archive: ${archive_name}..."
    cd "$SCRIPT_DIR"
    zip -r "$archive_name" libjpeg.xcframework libturbojpeg.xcframework

    print_success "Created archive: ${archive_name}"
}
