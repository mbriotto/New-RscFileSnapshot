@ECHO OFF
REM ============================================================================
REM Initialize-RubrikEnvironment.cmd  
REM Version: 1.6.0 - Added ExecutionPolicy configuration
REM ============================================================================

SETLOCAL EnableDelayedExpansion

ECHO.
ECHO ============================================================
ECHO   Rubrik Security Cloud - Environment Initialization
ECHO ============================================================
ECHO.

REM Check admin
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    ECHO [ERROR] Run as Administrator!
    PAUSE
    EXIT /B 1
)

SET "SCRIPT_DIR=%~dp0"
CD /D "%SCRIPT_DIR%"

ECHO [STEP 1/5] Checking module...
ECHO.

PowerShell -NoProfile -ExecutionPolicy Bypass -Command "if (Get-Module -ListAvailable -Name RubrikSecurityCloud) { exit 0 } else { exit 1 }"

IF %ERRORLEVEL% EQU 0 (
    ECHO [OK] Already installed
    PowerShell -NoProfile -ExecutionPolicy Bypass -Command "$m = Get-Module -ListAvailable -Name RubrikSecurityCloud | Select -First 1; Write-Host '  Version:' $m.Version -ForegroundColor Gray"
    ECHO.
    GOTO :CONFIGURE_EXECUTION_POLICY
)

ECHO [INFO] Module not found. Checking options...
ECHO.

SET "OFFLINE_MODULE_FOUND=0"
SET "OFFLINE_MODULE_PATH="

IF EXIST "%SCRIPT_DIR%RubrikSecurityCloud" (
    IF EXIST "%SCRIPT_DIR%RubrikSecurityCloud\RubrikSecurityCloud.psd1" (
        SET "OFFLINE_MODULE_FOUND=1"
        SET "OFFLINE_MODULE_PATH=%SCRIPT_DIR%RubrikSecurityCloud"
        ECHO [FOUND] Folder: .\RubrikSecurityCloud\
    )
)

IF EXIST "%SCRIPT_DIR%RubrikSecurityCloud.zip" (
    SET "OFFLINE_MODULE_FOUND=1"
    SET "OFFLINE_MODULE_PATH=%SCRIPT_DIR%RubrikSecurityCloud.zip"
    ECHO [FOUND] ZIP: .\RubrikSecurityCloud.zip
)

IF !OFFLINE_MODULE_FOUND! EQU 0 (
    FOR %%F IN ("%SCRIPT_DIR%*rubrik*.zip") DO (
        SET "OFFLINE_MODULE_FOUND=1"
        SET "OFFLINE_MODULE_PATH=%%F"
        ECHO [FOUND] ZIP: %%~nxF
        GOTO :FOUND_OFFLINE
    )
)

:FOUND_OFFLINE

IF !OFFLINE_MODULE_FOUND! EQU 1 (
    ECHO.
    ECHO ============================================================
    ECHO   Installation Method
    ECHO ============================================================
    ECHO.
    ECHO   [1] OFFLINE (recommended)
    ECHO   [2] ONLINE (PowerShell Gallery)
    ECHO   [3] Cancel
    ECHO.
    CHOICE /C 123 /N /M "Choice [1/2/3]: "
    
    IF !ERRORLEVEL! EQU 1 GOTO :INSTALL_OFFLINE
    IF !ERRORLEVEL! EQU 2 GOTO :INSTALL_ONLINE
    IF !ERRORLEVEL! EQU 3 GOTO :CONFIGURE_EXECUTION_POLICY
) ELSE (
    ECHO [INFO] Attempting online installation...
    ECHO.
    GOTO :INSTALL_ONLINE
)

:INSTALL_OFFLINE
ECHO.
ECHO ============================================================
ECHO   Installing from Offline Package
ECHO ============================================================
ECHO.

REM Extract embedded PowerShell script to temp file
SET "TEMP_PS1=%TEMP%\Install-RscOffline-%RANDOM%.ps1"
findstr /B /C:"#PS1#" "%~f0" > "%TEMP_PS1%.tmp"
powershell -Command "(Get-Content '%TEMP_PS1%.tmp') -replace '^#PS1# ', '' | Set-Content '%TEMP_PS1%' -Encoding UTF8"
del "%TEMP_PS1%.tmp"

REM Execute the script
PowerShell -NoProfile -ExecutionPolicy Bypass -File "%TEMP_PS1%" -ModulePath "!OFFLINE_MODULE_PATH!"
SET RESULT=%ERRORLEVEL%

REM Clean up
DEL "%TEMP_PS1%" 2>nul

IF %RESULT% EQU 0 (
    ECHO.
    GOTO :CONFIGURE_EXECUTION_POLICY
) ELSE (
    ECHO.
    ECHO [ERROR] Offline installation failed
    ECHO.
    ECHO Try online installation instead? (Y/N)
    CHOICE /C YN /N /M "> "
    IF !ERRORLEVEL! EQU 1 (
        ECHO.
        GOTO :INSTALL_ONLINE
    ) ELSE (
        GOTO :CONFIGURE_EXECUTION_POLICY
    )
)

:INSTALL_ONLINE
ECHO.
ECHO ============================================================
ECHO   Installing from PowerShell Gallery
ECHO ============================================================
ECHO.

PowerShell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;Write-Host 'Installing module...' -ForegroundColor Cyan;Write-Host 'For ALL USERS (SYSTEM included)' -ForegroundColor Yellow;Write-Host '';try{Write-Host '[SETUP] Configuring...' -ForegroundColor Cyan;$g=Get-PSRepository PSGallery -EA 0;if(!$g){Register-PSRepository -Default};Set-PSRepository PSGallery -InstallationPolicy Trusted;Write-Host '[DOWNLOAD] Installing NuGet...' -ForegroundColor Cyan;Install-PackageProvider NuGet -MinimumVersion 2.8.5.201 -Force|Out-Null;Write-Host '[DOWNLOAD] Downloading module (~50-100MB)...' -ForegroundColor Cyan;Write-Host '[INFO] This may take several minutes...' -ForegroundColor Gray;Install-Module RubrikSecurityCloud -Scope AllUsers -Force -AllowClobber;Write-Host '';Write-Host '[SUCCESS] Installed!' -ForegroundColor Green;Import-Module RubrikSecurityCloud;$v=(Get-Module RubrikSecurityCloud).Version;Write-Host \"[OK] Version: $v\" -ForegroundColor Green;exit 0}catch{Write-Host '';Write-Host \"[ERROR] $($_.Exception.Message)\" -ForegroundColor Red;exit 1}"

IF %ERRORLEVEL% NEQ 0 (
    ECHO.
    ECHO [ERROR] Online installation failed
    GOTO :CONFIGURE_EXECUTION_POLICY
)

ECHO.

:CONFIGURE_EXECUTION_POLICY
ECHO [STEP 2/5] Configuring ExecutionPolicy...
ECHO.

REM Configure for CurrentUser
ECHO [INFO] Setting ExecutionPolicy for CurrentUser...
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "try { Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; Write-Host '[OK] CurrentUser: RemoteSigned' -ForegroundColor Green; exit 0 } catch { Write-Host '[ERROR] Failed to set CurrentUser policy' -ForegroundColor Red; exit 1 }"

IF %ERRORLEVEL% NEQ 0 (
    ECHO [WARNING] Could not set ExecutionPolicy for CurrentUser
)

ECHO.
ECHO [INFO] Setting ExecutionPolicy for SYSTEM account...

REM Create temporary script for SYSTEM ExecutionPolicy configuration
SET "TEMP_EXEC_PS1=%TEMP%\Set-SystemExecutionPolicy-%RANDOM%.ps1"
ECHO try { > "%TEMP_EXEC_PS1%"
ECHO     Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force >> "%TEMP_EXEC_PS1%"
ECHO     exit 0 >> "%TEMP_EXEC_PS1%"
ECHO } catch { >> "%TEMP_EXEC_PS1%"
ECHO     exit 1 >> "%TEMP_EXEC_PS1%"
ECHO } >> "%TEMP_EXEC_PS1%"

REM Create temporary scheduled task to run as SYSTEM
SET "TEMP_TASK_NAME=SetExecPolicy-SYSTEM-%RANDOM%"
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -ExecutionPolicy Bypass -File \"%TEMP_EXEC_PS1%\"'; $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(2); $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest; Register-ScheduledTask -TaskName '%TEMP_TASK_NAME%' -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null; Start-ScheduledTask -TaskName '%TEMP_TASK_NAME%'; Start-Sleep -Seconds 5; $info = Get-ScheduledTaskInfo -TaskName '%TEMP_TASK_NAME%'; $result = $info.LastTaskResult; Unregister-ScheduledTask -TaskName '%TEMP_TASK_NAME%' -Confirm:$false; if ($result -eq 0) { Write-Host '[OK] SYSTEM: RemoteSigned' -ForegroundColor Green } else { Write-Host '[WARNING] SYSTEM policy may need manual configuration' -ForegroundColor Yellow }; exit 0"

REM Clean up temporary script
DEL "%TEMP_EXEC_PS1%" 2>nul

ECHO.

:UNBLOCK_SCRIPTS
ECHO [STEP 3/5] Unblocking scripts...
ECHO.

PowerShell -NoProfile -ExecutionPolicy Bypass -Command "$f=Get-ChildItem '%SCRIPT_DIR%' -Filter *.ps1 -EA 0;if($f){$f|ForEach-Object{Unblock-File $_.FullName -EA 0;Write-Host \"[OK] $($_.Name)\" -ForegroundColor Green}}"

ECHO.
ECHO [STEP 4/5] Verifying...
ECHO.

PowerShell -NoProfile -ExecutionPolicy Bypass -Command "try{Import-Module RubrikSecurityCloud;$v=(Get-Module RubrikSecurityCloud).Version;Write-Host '[OK] Module Version:' $v -ForegroundColor Green;exit 0}catch{Write-Host '[ERROR] Module verification failed' -ForegroundColor Red;exit 1}"

ECHO.

REM Verify ExecutionPolicy settings
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "$policies = Get-ExecutionPolicy -List; $current = ($policies | Where-Object { $_.Scope -eq 'CurrentUser' }).ExecutionPolicy; Write-Host '[OK] ExecutionPolicy (CurrentUser):' $current -ForegroundColor Green"

ECHO.
ECHO [STEP 5/5] Complete
ECHO.

:SHOW_NEXT_STEPS
ECHO ============================================================
ECHO   Status
ECHO ============================================================
ECHO.
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "if(Get-Module -ListAvailable RubrikSecurityCloud){$m=Get-Module -ListAvailable RubrikSecurityCloud|Select -First 1;Write-Host '  Module: [OK] Installed' -ForegroundColor Green;Write-Host '  Version:' $m.Version -ForegroundColor Gray}else{Write-Host '  Module: [FAIL] Not installed' -ForegroundColor Red}"
ECHO.
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "$p = (Get-ExecutionPolicy -List | Where-Object { $_.Scope -eq 'CurrentUser' }).ExecutionPolicy; if ($p -eq 'RemoteSigned' -or $p -eq 'Unrestricted') { Write-Host '  ExecutionPolicy: [OK]' $p -ForegroundColor Green } else { Write-Host '  ExecutionPolicy: [WARNING]' $p -ForegroundColor Yellow }"
ECHO.
ECHO ============================================================
ECHO   Next Steps
ECHO ============================================================
ECHO.
ECHO 1. Create Service Account
ECHO    powershell -File .\New-RscServiceAccount.ps1 -ServiceAccountName "FilesetBackup"
ECHO.
ECHO 2. Download JSON credentials and place here
ECHO.
ECHO 3. Schedule task (auto-auth)
ECHO    powershell -File .\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold"
ECHO.
ECHO 4. Test snapshot
ECHO    powershell -File .\New-RscFileSnapshot.ps1 -SlaName "Gold"
ECHO.
ECHO -------------------------------------------------------------
ECHO https://docs.rubrik.com/
ECHO -------------------------------------------------------------
ECHO.

PAUSE
ENDLOCAL
EXIT /B 0

REM ============================================================================
REM EMBEDDED POWERSHELL SCRIPT - Lines starting with #PS1# are extracted
REM ============================================================================
#PS1# param([string]$ModulePath)
#PS1# 
#PS1# $destPath = "$env:ProgramFiles\WindowsPowerShell\Modules\RubrikSecurityCloud\"
#PS1# 
#PS1# Write-Host "[INFO] Source: $ModulePath" -ForegroundColor Cyan
#PS1# Write-Host "[INFO] Dest: $destPath" -ForegroundColor Cyan
#PS1# Write-Host ""
#PS1# 
#PS1# try {
#PS1#     $isZip = $ModulePath -match '\.(zip|nupkg)$'
#PS1#     $tempDir = $null
#PS1#     
#PS1#     if ($isZip) {
#PS1#         Write-Host "[INFO] Extracting archive..." -ForegroundColor Yellow
#PS1#         $tempDir = Join-Path $env:TEMP "RscModule_$(Get-Random)"
#PS1#         New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
#PS1#         Add-Type -AssemblyName System.IO.Compression.FileSystem
#PS1#         [System.IO.Compression.ZipFile]::ExtractToDirectory($ModulePath, $tempDir)
#PS1#         Write-Host "[OK] Archive extracted" -ForegroundColor Green
#PS1#         
#PS1#         # Check if extracted a .nupkg file (NuGet packages are also ZIP files)
#PS1#         $nupkgFile = Get-ChildItem -Path $tempDir -Filter '*.nupkg' -File | Select-Object -First 1
#PS1#         if ($nupkgFile) {
#PS1#             Write-Host "[INFO] Found .nupkg file, extracting again..." -ForegroundColor Yellow
#PS1#             $nupkgDir = Join-Path $tempDir "nupkg_extracted"
#PS1#             New-Item -Path $nupkgDir -ItemType Directory -Force | Out-Null
#PS1#             [System.IO.Compression.ZipFile]::ExtractToDirectory($nupkgFile.FullName, $nupkgDir)
#PS1#             $tempDir = $nupkgDir
#PS1#             Write-Host "[OK] NuGet package extracted" -ForegroundColor Green
#PS1#         }
#PS1#         
#PS1#         # Search for the manifest file recursively
#PS1#         Write-Host "[INFO] Searching for module manifest..." -ForegroundColor Cyan
#PS1#         $manifestFile = Get-ChildItem -Path $tempDir -Recurse -Filter 'RubrikSecurityCloud.psd1' -File -ErrorAction SilentlyContinue | Select-Object -First 1
#PS1#         
#PS1#         if (-not $manifestFile) {
#PS1#             # List what we found for debugging
#PS1#             Write-Host "[DEBUG] Archive contents:" -ForegroundColor Yellow
#PS1#             Get-ChildItem -Path $tempDir -Recurse | Select-Object -First 20 | ForEach-Object { Write-Host "  $($_.FullName.Replace($tempDir, '.'))" -ForegroundColor Gray }
#PS1#             throw 'Module manifest (RubrikSecurityCloud.psd1) not found in archive'
#PS1#         }
#PS1#         
#PS1#         # Use the parent directory of the manifest
#PS1#         $ModulePath = $manifestFile.DirectoryName
#PS1#         Write-Host "[OK] Found manifest at: $($manifestFile.FullName.Replace($tempDir, 'temp'))" -ForegroundColor Green
#PS1#     }
#PS1#     
#PS1#     $manifestPath = Join-Path $ModulePath 'RubrikSecurityCloud.psd1'
#PS1#     if (-not (Test-Path -LiteralPath $manifestPath)) {
#PS1#         throw "Module manifest not found: $manifestPath"
#PS1#     }
#PS1#     
#PS1#     $manifest = Import-PowerShellDataFile -LiteralPath $manifestPath
#PS1#     $version = $manifest.ModuleVersion
#PS1#     Write-Host "[INFO] Version: $version" -ForegroundColor Cyan
#PS1#     Write-Host ""
#PS1#     
#PS1#     if (Test-Path $destPath) {
#PS1#         Write-Host "[INFO] Removing old version..." -ForegroundColor Yellow
#PS1#         Remove-Item $destPath -Recurse -Force
#PS1#     }
#PS1#     
#PS1#     Write-Host "[INFO] Copying module files..." -ForegroundColor Cyan
#PS1#     Copy-Item -LiteralPath $ModulePath -Destination $destPath -Recurse -Force
#PS1#     Write-Host "[OK] Files copied successfully" -ForegroundColor Green
#PS1#     Write-Host ""
#PS1#     
#PS1#     if ($tempDir -and (Test-Path $tempDir)) {
#PS1#         Write-Host "[INFO] Cleaning temporary files..." -ForegroundColor Gray
#PS1#         Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
#PS1#     }
#PS1#     
#PS1#     Write-Host "[TEST] Importing module..." -ForegroundColor Cyan
#PS1#     Import-Module RubrikSecurityCloud -Force
#PS1#     $module = Get-Module RubrikSecurityCloud
#PS1#     
#PS1#     Write-Host ""
#PS1#     Write-Host "[SUCCESS] Installation complete!" -ForegroundColor Green
#PS1#     Write-Host "  Name: $($module.Name)" -ForegroundColor Gray
#PS1#     Write-Host "  Version: $($module.Version)" -ForegroundColor Gray
#PS1#     Write-Host "  Path: $($module.ModuleBase)" -ForegroundColor Gray
#PS1#     
#PS1#     exit 0
#PS1# } catch {
#PS1#     Write-Host ""
#PS1#     Write-Host "[ERROR] Installation failed" -ForegroundColor Red
#PS1#     Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
#PS1#     exit 1
#PS1# }
