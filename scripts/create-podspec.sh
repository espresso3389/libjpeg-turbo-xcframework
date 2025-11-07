#!/bin/bash

# Script to generate podspec for CocoaPods

generate_podspec() {
    local version="$1"

    # Get repository URL from git
    local repo_url=$(get_git_repo_url)

    if [ -z "$repo_url" ]; then
        print_warning "Could not detect GitHub repository URL from git remote"
        print_warning "Skipping podspec generation"
        echo "You can manually create podspec using the template in README.md"
        return
    fi

    # Read checksum from checksums.txt
    local checksum_file="${OUTPUT_DIR}/checksums.txt"
    if [ ! -f "$checksum_file" ]; then
        print_error "checksums.txt not found. Cannot generate podspec"
        return 1
    fi

    # Extract just the checksum (first field)
    local checksum=$(awk '{print $1}' "$checksum_file")

    if [ -z "$checksum" ]; then
        print_error "Could not read checksum from checksums.txt"
        return 1
    fi

    local podspec_file="${OUTPUT_DIR}/libjpeg-turbo.podspec"

    echo "Generating libjpeg-turbo.podspec..."
    echo "  Repository: $repo_url"
    echo "  Version: $version"
    echo "  Checksum: $checksum"
    echo ""

    cat > "$podspec_file" << EOF
Pod::Spec.new do |s|
  s.name             = 'libjpeg-turbo'
  s.version          = '${version}'
  s.summary          = 'libjpeg-turbo XCFramework for iOS and macOS'
  s.description      = <<-DESC
    libjpeg-turbo is a JPEG image codec that uses SIMD instructions to accelerate
    baseline JPEG compression and decompression on x86, x86-64, Arm, PowerPC, and
    MIPS systems. This pod provides prebuilt XCFrameworks for iOS and macOS.
  DESC

  s.homepage         = '${repo_url}'
  s.license          = { :type => 'BSD', :file => 'LICENSE.md' }
  s.author           = { 'libjpeg-turbo' => 'information@libjpeg-turbo.org' }
  s.source           = {
    :http => '${repo_url}/releases/download/${version}/libjpeg-turbo-${version}-xcframework.zip',
    :sha256 => '${checksum}'
  }

  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '11.0'

  s.vendored_frameworks = 'libjpeg.xcframework', 'libturbojpeg.xcframework'

  s.libraries = 'c++'
end
EOF

    print_success "Generated libjpeg-turbo.podspec"
    echo ""
    echo "Podspec has been created with:"
    echo "  - Repository: $repo_url"
    echo "  - Version: $version"
    echo "  - Checksum: $checksum"
    echo ""
    echo "To use:"
    echo "  1. Commit the podspec to your repository"
    echo "  2. Tag with version ${version}"
    echo "  3. Push to GitHub"
    echo "  4. Optionally publish to CocoaPods trunk"
    echo ""
}
