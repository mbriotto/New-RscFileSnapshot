# Initialize-RubrikEnvironment.cmd

## Overview

`Initialize-RubrikEnvironment.cmd` is a Windows Batch script that automates the setup of the Rubrik Security Cloud PowerShell environment. It handles module installation, import verification, and prepares your system for automated backup operations.

## Features

- ✅ **Automatic Module Installation**: Downloads and installs the RubrikSecurityCloud PowerShell module if not present
- ✅ **Import Verification**: Checks if the module is imported and imports it automatically if needed
- ✅ **Script Unblocking**: Unblocks all PowerShell scripts in the current directory to prevent execution policy errors
- ✅ **Clear Guidance**: Provides step-by-step instructions for next actions
- ✅ **Error Handling**: Robust error checking with informative messages

## Prerequisites

- Windows operating system (Windows 10/11 or Windows Server 2016+)
- PowerShell 5.1 or later
- **Administrator privileges** (required to install module for all users)
- Internet connection (for initial module download)

**Important**: The module must be installed for ALL USERS (including SYSTEM account) to support scheduled tasks.

## Installation

1. Download `Initialize-RubrikEnvironment.cmd` to your desired directory (e.g., `C:\Scripts\`)
2. No additional setup required - the script is self-contained

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

## What It Does

The script performs three main steps:

### Step 1: Module Management

1. **Checks** if RubrikSecurityCloud PowerShell module is installed
2. **Installs** the module if not present (including NuGet provider if needed)
3. **Verifies** if the module is imported in the current session
4. **Imports** the module if installed but not loaded

### Step 2: Script Unblocking

1. **Scans** the current directory for `.ps1` files
2. **Unblocks** each PowerShell script to prevent execution policy warnings
3. **Reports** which files were processed

### Step 3: Next Steps Guidance

Displays clear instructions for:
- Creating a Service Account
- Downloading credentials
- Running backup scripts
- Setting up scheduled tasks

## Output Example

```
============================================================
  Rubrik Security Cloud - Environment Initialization
============================================================

[STEP 1/3] Checking and installing Rubrik PowerShell Module...

[OK] Rubrik Security Cloud PowerShell Module found
[OK] Module already imported in current session

[STEP 2/3] Unblocking PowerShell scripts in current directory...

[INFO] Found 3 PowerShell script(s)
[OK] Unblocked: New-RscServiceAccount.ps1
[OK] Unblocked: New-RscFileSnapshot.ps1
[OK] Unblocked: New-RscFileSnapshotScheduler.ps1

[STEP 3/3] Configuration completed

============================================================
  Initialization Complete!
============================================================

Next Steps:
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

### 3. Run Backup Snapshots

Execute your first backup:

```powershell
.\New-RscFileSnapshot.ps1 -SlaName 'Gold'
```

### 4. (Optional) Schedule Automatic Backups

Create Windows scheduled tasks for automated backups:

```powershell
.\New-RscFileSnapshotScheduler.ps1 -SlaName 'Gold'
```

## Troubleshooting

### Module Installation Fails

**Symptom**: Error message during module installation

**Solutions**:
- Check your internet connection
- Run the script as Administrator
- Verify that PowerShell Gallery is accessible: `Test-NetConnection powershellgallery.com -Port 443`
- Manually install NuGet: `Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force`

### Permission Errors

**Symptom**: "Access denied" or permission-related errors

**Solutions**:
- Right-click the script and select "Run as Administrator"
- Check if your organization's security policies block module installation
- Try installing to user scope (already configured in the script)

### Execution Policy Warnings

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

### Script Flow

```
START
  │
  ├─► Check Admin Privileges (Warning only)
  │
  ├─► STEP 1: Module Check
  │   ├─► Is module installed?
  │   │   ├─ YES ─► Is module imported?
  │   │   │        ├─ YES ─► Continue to Step 2
  │   │   │        └─ NO  ─► Import module ─► Continue to Step 2
  │   │   │
  │   │   └─ NO  ─► Install module ─► Import module ─► Continue to Step 2
  │
  ├─► STEP 2: Unblock Scripts
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

Recommended directory structure after setup:

```
C:\Scripts\
├── Initialize-RubrikEnvironment.cmd     (this script)
├── New-RscServiceAccount.ps1            (create service account)
├── New-RscFileSnapshot.ps1              (run backups)
├── New-RscFileSnapshotScheduler.ps1     (schedule backups)
└── service-account-credentials.json     (downloaded credentials)
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

### How do I verify the module is available for SYSTEM?

Use the `Check-RscServiceAccountStatus.ps1` script to verify module availability for different accounts.

## Version History

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
