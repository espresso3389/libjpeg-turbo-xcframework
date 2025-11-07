#!/bin/bash

# Universal build script for libjpeg-turbo
# Automatically detects platform and calls the appropriate build script

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect platform
detect_platform() {
    case "$(uname -s)" in
        Darwin*)
            echo "darwin"
            ;;
        Linux*)
            echo "linux"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

PLATFORM=$(detect_platform)

if [ "$PLATFORM" = "unknown" ]; then
    echo "Error: Unsupported platform '$(uname -s)'"
    echo "Supported platforms: macOS (Darwin), Linux, Windows"
    exit 1
fi

# Select the appropriate build script
case "$PLATFORM" in
    darwin)
        BUILD_SCRIPT="${SCRIPT_DIR}/scripts/build-darwin.sh"
        ;;
    linux)
        BUILD_SCRIPT="${SCRIPT_DIR}/scripts/build-linux.sh"
        ;;
    windows)
        echo "Error: For Windows, please use build.bat instead"
        exit 1
        ;;
esac

# Check if build script exists
if [ ! -f "$BUILD_SCRIPT" ]; then
    echo "Error: Build script not found: $BUILD_SCRIPT"
    exit 1
fi

# Make sure it's executable
chmod +x "$BUILD_SCRIPT"

# Execute the platform-specific build script, passing all arguments
exec "$BUILD_SCRIPT" "$@"
