@echo off
REM Thin wrapper for build-windows.ps1
REM All logic is in the PowerShell script

setlocal

REM Get script directory
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%scripts\build-windows.ps1"

REM Check if PowerShell script exists
if not exist "%PS_SCRIPT%" (
    echo Error: PowerShell script not found: %PS_SCRIPT%
    exit /b 1
)

REM Execute PowerShell script, passing all arguments directly
pwsh -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*

REM Exit with PowerShell script's exit code
exit /b %ERRORLEVEL%
