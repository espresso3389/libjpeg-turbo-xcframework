#!/bin/bash

# Clean script to remove all build artifacts

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Cleaning build artifacts..."

# Remove entire build directory (contains everything)
rm -rf build/

echo "✓ Clean complete"
