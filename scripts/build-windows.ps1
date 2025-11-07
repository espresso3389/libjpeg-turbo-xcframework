# PowerShell script to build libjpeg-turbo for Windows platforms

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Arguments
)

$ErrorActionPreference = "Stop"

# Default values
$Version = ""
$Arch = "all"  # all, x86, x64, arm64
$WithJpeg8 = 0
$WithJpeg7 = 0
$WithSimd = 1
$WithArithEnc = 1
$WithArithDec = 1
$WithTurbojpeg = 1
$ShowHelp = $false

# Parse arguments (supports both PowerShell style and batch style)
$NextIsArch = $false
foreach ($arg in $Arguments) {
    if ($NextIsArch) {
        $Arch = $arg
        $NextIsArch = $false
        continue
    }

    switch -Regex ($arg) {
        "^(-Help|--help|-h)$" {
            $ShowHelp = $true
        }
        "^(-Version|-v)$" {
            # Next argument should be the version
            continue
        }
        "^(-Arch|--arch)$" {
            $NextIsArch = $true
        }
        "^(-Jpeg8|--jpeg8)$" {
            $WithJpeg8 = 1
            $WithJpeg7 = 0
        }
        "^(-Jpeg7|--jpeg7)$" {
            $WithJpeg7 = 1
            $WithJpeg8 = 0
        }
        "^(-NoSimd|--no-simd)$" {
            $WithSimd = 0
        }
        "^(-NoArithEnc|--no-arith-enc)$" {
            $WithArithEnc = 0
        }
        "^(-NoArithDec|--no-arith-dec)$" {
            $WithArithDec = 0
        }
        "^(-NoTurbojpeg|--no-turbojpeg)$" {
            $WithTurbojpeg = 0
        }
        default {
            # Assume it's the version if it doesn't start with - or --
            if (-not $arg.StartsWith("-")) {
                $Version = $arg
            }
        }
    }
}

# Show help if requested or no version provided
if ($ShowHelp -or $Version -eq "") {
    Write-Host @"
Usage: build-windows.ps1 [OPTIONS] -Version VERSION
       build-windows.bat [OPTIONS] VERSION

Build libjpeg-turbo for Windows (x86, x64, arm64).

Arguments:
  -Version VERSION         Version to build (required)
                          Examples: latest, 3.0.1, 2.1.5
                          Use 'latest' to build the most recent release

Options:
  -Arch ARCH              Architecture to build (default: all)
                          Options: all, x86, x64, arm64
  -Jpeg8                  Build with libjpeg v8 API/ABI compatibility
  -Jpeg7                  Build with libjpeg v7 API/ABI compatibility
  -NoSimd                 Disable SIMD extensions
  -NoArithEnc             Disable arithmetic encoding support
  -NoArithDec             Disable arithmetic decoding support
  -NoTurbojpeg            Disable TurboJPEG API library
  -Help                   Display this help message

Examples:
  build-windows.ps1 -Version latest              # Build latest version
  build-windows.ps1 -Version 3.0.1               # Build version 3.0.1
  build-windows.ps1 -Jpeg8 -Version 3.0.1        # Build with JPEG8 compatibility
  build-windows.ps1 -NoSimd -Version latest      # Build without SIMD

  build-windows.bat latest                       # Build latest version
  build-windows.bat 3.0.1                        # Build version 3.0.1
  build-windows.bat --jpeg8 3.0.1                # Build with JPEG8 compatibility
  build-windows.bat --no-simd latest             # Build without SIMD

Prerequisites:
  - Windows 10 or later
  - CMake
  - Visual Studio 2017 or later (or Ninja build system)
  - NASM (for SIMD support)

Note:
  - The script will automatically download the source code.
  - If Ninja is available, it will be used for faster builds.
  - Otherwise, Visual Studio's MSBuild will be used.
"@
    exit 0
}

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir

# Directories
$BuildRoot = Join-Path $RootDir "build"
$SourceDir = Join-Path $BuildRoot "source"
$BuildDir = Join-Path $BuildRoot "cmake-build"
$InstallDir = Join-Path $BuildRoot "install"
$OutputDir = Join-Path $BuildRoot "output"

# Helper functions
function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host $Message -ForegroundColor Blue
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host ""
}

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "▶ $Message" -ForegroundColor Green
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-ErrorMsg {
    param([string]$Message)
    Write-Host "✗ Error: $Message" -ForegroundColor Red
}

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Cyan
Write-Host ""

# Check CMake
$cmake = Get-Command cmake -ErrorAction SilentlyContinue
if (-not $cmake) {
    Write-ErrorMsg "CMake is not installed or not in PATH"
    Write-Host "Please install CMake from https://cmake.org/download/" -ForegroundColor Yellow
    exit 1
}
Write-Host "✓ CMake found: $($cmake.Version)" -ForegroundColor Green

# Check NASM (only if SIMD is enabled)
if ($WithSimd -eq 1) {
    $nasm = Get-Command nasm -ErrorAction SilentlyContinue
    if (-not $nasm) {
        Write-ErrorMsg "NASM is not installed or not in PATH"
        Write-Host "NASM is required for SIMD support." -ForegroundColor Yellow
        Write-Host "Please install NASM from https://www.nasm.us/pub/nasm/releasebuilds/" -ForegroundColor Yellow
        Write-Host "Or run with -NoSimd flag to build without SIMD optimizations." -ForegroundColor Yellow
        exit 1
    }
    Write-Host "✓ NASM found: $($nasm.Version)" -ForegroundColor Green
} else {
    Write-Host "⊘ SIMD disabled, NASM not required" -ForegroundColor Yellow
}

# Check for Ninja (preferred) or Visual Studio / MSBuild
$ninja = Get-Command ninja -ErrorAction SilentlyContinue
$UseNinja = $false
if ($ninja) {
    Write-Host "✓ Ninja found: $($ninja.Version)" -ForegroundColor Green
    $UseNinja = $true
} else {
    Write-Host "⊘ Ninja not found, will use MSBuild" -ForegroundColor Yellow

    # Check Visual Studio / MSBuild
    $msbuild = Get-Command msbuild -ErrorAction SilentlyContinue
    if (-not $msbuild) {
        Write-Host "⚠ MSBuild not found in PATH, but CMake will attempt to locate Visual Studio" -ForegroundColor Yellow
    } else {
        Write-Host "✓ MSBuild found: $($msbuild.Version)" -ForegroundColor Green
    }
}

Write-Host ""

function Get-LatestVersion {
    Write-Host "Fetching latest libjpeg-turbo version from GitHub..."
    try {
        $ApiUrl = "https://api.github.com/repos/libjpeg-turbo/libjpeg-turbo/releases/latest"

        # Add authentication header if GITHUB_TOKEN is set
        $Headers = @{}
        if ($env:GITHUB_TOKEN) {
            $Headers["Authorization"] = "Bearer $env:GITHUB_TOKEN"
        }

        $Response = Invoke-RestMethod -Uri $ApiUrl -Headers $Headers -ErrorAction Stop
        $LatestVersion = $Response.tag_name
        Write-Host "Latest version: $LatestVersion"
        return $LatestVersion
    }
    catch {
        Write-ErrorMsg "Failed to fetch latest version: $_"
        exit 1
    }
}

function Get-LibjpegTurboSource {
    param([string]$Version)

    # If version is "latest", fetch the latest release
    if ($Version -eq "latest") {
        $Version = Get-LatestVersion
    }

    # Clean version (remove 'v' prefix if present)
    $VersionClean = $Version -replace '^v', ''

    Write-Step "Fetching libjpeg-turbo source version $VersionClean"

    # Create build directory if it doesn't exist
    if (-not (Test-Path $BuildRoot)) {
        New-Item -ItemType Directory -Force -Path $BuildRoot | Out-Null
    }

    # Check if source already exists
    if (Test-Path $SourceDir) {
        Write-Host "Source directory already exists. Checking version..."
        $CMakeFile = Join-Path $SourceDir "CMakeLists.txt"
        if (Test-Path $CMakeFile) {
            $Content = Get-Content $CMakeFile -Raw
            if ($Content -match "set\(VERSION\s+$VersionClean\)") {
                Write-Success "Source for version $VersionClean already present"
                return $VersionClean
            }
        }
        Write-Host "Removing old source..."
        Remove-Item -Recurse -Force $SourceDir
    }

    # Download source tarball
    $TarballUrl = "https://github.com/libjpeg-turbo/libjpeg-turbo/archive/refs/tags/$Version.tar.gz"
    $TarballPath = Join-Path $BuildRoot "libjpeg-turbo-$VersionClean.tar.gz"

    Write-Host "Downloading from $TarballUrl"
    try {
        Invoke-WebRequest -Uri $TarballUrl -OutFile $TarballPath -ErrorAction Stop
        Write-Success "Downloaded source tarball"
    }
    catch {
        Write-ErrorMsg "Failed to download source: $_"
        exit 1
    }

    # Extract tarball (requires tar command, available in Windows 10+)
    Write-Host "Extracting source..."
    try {
        $ExtractDir = Join-Path $BuildRoot "extract"
        if (Test-Path $ExtractDir) {
            Remove-Item -Recurse -Force $ExtractDir
        }
        New-Item -ItemType Directory -Force -Path $ExtractDir | Out-Null

        # Use tar command (built into Windows 10+)
        Push-Location $ExtractDir
        & tar -xzf $TarballPath
        if ($LASTEXITCODE -ne 0) {
            throw "tar extraction failed"
        }
        Pop-Location

        # Move extracted directory to source location
        $ExtractedDir = Get-ChildItem -Path $ExtractDir -Directory | Select-Object -First 1
        Move-Item -Path $ExtractedDir.FullName -Destination $SourceDir -Force

        # Clean up
        Remove-Item -Recurse -Force $ExtractDir
        Remove-Item -Force $TarballPath

        Write-Success "Extracted source to $SourceDir"
    }
    catch {
        Pop-Location
        Write-ErrorMsg "Failed to extract source: $_"
        exit 1
    }

    return $VersionClean
}

function Build-WindowsPlatform {
    param(
        [string]$Arch,
        [string]$Generator = "Visual Studio 17 2022",
        [bool]$UseNinja = $false
    )

    $BuildName = "windows-$Arch"
    $BuildPath = Join-Path $BuildDir $BuildName
    $InstallPath = Join-Path $InstallDir $BuildName

    Write-Host "Building for Windows $Arch..." -ForegroundColor Cyan

    # Create build directory
    New-Item -ItemType Directory -Force -Path $BuildPath | Out-Null
    Push-Location $BuildPath

    try {
        # Build CMake arguments based on generator
        if ($UseNinja) {
            # Ninja uses CMAKE_SYSTEM_PROCESSOR instead of -A flag
            $CmakeProcessor = switch ($Arch) {
                "x86"   { "x86" }
                "x64"   { "AMD64" }
                "arm64" { "ARM64" }
                default {
                    Write-ErrorMsg "Unsupported Windows architecture: $Arch"
                    return $false
                }
            }

            $CmakeArgs = @(
                $SourceDir,
                "-G", "Ninja",
                "-DCMAKE_BUILD_TYPE=Release",
                "-DCMAKE_SYSTEM_PROCESSOR=$CmakeProcessor",
                "-DCMAKE_INSTALL_PREFIX=$InstallPath",
                "-DENABLE_SHARED=ON",
                "-DENABLE_STATIC=ON",
                "-DWITH_JPEG8=$WithJpeg8",
                "-DWITH_JPEG7=$WithJpeg7",
                "-DWITH_SIMD=$WithSimd",
                "-DWITH_ARITH_ENC=$WithArithEnc",
                "-DWITH_ARITH_DEC=$WithArithDec",
                "-DWITH_TURBOJPEG=$WithTurbojpeg"
            )
        } else {
            # Map architecture names to CMake platform names for Visual Studio
            $CmakeArch = switch ($Arch) {
                "x86"   { "Win32" }
                "x64"   { "x64" }
                "arm64" { "ARM64" }
                default {
                    Write-ErrorMsg "Unsupported Windows architecture: $Arch"
                    return $false
                }
            }

            $CmakeArgs = @(
                $SourceDir,
                "-G", $Generator,
                "-A", $CmakeArch,
                "-DCMAKE_INSTALL_PREFIX=$InstallPath",
                "-DCMAKE_BUILD_TYPE=Release",
                "-DENABLE_SHARED=ON",
                "-DENABLE_STATIC=ON",
                "-DWITH_JPEG8=$WithJpeg8",
                "-DWITH_JPEG7=$WithJpeg7",
                "-DWITH_SIMD=$WithSimd",
                "-DWITH_ARITH_ENC=$WithArithEnc",
                "-DWITH_ARITH_DEC=$WithArithDec",
                "-DWITH_TURBOJPEG=$WithTurbojpeg"
            )
        }

        # Configure
        Write-Host "Configuring..."
        & cmake $CmakeArgs
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorMsg "CMake configuration failed for $BuildName"
            return $false
        }

        # Build
        Write-Host "Building..."
        if ($UseNinja) {
            # Ninja is a single-config generator, no --config flag needed
            & cmake --build . --parallel
        } else {
            # Multi-config generator (Visual Studio) needs --config flag
            & cmake --build . --config Release --parallel
        }
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorMsg "Build failed for $BuildName"
            return $false
        }

        # Install
        Write-Host "Installing..."
        if ($UseNinja) {
            # Ninja is a single-config generator
            & cmake --install .
        } else {
            # Multi-config generator (Visual Studio)
            & cmake --install . --config Release
        }
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorMsg "Installation failed for $BuildName"
            return $false
        }

        Write-Success "Built $BuildName"
        return $true
    }
    finally {
        Pop-Location
    }
}

function Organize-WindowsOutput {
    param([string]$Version, [string]$Arch)

    Write-Step "Organizing Windows output"

    # Create output directory structure for single architecture
    New-Item -ItemType Directory -Force -Path "$OutputDir\bin" | Out-Null
    New-Item -ItemType Directory -Force -Path "$OutputDir\lib" | Out-Null
    New-Item -ItemType Directory -Force -Path "$OutputDir\include" | Out-Null

    $InstallPath = Join-Path $InstallDir "windows-$Arch"

    # Copy DLLs and executables
    $BinPath = Join-Path $InstallPath "bin"
    if (Test-Path $BinPath) {
        Get-ChildItem -Path $BinPath -Filter "*.dll" -ErrorAction SilentlyContinue |
            Copy-Item -Destination "$OutputDir\bin" -Force
        Get-ChildItem -Path $BinPath -Filter "*.exe" -ErrorAction SilentlyContinue |
            Copy-Item -Destination "$OutputDir\bin" -Force
    }

    # Copy import libraries
    $LibPath = Join-Path $InstallPath "lib"
    if (Test-Path $LibPath) {
        Get-ChildItem -Path $LibPath -Filter "*.lib" -ErrorAction SilentlyContinue |
            Copy-Item -Destination "$OutputDir\lib" -Force
    }

    # Copy headers
    $IncludePath = Join-Path $InstallPath "include"
    if (Test-Path $IncludePath) {
        Get-ChildItem -Path $IncludePath -Recurse |
            Copy-Item -Destination "$OutputDir\include" -Force
    }

    # Create README
    $ReadmeContent = @"
libjpeg-turbo $Version - Windows $Arch Binaries
============================================

This package contains pre-built libjpeg-turbo libraries for Windows $Arch.

Directory Structure:
-------------------
bin\      - DLL files and executables
lib\      - Import libraries (.lib files)
include\  - Header files

Build Configuration:
-------------------
JPEG8 Compatibility:      $WithJpeg8
JPEG7 Compatibility:      $WithJpeg7
SIMD Optimizations:       $WithSimd
Arithmetic Encoding:      $WithArithEnc
Arithmetic Decoding:      $WithArithDec
TurboJPEG API:           $WithTurbojpeg

Usage:
------
1. Copy the DLL files to your application directory
2. Link against the .lib files when building your application
3. Include the header files in your project

For more information, visit: https://libjpeg-turbo.org/
"@

    Set-Content -Path "$OutputDir\README.txt" -Value $ReadmeContent
    Write-Success "Organized output files"
}

# Main execution
Write-Header "Building libjpeg-turbo for Windows"

Write-Host "Build Configuration:"
Write-Host "  Version:                 $Version"
Write-Host "  WITH_JPEG8:              $WithJpeg8"
Write-Host "  WITH_JPEG7:              $WithJpeg7"
Write-Host "  WITH_SIMD:               $WithSimd"
Write-Host "  WITH_ARITH_ENC:          $WithArithEnc"
Write-Host "  WITH_ARITH_DEC:          $WithArithDec"
Write-Host "  WITH_TURBOJPEG:          $WithTurbojpeg"
Write-Host ""

# Fetch source
$VersionClean = Get-LibjpegTurboSource -Version $Version

# Clean and create build directories
if (Test-Path $BuildDir) {
    Remove-Item -Recurse -Force $BuildDir
}
if (Test-Path $InstallDir) {
    Remove-Item -Recurse -Force $InstallDir
}
if (Test-Path $OutputDir) {
    Remove-Item -Recurse -Force $OutputDir
}

New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

# Detect generator to use
if ($UseNinja) {
    Write-Host "Using CMake generator: Ninja" -ForegroundColor Green
} else {
    # Detect Visual Studio generator
    $Generator = "Visual Studio 17 2022"
    $CmakeHelp = & cmake --help 2>&1 | Out-String
    if ($CmakeHelp -notmatch "Visual Studio 17 2022") {
        if ($CmakeHelp -match "Visual Studio 16 2019") {
            $Generator = "Visual Studio 16 2019"
        }
        elseif ($CmakeHelp -match "Visual Studio 15 2017") {
            $Generator = "Visual Studio 15 2017"
        }
        else {
            Write-Host "Warning: Could not detect Visual Studio generator, using default: $Generator" -ForegroundColor Yellow
        }
    }
    Write-Host "Using CMake generator: $Generator"
}
Write-Host ""

# Build all architectures
# Build based on architecture selection
$Success = $true
if ($Arch -eq "all") {
    Write-Step "Building for all Windows platforms"
    $Success = (Build-WindowsPlatform -Arch "x86" -Generator $Generator -UseNinja $UseNinja) -and $Success
    $Success = (Build-WindowsPlatform -Arch "x64" -Generator $Generator -UseNinja $UseNinja) -and $Success
    $Success = (Build-WindowsPlatform -Arch "arm64" -Generator $Generator -UseNinja $UseNinja) -and $Success
} else {
    Write-Step "Building for Windows $Arch"
    $Success = Build-WindowsPlatform -Arch $Arch -Generator $Generator -UseNinja $UseNinja
}

if (-not $Success) {
    Write-ErrorMsg "Build failed for one or more platforms"
    exit 1
}

Write-Success "All Windows platforms built successfully"

# Organize output (VersionClean was already set by Get-LibjpegTurboSource)
Organize-WindowsOutput -Version $VersionClean -Arch $Arch

Write-Header "Build Complete!"
Write-Host "Output files in $OutputDir"
Write-Host "  - bin\"
Write-Host "  - lib\"
Write-Host "  - include\"
Write-Host "  - README.txt"
Write-Host ""
Write-Host "Note: GitHub Actions will create the zip archive from these files"
Write-Host ""
