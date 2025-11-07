#!/bin/bash

# Clean script to remove all build artifacts

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Cleaning build artifacts..."

# Remove build directories
rm -rf build/
rm -rf install/
rm -rf frameworks/
rm -rf libjpeg-turbo-source/

# Remove output files
rm -rf *.xcframework
rm -f *.zip
rm -f *.tar.gz
rm -f checksums.txt
rm -f Package.swift
rm -f build.log

echo "✓ Clean complete"
