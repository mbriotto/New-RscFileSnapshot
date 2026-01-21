@ECHO OFF
REM ============================================================================
REM Initialize-RubrikEnvironment.cmd
REM Version: 1.0 - Initial release
REM 
REM This script initializes the working environment for Rubrik Security Cloud
REM - Installs the Rubrik Security Cloud PowerShell Module (if needed)
REM - Unblocks PowerShell scripts in the current directory
REM - Shows next steps to configure backups
REM ============================================================================

SETLOCAL EnableDelayedExpansion

ECHO.
ECHO ============================================================
ECHO   Rubrik Security Cloud - Environment Initialization
ECHO ============================================================
ECHO.

REM Check for administrative privileges
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    ECHO [ERROR] This script MUST be run as Administrator!
    ECHO.
    ECHO The RubrikSecurityCloud module needs to be installed for ALL users
    ECHO including SYSTEM account for scheduled tasks
    ECHO.
    ECHO Please:
    ECHO   1. Right-click on this script
    ECHO   2. Select "Run as Administrator"
    ECHO   3. Run the script again
    ECHO.
    PAUSE
    EXIT /B 1
)

REM Get current directory
SET "SCRIPT_DIR=%~dp0"
CD /D "%SCRIPT_DIR%"

ECHO [STEP 1/3] Checking and installing Rubrik PowerShell Module...
ECHO.

REM Check if module is already installed
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "if (Get-Module -ListAvailable -Name RubrikSecurityCloud) { exit 0 } else { exit 1 }"

IF %ERRORLEVEL% EQU 0 (
    ECHO [OK] Rubrik Security Cloud PowerShell Module found
    
    REM Check if module is already imported
    PowerShell -NoProfile -ExecutionPolicy Bypass -Command "if (Get-Module -Name RubrikSecurityCloud) { exit 0 } else { exit 1 }"
    
    IF %ERRORLEVEL% EQU 0 (
        ECHO [OK] Module already imported in current session
        ECHO.
        GOTO :UNBLOCK_SCRIPTS
    ) ELSE (
        ECHO [INFO] Module installed but not imported
        ECHO [INFO] Importing module...
        
        REM Import the module
        PowerShell -NoProfile -ExecutionPolicy Bypass -Command "try { Import-Module RubrikSecurityCloud -ErrorAction Stop; exit 0 } catch { exit 1 }"
        
        IF %ERRORLEVEL% EQU 0 (
            ECHO [OK] Module imported successfully!
            ECHO.
            GOTO :UNBLOCK_SCRIPTS
        ) ELSE (
            ECHO [ERROR] Error importing module.
            ECHO.
            GOTO :NEXT_STEPS
        )
    )
)

ECHO [INFO] Module not found. Starting installation...
ECHO.

REM Install Rubrik Security Cloud module
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "Write-Host 'Installing RubrikSecurityCloud PowerShell Module...' -ForegroundColor Cyan; Write-Host 'Installing for ALL USERS (including SYSTEM account)...' -ForegroundColor Yellow; Write-Host 'This may take a few minutes...' -ForegroundColor Gray; Write-Host ''; try { if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) { Write-Host '[SETUP] Installing NuGet provider...' -ForegroundColor Yellow; Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null; } Write-Host '[DOWNLOAD] Downloading RubrikSecurityCloud module...' -ForegroundColor Cyan; Install-Module -Name RubrikSecurityCloud -Scope AllUsers -Force -AllowClobber; Write-Host ''; Write-Host '[SUCCESS] Module installed successfully for ALL USERS!' -ForegroundColor Green; Import-Module RubrikSecurityCloud; $version = (Get-Module RubrikSecurityCloud).Version; Write-Host '[OK] Module imported - Version:' $version -ForegroundColor Green; Write-Host '[INFO] Module available for SYSTEM account (scheduled tasks)' -ForegroundColor Cyan; exit 0; } catch { Write-Host ''; Write-Host '[ERROR] Error during installation:' $_.Exception.Message -ForegroundColor Red; Write-Host '[HINT] Make sure you are running as Administrator' -ForegroundColor Yellow; exit 1; }"

IF %ERRORLEVEL% NEQ 0 (
    ECHO.
    ECHO [ERROR] Module installation failed!
    ECHO.
    ECHO Common causes:
    ECHO   - Not running as Administrator
    ECHO   - No internet connection
    ECHO   - PowerShell Gallery blocked by firewall
    ECHO.
    ECHO To install manually:
    ECHO   1. Run PowerShell as Administrator
    ECHO   2. Execute: Install-Module RubrikSecurityCloud -Scope AllUsers -Force
    ECHO.
    GOTO :NEXT_STEPS
)

ECHO.

:UNBLOCK_SCRIPTS
ECHO [STEP 2/3] Unblocking PowerShell scripts in current directory...
ECHO.

REM Unblock all PowerShell scripts in current directory
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "$scriptPath = '%SCRIPT_DIR%'; $psFiles = Get-ChildItem -Path $scriptPath -Filter '*.ps1' -ErrorAction SilentlyContinue; if ($psFiles.Count -eq 0) { Write-Host '[INFO] No PowerShell scripts (.ps1) found in directory' -ForegroundColor Yellow; } else { Write-Host ('[INFO] Found ' + $psFiles.Count + ' PowerShell script(s)') -ForegroundColor Cyan; foreach ($file in $psFiles) { try { Unblock-File -Path $file.FullName -ErrorAction Stop; Write-Host ('[OK] Unblocked: ' + $file.Name) -ForegroundColor Green; } catch { Write-Host ('[SKIP] ' + $file.Name + ' - Already unblocked or error') -ForegroundColor Gray; } } }"

ECHO.
ECHO [STEP 3/3] Configuration completed
ECHO.

:NEXT_STEPS
ECHO ============================================================
ECHO   Initialization Complete!
ECHO ============================================================
ECHO.
ECHO Next Steps:
ECHO.
ECHO 1. Create a Service Account in Rubrik Security Cloud
ECHO    Run:
ECHO    .\New-RscServiceAccount.ps1 -ServiceAccountName 'FilesetBackup'
ECHO.
ECHO 2. Download the Service Account JSON credentials
ECHO    - Log in to Rubrik Security Cloud console
ECHO    - Go to Settings ^> Users ^> Service Accounts
ECHO    - Download the JSON credentials file
ECHO    - Place the JSON file in this directory:
ECHO      %SCRIPT_DIR%
ECHO.
ECHO 3. Run the snapshot script
ECHO    Run:
ECHO    .\New-RscFileSnapshot.ps1 -SlaName 'Gold'
ECHO.
ECHO 4. (Optional) Create scheduled tasks for automatic backups
ECHO    Run:
ECHO    .\New-RscFileSnapshotScheduler.ps1 -SlaName 'Gold'
ECHO.
ECHO -------------------------------------------------------------
ECHO For more information:
ECHO https://docs.rubrik.com/
ECHO -------------------------------------------------------------
ECHO.

ENDLOCAL
EXIT /B 0
