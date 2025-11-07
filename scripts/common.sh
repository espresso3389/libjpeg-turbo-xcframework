#!/bin/bash

# Common utilities and variables

# Determine script directory (works when sourced or executed)
if [ -n "${BASH_SOURCE[0]}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# If SCRIPT_DIR is still not set, use current directory
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(pwd)"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sysctl -n hw.ncpu
    else
        nproc
    fi
}

# Global variables that will be set by fetch-source.sh
VERSION_CLEAN=""

# Directories - all build artifacts go inside build/
BUILD_ROOT="${SCRIPT_DIR}/build"
SOURCE_DIR="${BUILD_ROOT}/source"
BUILD_DIR="${BUILD_ROOT}/cmake-build"
INSTALL_DIR="${BUILD_ROOT}/install"
FRAMEWORKS_DIR="${BUILD_ROOT}/frameworks"
OUTPUT_DIR="${BUILD_ROOT}/output"
