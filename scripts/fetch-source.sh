#!/bin/bash

# Script to fetch libjpeg-turbo source code

fetch_libjpeg_turbo_source() {
    local input_version="$1"

    if [ "$input_version" = "latest" ]; then
        echo "Fetching latest release version..."
        LATEST_VERSION=$(curl -s https://api.github.com/repos/libjpeg-turbo/libjpeg-turbo/releases/latest | jq -r .tag_name)
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

    cd "$SCRIPT_DIR"

    print_success "Source downloaded and extracted to $SOURCE_DIR"
}
