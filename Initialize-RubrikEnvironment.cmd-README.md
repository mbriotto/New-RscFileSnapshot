# Initialize-RubrikEnvironment.cmd

## Overview

`Initialize-RubrikEnvironment.cmd` is a Windows Batch script that automates the setup of the Rubrik Security Cloud PowerShell environment. It handles module installation (online or offline), import verification, and prepares your system for automated backup operations.

**NEW in v1.6.0**: Automatic PowerShell ExecutionPolicy configuration for both CurrentUser and SYSTEM accounts!

## Features

- ✅ **Automatic Module Installation**: Downloads and installs the RubrikSecurityCloud PowerShell module if not present
- ✅ **ExecutionPolicy Auto-Configuration**: Configures PowerShell ExecutionPolicy for CurrentUser and SYSTEM accounts (NEW in v1.6.0)
- ✅ **Offline Installation Support**: Automatically detects and installs from local module packages
- ✅ **NuGet Package Support**: Handles .nupkg files and nested archives
- ✅ **Smart Installation Selection**: Choose between online or offline installation when both are available
- ✅ **Embedded PowerShell Script**: Self-contained script with embedded installation logic
- ✅ **Import Verification**: Checks if the module is imported and imports it automatically if needed
- ✅ **Script Unblocking**: Unblocks all PowerShell scripts in the current directory to prevent execution policy errors
- ✅ **Network Troubleshooting**: Enhanced error handling for connectivity issues
- ✅ **Debug Output**: Shows archive contents if installation fails for troubleshooting
- ✅ **Clear Guidance**: Provides step-by-step instructions for next actions
- ✅ **Error Handling**: Robust error checking with informative messages

## Prerequisites

- Windows operating system (Windows 10/11 or Windows Server 2016+)
- PowerShell 5.1 or later
- **Administrator privileges** (required to install module for all users)
- Internet connection (for online module download) OR offline module package

**Important**: The module must be installed for ALL USERS (including SYSTEM account) to support scheduled tasks.

## Installation

1. Download `Initialize-RubrikEnvironment.cmd` to your desired directory (e.g., `C:\Scripts\`)
2. No additional setup required - the script is self-contained

### Optional: Prepare Offline Installation

If you don't have internet access or are behind a restrictive firewall, you can prepare an offline installation package:

**Method 1: Save from PowerShell Gallery (Recommended)**

On a computer with internet access:
```powershell
# Run PowerShell as Administrator
Save-Module -Name RubrikSecurityCloud -Path C:\Temp
# This creates: C:\Temp\RubrikSecurityCloud\
```

**Method 2: Download NuGet Package**

Alternatively, download the .nupkg file directly:
1. Visit: https://www.powershellgallery.com/packages/RubrikSecurityCloud/
2. Click "Manual Download" 
3. Download the `.nupkg` file

**Transfer to your target computer:**
- Copy the `RubrikSecurityCloud` folder to your scripts directory
- OR place the `.nupkg` file in your scripts directory
- OR create/use a ZIP file: `RubrikSecurityCloud.zip` or `*.nupkg.zip`

**Supported offline package formats:**
- ✅ Folder: `RubrikSecurityCloud\` (with `.psd1` manifest)
- ✅ ZIP file: `RubrikSecurityCloud.zip`
- ✅ NuGet package: `rubriksecuritycloud.*.nupkg`
- ✅ Nested archives: `rubriksecuritycloud.*.nupkg.zip`
- ✅ Any ZIP with "rubrik" in filename (case-insensitive)

The script will automatically detect the offline package and offer to use it!

## Usage

### Basic Execution

**Run as Administrator** - Right-click the script and select "Run as Administrator":

```cmd
REM Right-click → Run as Administrator
Initialize-RubrikEnvironment.cmd
```

Or from an elevated Command Prompt:

```cmd
.\Initialize-RubrikEnvironment.cmd
```

### From PowerShell

```powershell
.\Initialize-RubrikEnvironment.cmd
```

### From Command Prompt

```cmd
cd C:\Scripts
Initialize-RubrikEnvironment.cmd
```

### Usage Scenarios

#### Scenario 1: Online Installation (Default)
```cmd
REM Simply run the script - it will download from PowerShell Gallery
Initialize-RubrikEnvironment.cmd
```

#### Scenario 2: Offline Installation - Folder
```cmd
REM Place offline package in the same directory
C:\Scripts\
├── Initialize-RubrikEnvironment.cmd
└── RubrikSecurityCloud\          ← Offline module folder

REM Run the script - it will detect and offer offline installation
Initialize-RubrikEnvironment.cmd

REM Choose option [1] when prompted
```

#### Scenario 3: Offline Installation - ZIP File
```cmd
REM Place ZIP file in the same directory
C:\Scripts\
├── Initialize-RubrikEnvironment.cmd
└── RubrikSecurityCloud.zip       ← Offline module ZIP

REM Run the script - it will extract and install
Initialize-RubrikEnvironment.cmd
```

#### Scenario 4: Offline Installation - NuGet Package (NEW)
```cmd
REM Place .nupkg file (downloaded from PowerShell Gallery)
C:\Scripts\
├── Initialize-RubrikEnvironment.cmd
└── rubriksecuritycloud.1.14.20260105.nupkg.zip  ← NuGet package

REM Run the script - it will handle nested extraction
Initialize-RubrikEnvironment.cmd

REM The script automatically:
REM - Extracts the .nupkg.zip
REM - Extracts the inner .nupkg (which is also a ZIP)
REM - Finds the module manifest
REM - Installs the module
```

## What It Does

The script performs five main steps:

### Step 1: Module Check and Installation

1. **Checks** if RubrikSecurityCloud PowerShell module is already installed
2. If not installed:
   - **Searches** for offline module packages in current directory
   - **Detects** folders named `RubrikSecurityCloud` with `.psd1` manifest
   - **Detects** ZIP files: `RubrikSecurityCloud.zip` or `*Rubrik*.zip`
3. If offline package found:
   - **Presents** installation options:
     - [1] Install from OFFLINE package (fast, no internet)
     - [2] Download from PowerShell Gallery (online)
     - [3] Cancel installation
4. If no offline package or user selects online:
   - **Installs** NuGet provider if needed
   - **Downloads** module from PowerShell Gallery
   - **Installs** for ALL USERS (including SYSTEM)
5. **Verifies** module installation and imports it

### Step 2: PowerShell ExecutionPolicy Configuration (NEW in v1.6.0)

1. **Configures** ExecutionPolicy to `Bypass` for CurrentUser account
2. **Configures** ExecutionPolicy to `Bypass` for SYSTEM account (via scheduled task)
3. **Verifies** configuration for both accounts
4. **Ensures** automated backup scripts can run without manual intervention

This critical step enables:
- ✅ Scheduled tasks to execute PowerShell scripts automatically
- ✅ Scripts to run under SYSTEM account without ExecutionPolicy errors
- ✅ Seamless automation of Rubrik backup operations

### Step 3: Script Unblocking

1. **Scans** the current directory for `.ps1` files
2. **Unblocks** each PowerShell script to prevent execution policy warnings
3. **Reports** which files were processed

### Step 4: Module Verification

1. **Tests** module import functionality
2. **Displays** installed module version
3. **Confirms** availability for SYSTEM account

### Step 5: Next Steps Guidance

Displays clear instructions for:
- Creating a Service Account
- Downloading credentials
- Running backup scripts with automatic SYSTEM authentication
- Setting up scheduled tasks

## Output Example

### Example 1: Offline Package Detected

```
============================================================
  Rubrik Security Cloud - Environment Initialization
============================================================

[STEP 1/5] Checking Rubrik PowerShell Module...

[INFO] Module not found. Checking installation options...

[FOUND] Offline module detected: .\RubrikSecurityCloud\

============================================================
  Installation Method Selection
============================================================

An offline module package has been detected in this folder.

Choose installation method:
  [1] Install from OFFLINE package (faster, no internet needed)
  [2] Download from PowerShell Gallery (requires internet)
  [3] Cancel installation

Your choice [1/2/3]: 1

============================================================
  Installing from Offline Package
============================================================

[INFO] Source: C:\Scripts\RubrikSecurityCloud
[INFO] Destination: C:\Program Files\WindowsPowerShell\Modules\RubrikSecurityCloud
[INFO] Module version: 1.2.3
[INFO] Copying module files...
[OK] Module files copied successfully

[TEST] Testing module import...

[SUCCESS] Module installed and imported successfully!
  Name: RubrikSecurityCloud
  Version: 1.2.3
  Path: C:\Program Files\WindowsPowerShell\Modules\RubrikSecurityCloud
[INFO] Module available for SYSTEM account (scheduled tasks)

[STEP 2/5] Configuring PowerShell ExecutionPolicy...

[INFO] Setting ExecutionPolicy for CurrentUser...
[OK] CurrentUser: Bypass
[INFO] Setting ExecutionPolicy for SYSTEM account...
[OK] SYSTEM account: Bypass
[SUCCESS] ExecutionPolicy configured for automated tasks

[STEP 3/5] Unblocking PowerShell scripts in current directory...

[INFO] Found 3 PowerShell script(s)
[OK] Unblocked: New-RscServiceAccount.ps1
[OK] Unblocked: New-RscFileSnapshot.ps1
[OK] Unblocked: New-RscFileSnapshotScheduler.ps1

[STEP 4/5] Verifying module installation...

[OK] Module verified - Version: 1.2.3

[STEP 5/5] Configuration completed

============================================================
  Setup Status
============================================================

Module Installation:
  [OK] Installed
  Version: 1.2.3

============================================================
  Next Steps
============================================================
...
```

### Example 2: Online Installation (No Offline Package)

```
============================================================
  Rubrik Security Cloud - Environment Initialization
============================================================

[STEP 1/4] Checking Rubrik PowerShell Module...

[INFO] Module not found. Checking installation options...
[INFO] No offline module detected in current directory
[INFO] Will attempt online installation from PowerShell Gallery

============================================================
  Installing from PowerShell Gallery
============================================================

[CHECK] Testing internet connectivity...
[OK] Internet connection available

[SETUP] Configuring package sources...
[INFO] Setting PowerShell Gallery as trusted source...
[DOWNLOAD] Downloading and installing NuGet provider...
[OK] NuGet provider installed

[DOWNLOAD] Downloading RubrikSecurityCloud module...
[INFO] Module size is approximately 50-100 MB
[INFO] This may take several minutes depending on connection speed...

[SUCCESS] Module installed successfully for ALL USERS!
[OK] Module imported - Version: 1.2.3
[INFO] Module available for SYSTEM account (scheduled tasks)

[STEP 2/4] Unblocking PowerShell scripts...
...
```

### Example 3: Module Already Installed

```
============================================================
  Rubrik Security Cloud - Environment Initialization
============================================================

[STEP 1/5] Checking Rubrik PowerShell Module...

[OK] Rubrik Security Cloud PowerShell Module is already installed
  Version: 1.2.3
  Path: C:\Program Files\WindowsPowerShell\Modules\RubrikSecurityCloud

[STEP 2/5] Configuring PowerShell ExecutionPolicy...

[INFO] Checking ExecutionPolicy for CurrentUser...
[OK] CurrentUser: Already set to Bypass
[INFO] Checking ExecutionPolicy for SYSTEM account...
[OK] SYSTEM account: Already set to Bypass
[SUCCESS] ExecutionPolicy already configured

[STEP 3/5] Unblocking PowerShell scripts in current directory...
...
```

## Next Steps After Initialization

After running the initialization script successfully, follow these steps:

### 1. Create a Service Account

Create a service account in Rubrik Security Cloud for authentication:

```powershell
.\New-RscServiceAccount.ps1 -ServiceAccountName 'FilesetBackup'
```

### 2. Download Service Account Credentials

1. Log in to your Rubrik Security Cloud console
2. Navigate to **Settings** > **Users** > **Service Accounts**
3. Locate your newly created service account
4. Download the JSON credentials file
5. Place the JSON file in the same directory as your scripts

### 3. Create Automated Scheduled Tasks (Recommended - NEW)

**NEW in v1.1**: The scheduler now automatically configures SYSTEM account authentication!

```powershell
# The scheduler will automatically:
# - Detect the JSON file in current directory
# - Configure SYSTEM account authentication
# - Create the scheduled task
# - Verify authentication works

.\New-RscFileSnapshotScheduler.ps1 -SlaName 'Gold'

# OR specify JSON path explicitly
.\New-RscFileSnapshotScheduler.ps1 -SlaName 'Gold' -ServiceAccountJsonPath ".\service-account-XXX.json"
```

**What happens automatically:**
- ✅ Script verifies SYSTEM account authentication
- ✅ Configures authentication if needed using provided JSON
- ✅ Creates scheduled task with verified credentials
- ✅ Task executes immediately without manual configuration

### 4. (Optional) Test Manual Snapshot

Execute a manual backup to verify configuration:

```powershell
.\New-RscFileSnapshot.ps1 -SlaName 'Gold'
```

## Troubleshooting

### Online Installation Fails

**Symptom**: Error message during online module installation

**Common Errors:**
```
[ERROR] Cannot download NuGet provider
[ERROR] Cannot reach PowerShell Gallery
[ERROR] The NuGet provider is required
```

**Solutions:**

1. **Try offline installation** (Recommended):
   ```powershell
   # On a computer with internet, download the module
   Save-Module -Name RubrikSecurityCloud -Path C:\Temp
   
   # Copy C:\Temp\RubrikSecurityCloud to your scripts directory
   # Re-run Initialize-RubrikEnvironment.cmd
   ```

2. **Enable TLS 1.2** (if online installation needed):
   ```powershell
   [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
   Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
   Install-Module -Name RubrikSecurityCloud -Scope AllUsers -Force
   ```

3. **Configure proxy** (if behind corporate firewall):
   ```powershell
   [System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
   ```

4. **Verify connectivity**:
   ```powershell
   Test-NetConnection powershellgallery.com -Port 443
   ```

### Offline Installation Issues

**Symptom**: "Module manifest not found in archive"

**This happens with .nupkg files** - The script now handles this automatically (v1.5.0+):
- Automatically detects nested .nupkg files inside ZIP archives
- Extracts them recursively
- Shows debug output if manifest still not found

**Solutions:**

1. **Check the debug output**: The script shows the first 20 files in the archive
   ```
   [DEBUG] Archive contents:
     .\rubriksecuritycloud.1.14.nupkg
     .\[Content-Types].xml
   ```

2. **Verify it's a valid module package**:
   ```powershell
   # Extract manually and check structure
   Expand-Archive .\rubriksecuritycloud.*.nupkg.zip -DestinationPath .\test
   Get-ChildItem .\test -Recurse -Filter "*.psd1"
   ```

3. **Use Save-Module instead** (most reliable):
   ```powershell
   # On PC with internet
   Save-Module -Name RubrikSecurityCloud -Path C:\Temp
   # Copy folder to target PC
   ```

**Symptom**: Offline package not detected by script

**Solutions:**
1. Ensure package is in the same directory as the `.cmd` file
2. **Supported filenames:**
   - Exact: `RubrikSecurityCloud` (folder)
   - Exact: `RubrikSecurityCloud.zip`
   - Pattern: Any file with "rubrik" in name (case-insensitive)
   - Examples: `rubriksecuritycloud.1.14.nupkg.zip` ✅
3. Check that folder contains `.psd1` manifest:
   ```powershell
   Test-Path .\RubrikSecurityCloud\RubrikSecurityCloud.psd1
   ```

**Symptom**: "Cannot find RubrikSecurityCloud.psd1"

**The script searches recursively** - it will find the manifest in any subfolder.

**Solutions:**
1. Verify the archive actually contains the module:
   ```powershell
   # Manual extraction
   Expand-Archive file.zip -DestinationPath test
   Get-ChildItem test -Recurse -Filter "RubrikSecurityCloud.psd1"
   ```

2. If downloading from PowerShell Gallery manually:
   - Use the "Manual Download" button
   - Download the `.nupkg` file
   - The script handles .nupkg extraction automatically

### Permission Errors

**Symptom**: "Access denied" or permission-related errors

**Solutions**:
- Right-click the script and select "Run as Administrator"
- Check if your organization's security policies block module installation
- Verify write permissions to `C:\Program Files\WindowsPowerShell\Modules\`

### Execution Policy Warnings

**Symptom**: Scripts won't run due to execution policy

**Solutions**:
- The script uses `-ExecutionPolicy Bypass` which should handle this automatically
- If issues persist, temporarily set the policy: `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`

**Symptom**: Scripts won't run due to execution policy

**Solutions**:
- The script uses `-ExecutionPolicy Bypass` which should handle this automatically
- If issues persist, temporarily set the policy: `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`

### Module Not Found After Installation

**Symptom**: Script says module is not found even after installation

**Solutions**:
- Close and reopen your PowerShell/Command Prompt window
- Manually verify installation: `Get-Module -ListAvailable -Name RubrikSecurityCloud`
- Check module path: `$env:PSModulePath`

## Technical Details

### Script Flow (v1.3)

```
START
  │
  ├─► Check Admin Privileges (Required)
  │
  ├─► STEP 1: Module Check and Installation
  │   │
  │   ├─► Is module already installed?
  │   │   ├─ YES ─► Skip to Step 2
  │   │   │
  │   │   └─ NO  ─► Search for offline package
  │   │           │
  │   │           ├─► Offline package found?
  │   │           │   │
  │   │           │   ├─ YES ─► Present options:
  │   │           │   │         [1] Install from OFFLINE
  │   │           │   │         [2] Download ONLINE
  │   │           │   │         [3] Cancel
  │   │           │   │         │
  │   │           │   │         ├─ User selects [1] ─► Install from offline
  │   │           │   │         ├─ User selects [2] ─► Install online
  │   │           │   │         └─ User selects [3] ─► Exit
  │   │           │   │
  │   │           │   └─ NO  ─► Install online (automatic)
  │   │           │
  │   │           ├─► OFFLINE Installation:
  │   │           │   ├─ Extract ZIP if needed
  │   │           │   ├─ Verify .psd1 manifest
  │   │           │   ├─ Copy to Program Files
  │   │           │   ├─ Test import
  │   │           │   └─ Success ─► Continue to Step 2
  │   │           │       Failed ─► Offer online installation
  │   │           │
  │   │           └─► ONLINE Installation:
  │   │               ├─ Enable TLS 1.2
  │   │               ├─ Test connectivity
  │   │               ├─ Register PSGallery
  │   │               ├─ Install NuGet provider
  │   │               ├─ Download module
  │   │               ├─ Install for AllUsers
  │   │               └─ Import module
  │
  ├─► STEP 2: Unblock Scripts
  │   ├─► Find all .ps1 files
  │   ├─► Unblock each file
  │   └─► Report results
  │
  ├─► STEP 3: Verify Module
  │   ├─► Test import
  │   ├─► Display version
  │   └─► Confirm SYSTEM availability
  │
  ├─► STEP 4: Display Next Steps
  │   ├─► Module status
  │   ├─► Service Account creation
  │   ├─► Scheduler usage (with auto-auth)
  │   └─► Manual backup option
  │
END
```

### Offline Package Detection Logic

The script searches for offline packages in this order:

1. **Folder with manifest**: `.\RubrikSecurityCloud\RubrikSecurityCloud.psd1`
2. **Exact ZIP name**: `.\RubrikSecurityCloud.zip`
3. **Pattern match**: `.\*Rubrik*.zip` (any ZIP with "Rubrik" in name)

### Installation Method Priority

```
Module Already Installed?
  YES → Skip installation
  NO  → Continue

Offline Package Detected?
  YES → Offer user choice:
        - Offline (recommended for speed/reliability)
        - Online (if fresh download preferred)
        - Cancel
  NO  → Automatic online installation
```
  │   ├─► Find all .ps1 files
  │   ├─► Unblock each file
  │   └─► Report results
  │
  ├─► STEP 3: Display Next Steps
  │
END
```

### Exit Codes

- `0` - Success, all operations completed
- `1` - Module installation failed
- `2` - Module import failed

### Environment Variables

The script uses the following variables:

- `SCRIPT_DIR` - Directory where the script is located (automatically detected)
- `MODULE_STATUS` - Tracks module installation/import status
- `ERRORLEVEL` - Standard Windows error level for command execution

## Security Considerations

- The script uses `-ExecutionPolicy Bypass` only for its own operations
- **NEW v1.6.0**: Automatically configures ExecutionPolicy to `Bypass` for:
  - CurrentUser account (enables manual script execution)
  - SYSTEM account (enables automated scheduled task execution)
- ExecutionPolicy `Bypass` is required for enterprise automation but maintain other security controls:
  - File Integrity Monitoring (FIM) for script changes
  - Access Control Lists (ACL) on script directories
  - Audit logging for script execution
- Module installation is scoped to `AllUsers` (required for SYSTEM account access in scheduled tasks)
- Administrator privileges are required for AllUsers installation
- No credentials are stored or transmitted by this script
- All PowerShell operations are explicitly defined (no arbitrary code execution)

## Dependencies

### Required PowerShell Modules

- **RubrikSecurityCloud** - Automatically installed by this script

### Required PowerShell Providers

- **NuGet** - Automatically installed if missing

## File Structure

### Recommended Directory Structure After Setup

#### Option 1: Online Installation Only
```
C:\Scripts\Rsc-Backup\
├── Initialize-RubrikEnvironment.cmd     (this script)
├── New-RscServiceAccount.ps1            (create service account)
├── New-RscFileSnapshot.ps1              (run backups)
├── New-RscFileSnapshotScheduler.ps1     (schedule backups - with auto-auth)
└── service-account-credentials.json     (downloaded credentials)
```

#### Option 2: With Offline Module Package (Folder)
```
C:\Scripts\Rsc-Backup\
├── Initialize-RubrikEnvironment.cmd
├── New-RscServiceAccount.ps1
├── New-RscFileSnapshot.ps1
├── New-RscFileSnapshotScheduler.ps1
├── service-account-credentials.json
└── RubrikSecurityCloud\                 ← Offline module folder
    ├── RubrikSecurityCloud.psd1         (manifest)
    ├── RubrikSecurityCloud.psm1         (module)
    └── ... (other module files)
```

#### Option 3: With Offline Module Package (ZIP)
```
C:\Scripts\Rsc-Backup\
├── Initialize-RubrikEnvironment.cmd
├── New-RscServiceAccount.ps1
├── New-RscFileSnapshot.ps1
├── New-RscFileSnapshotScheduler.ps1
├── service-account-credentials.json
└── RubrikSecurityCloud.zip              ← Offline module ZIP
```

### After Installation

Once the module is installed (either online or offline), the directory structure simplifies:

```
C:\Scripts\Rsc-Backup\
├── Initialize-RubrikEnvironment.cmd
├── New-RscServiceAccount.ps1
├── New-RscFileSnapshot.ps1
├── New-RscFileSnapshotScheduler.ps1
└── service-account-credentials.json

# Module installed here (accessible to all users including SYSTEM):
C:\Program Files\WindowsPowerShell\Modules\
└── RubrikSecurityCloud\
    └── ... (module files)
```

## Frequently Asked Questions (FAQ)

### Why do I need to run as Administrator?

The module must be installed with `-Scope AllUsers` to make it available to:
- Your user account
- **SYSTEM account** (used by scheduled tasks)
- Other users on the system

Without AllUsers scope, scheduled tasks will fail because SYSTEM cannot access user-specific modules.

### Can I install for CurrentUser instead?

**Not recommended** if you plan to use scheduled tasks. Manual snapshots will work, but automated tasks running as SYSTEM will fail with "module not found" errors.

### What if I already installed for CurrentUser?

You need to reinstall for AllUsers:

```powershell
# Run PowerShell as Administrator
Uninstall-Module RubrikSecurityCloud -Force
Install-Module RubrikSecurityCloud -Scope AllUsers -Force
```

### When should I use offline installation?

Use offline installation when:
- ❌ **No internet connection** available
- ❌ **Corporate firewall** blocks PowerShell Gallery
- ❌ **Proxy issues** prevent downloads
- ❌ **Network restrictions** in secure environments
- ✅ **Faster installation** preferred (no download time)
- ✅ **Consistent version** needed across multiple machines

### How do I prepare an offline package?

**Method 1: Save-Module (Recommended)**

On a computer with internet:
```powershell
# Run PowerShell as Administrator
Save-Module -Name RubrikSecurityCloud -Path C:\Temp
```

**Method 2: Download .nupkg from PowerShell Gallery**

1. Visit: https://www.powershellgallery.com/packages/RubrikSecurityCloud/
2. Click "Manual Download"
3. Download the `.nupkg` file (e.g., `rubriksecuritycloud.1.14.nupkg`)

**Transfer to target computer:**
- Copy the `RubrikSecurityCloud` folder to scripts directory
- OR place the `.nupkg` file directly  
- OR ZIP the folder/file: `RubrikSecurityCloud.zip`
- Script will automatically detect and offer installation

**Supported formats:**
- Folder: `RubrikSecurityCloud\`
- ZIP: `RubrikSecurityCloud.zip` or `*rubrik*.zip`
- NuGet: `*.nupkg` or `*.nupkg.zip`

### Can I use both online and offline methods?

Yes! The script detects offline packages and lets you choose:
- Option [1]: Install from offline package (fast)
- Option [2]: Download from PowerShell Gallery (fresh)
- Option [3]: Cancel installation

### What if offline installation fails?

The script will automatically offer to try online installation as a fallback. If both fail, you can manually install using the standalone `Install-RscModule-Offline.ps1` script.

### How do I verify the module is available for SYSTEM?

After installation, the script automatically verifies SYSTEM can access the module. You can also check manually:

```powershell
# Check installation scope
Get-Module -ListAvailable -Name RubrikSecurityCloud | Select-Object Name, Path

# Path should show:
# C:\Program Files\WindowsPowerShell\Modules\RubrikSecurityCloud
# NOT: C:\Users\...\Documents\WindowsPowerShell\Modules\...
```

### What's new in the scheduler (v1.1)?

The `New-RscFileSnapshotScheduler.ps1` now **automatically configures SYSTEM account authentication**:
- Detects if SYSTEM is authenticated
- Configures credentials using provided JSON
- Verifies authentication before creating task
- No manual PsExec configuration needed!

### Why does the script configure ExecutionPolicy to Bypass? (NEW in v1.6.0)

ExecutionPolicy `Bypass` is essential for enterprise automation:

**Why it's needed:**
- ✅ Allows scheduled tasks to run PowerShell scripts automatically
- ✅ Prevents "cannot be loaded because running scripts is disabled" errors
- ✅ Enables SYSTEM account to execute scripts without user interaction
- ✅ Required for unattended backup automation

**Security considerations:**
- The script only configures ExecutionPolicy for PowerShell scripts
- This does NOT disable Windows security features (Windows Defender, SmartScreen, etc.)
- Maintain other security controls:
  - File Integrity Monitoring on script directories
  - Access Control Lists restricting who can modify scripts
  - Audit logging for script execution
  - Code signing for production environments (optional)

**Alternative approaches if you prefer not to use Bypass:**
1. Use `RemoteSigned` + sign your scripts with a code signing certificate
2. Use Group Policy to configure ExecutionPolicy centrally
3. Use scheduled tasks with `-ExecutionPolicy Bypass` argument per task

### Can I verify the ExecutionPolicy configuration?

Yes! After running the initialization script, you can check:

```powershell
# Check CurrentUser ExecutionPolicy
Get-ExecutionPolicy -Scope CurrentUser

# Check SYSTEM ExecutionPolicy (requires PsExec or scheduled task)
# The initialization script does this automatically for you
```

## Version History

### Version 1.6.0 (February 2026) - Current
- ✨ **NEW**: Automatic PowerShell ExecutionPolicy configuration
- ✨ **NEW**: Configures ExecutionPolicy for CurrentUser account
- ✨ **NEW**: Configures ExecutionPolicy for SYSTEM account via scheduled task
- ✨ **NEW**: Verifies ExecutionPolicy settings for both accounts
- 🎯 **IMPACT**: Enables seamless automated task execution without manual intervention
- 🎯 **IMPACT**: Eliminates ExecutionPolicy errors in scheduled tasks
- 🎯 **IMPACT**: Critical for enterprise automation scenarios
- 📝 Updated step count from 4 to 5 steps

### Version 1.5.0 (February 2026)
- ✨ **NEW**: NuGet package (.nupkg) support with automatic extraction
- ✨ **NEW**: Nested archive handling (e.g., .nupkg.zip containing .nupkg)
- ✨ **NEW**: Embedded PowerShell script using findstr extraction
- ✨ **NEW**: Debug output showing archive contents on failure
- ✨ **NEW**: Recursive manifest search in all subfolders
- 🔧 Improved file detection using direct file search vs folder search
- 🔧 Enhanced error messages with specific failure details
- 🔧 Better handling of complex archive structures
- 📝 Complete rewrite of offline installation logic for reliability

### Version 1.4.0-1.4.1
- 🔧 Attempts to fix PowerShell script generation issues
- 🔧 Various approaches to handle special characters in paths
- ⚠️ Deprecated - superseded by v1.5.0

### Version 1.3 (February 2026)
- ✨ **NEW**: Integrated offline installation support
- ✨ **NEW**: Automatic offline package detection
- ✨ **NEW**: Interactive installation method selection
- ✨ **NEW**: Support for ZIP file extraction
- 🔧 Enhanced error handling for network issues
- 🔧 TLS 1.2 enablement for secure downloads
- 🔧 Improved troubleshooting guidance
- 📝 Updated documentation with offline scenarios

### Version 1.2
- Enhanced network troubleshooting
- Added connectivity tests
- Improved error messages

### Version 1.1
- Added NuGet provider auto-installation
- Improved module import verification

### Version 1.0
- Initial release
- Module installation and import verification
- Script unblocking functionality
- Next steps guidance

## Support

For issues and questions:

- **Rubrik Security Cloud Documentation**: https://docs.rubrik.com/
- **PowerShell Module Repository**: https://www.powershellgallery.com/packages/RubrikSecurityCloud
- **Rubrik Support Portal**: https://support.rubrik.com/

## License

This script is provided as-is for use with Rubrik Security Cloud. Please refer to your Rubrik license agreement for terms of use.

## Contributing

Contributions, issues, and feature requests are welcome. Please ensure any modifications maintain backward compatibility and follow Windows Batch scripting best practices.

## Author

Created for Rubrik Security Cloud automation and environment setup.

---

**Last Updated**: January 2026
