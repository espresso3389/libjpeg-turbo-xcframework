#!/bin/bash

# Script to generate checksums

generate_checksums() {
    local version="$1"
    local archive_name="libjpeg-turbo-${version}-xcframework.zip"

    echo "Generating SHA256 checksums..."
    cd "$SCRIPT_DIR"

    shasum -a 256 "$archive_name" > checksums.txt

    echo ""
    echo "Checksums:"
    cat checksums.txt
    echo ""

    print_success "Generated checksums.txt"
}
