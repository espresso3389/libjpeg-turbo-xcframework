#!/bin/bash

# Script to generate Package.swift for Swift Package Manager

get_git_repo_url() {
    # Try to get the GitHub repository URL from git remote
    local remote_url=$(git config --get remote.origin.url 2>/dev/null || echo "")

    if [ -z "$remote_url" ]; then
        echo ""
        return
    fi

    # Convert SSH URL to HTTPS format
    # git@github.com:user/repo.git -> https://github.com/user/repo
    if [[ "$remote_url" =~ ^git@github\.com:(.+)\.git$ ]]; then
        echo "https://github.com/${BASH_REMATCH[1]}"
    # https://github.com/user/repo.git -> https://github.com/user/repo
    elif [[ "$remote_url" =~ ^https://github\.com/(.+)\.git$ ]]; then
        echo "https://github.com/${BASH_REMATCH[1]}"
    # https://github.com/user/repo -> https://github.com/user/repo
    elif [[ "$remote_url" =~ ^https://github\.com/(.+)$ ]]; then
        echo "https://github.com/${BASH_REMATCH[1]}"
    else
        echo ""
    fi
}

generate_package_swift() {
    local version="$1"

    # Get repository URL from git
    local repo_url=$(get_git_repo_url)

    if [ -z "$repo_url" ]; then
        print_warning "Could not detect GitHub repository URL from git remote"
        print_warning "Skipping Package.swift generation"
        echo "You can manually create Package.swift using the checksums.txt file"
        return
    fi

    # Read checksum from checksums.txt
    local checksum_file="${OUTPUT_DIR}/checksums.txt"
    if [ ! -f "$checksum_file" ]; then
        print_error "checksums.txt not found. Cannot generate Package.swift"
        return 1
    fi

    # Extract just the checksum (first field)
    local checksum=$(awk '{print $1}' "$checksum_file")

    if [ -z "$checksum" ]; then
        print_error "Could not read checksum from checksums.txt"
        return 1
    fi

    local package_file="${OUTPUT_DIR}/Package.swift"

    echo "Generating Package.swift..."
    echo "  Repository: $repo_url"
    echo "  Version: $version"
    echo "  Checksum: $checksum"
    echo ""

    cat > "$package_file" << EOF
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "libjpeg-turbo",
    platforms: [
        .iOS(.v12),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "libjpeg",
            targets: ["libjpeg"]),
        .library(
            name: "libturbojpeg",
            targets: ["libturbojpeg"])
    ],
    targets: [
        .binaryTarget(
            name: "libjpeg",
            url: "${repo_url}/releases/download/${version}/libjpeg-turbo-${version}-xcframework.zip",
            checksum: "${checksum}"
        ),
        .binaryTarget(
            name: "libturbojpeg",
            url: "${repo_url}/releases/download/${version}/libjpeg-turbo-${version}-xcframework.zip",
            checksum: "${checksum}"
        )
    ]
)
EOF

    print_success "Generated Package.swift"
    echo ""
    echo "Package.swift has been created with:"
    echo "  - Repository: $repo_url"
    echo "  - Version: $version"
    echo "  - Checksum: $checksum"
    echo ""
    echo "You can now commit this file to your repository."
    echo ""
}
