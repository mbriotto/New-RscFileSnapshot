# New-RscServiceAccount.ps1

PowerShell script for creating Service Accounts in Rubrik Security Cloud with minimum required permissions for Fileset snapshots.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)

## Overview

`New-RscServiceAccount.ps1` is a guided automation tool that helps you create Service Accounts in Rubrik Security Cloud (RSC) with the exact permissions needed to run the `New-RscFileSnapshot.ps1` script. 

Due to current limitations in the Rubrik PowerShell SDK, this script provides an interactive guided process that walks you through the manual steps in the RSC web interface while automating validation and documentation.

---

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Parameters](#parameters)
- [Permissions Granted](#permissions-granted)
- [Examples](#examples)
- [Step-by-Step Guide](#step-by-step-guide)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)
- [Support](#support)

---

## Features

✅ **Guided Process**: Interactive step-by-step instructions for RSC UI  
✅ **Minimum Permissions**: Creates role with only required permissions  
✅ **Automatic Validation**: Checks for JSON credentials file after download  
✅ **Browser Integration**: Optional automatic opening of RSC web interface  
✅ **Output Management**: Validates and creates output directories  
✅ **Colored Output**: Clear, color-coded console messages  
✅ **Comprehensive Help**: Built-in documentation and examples  
✅ **Safe Defaults**: Sensible default values for all optional parameters  

---

## Prerequisites

### 1. Rubrik PowerShell SDK

```powershell
Install-Module -Name RubrikSecurityCloud -Scope CurrentUser
```

Verify installation:
```powershell
Get-Module -ListAvailable RubrikSecurityCloud
```

### 2. Rubrik Security Cloud Access

- Administrator access to Rubrik Security Cloud
- Permissions to create Service Accounts and Roles
- Access to https://rubrik.my.rubrik.com (or your organization's RSC URL)

### 3. PowerShell Version

- PowerShell 5.1 or higher
- Windows PowerShell or PowerShell Core

---

## Installation

### Option 1: Clone Repository

```powershell
git clone https://github.com/mbriotto/New-RscFileSnapshot.git
cd New-RscFileSnapshot
```

### Option 2: Direct Download

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/mbriotto/New-RscFileSnapshot/main/New-RscServiceAccount.ps1" -OutFile "New-RscServiceAccount.ps1"
```

---

## Usage

### Basic Syntax

```powershell
.\New-RscServiceAccount.ps1 -ServiceAccountName <Name> [OPTIONS]
```

### Quick Start

```powershell
# Simplest usage with defaults
.\New-RscServiceAccount.ps1 -ServiceAccountName "FilesetBackupAutomation"
```

The script will:
1. Connect to Rubrik Security Cloud
2. Guide you through creating a custom role
3. Guide you through creating the Service Account
4. Verify the JSON credentials file is downloaded
5. Provide next steps

---

## Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `-ServiceAccountName` | **Yes** | - | Name of the Service Account to create |
| `-ServiceAccountDescription` | No | "Service account for automated Fileset snapshots" | Description of the Service Account |
| `-RoleName` | No | "Fileset Snapshot Operator" | Name of the custom role to create |
| `-OutputPath` | No | Current directory | Path where JSON credentials will be saved |
| `-Credential` | No | - | PSCredential for RSC authentication |
| `-Help` / `-?` | No | - | Display help and exit |

---

## Permissions Granted

The script creates a custom role with the **minimum permissions** required for Fileset snapshots:

### Object-Level Permissions

| Object Type | Operations | Purpose |
|-------------|------------|---------|
| **Fileset** | `VIEW_FILESET`<br>`BACKUP_FILESET` | Read Fileset configuration<br>Trigger on-demand backups |
| **SLA Domain** | `VIEW_SLA` | Read SLA policies |
| **Host** | `VIEW_HOST` | Read host information |
| **Cluster** | `VIEW_CLUSTER` | Read cluster configuration |

### Why These Permissions?

- **Fileset Read**: Required to identify and select the correct Fileset
- **Fileset Backup**: Required to trigger on-demand snapshots
- **SLA Read**: Required to apply SLA policies to snapshots
- **Host Read**: Required to identify the host and extract cluster information
- **Cluster Read**: Required to verify connectivity and cluster details

---

## Examples

### Example 1: Basic Creation

```powershell
.\New-RscServiceAccount.ps1 -ServiceAccountName "FilesetBackupAutomation"
```

Creates Service Account with:
- Name: `FilesetBackupAutomation`
- Role: `Fileset Snapshot Operator` (default)
- Output: Current directory

### Example 2: Custom Output Path

```powershell
.\New-RscServiceAccount.ps1 -ServiceAccountName "BackupService" -OutputPath "C:\Credentials\Rubrik"
```

Saves JSON credentials to `C:\Credentials\Rubrik`

### Example 3: Custom Role Name

```powershell
.\New-RscServiceAccount.ps1 `
    -ServiceAccountName "SnapshotAutomation" `
    -RoleName "Custom Fileset Operator" `
    -ServiceAccountDescription "Automated snapshot service for production filesets"
```

### Example 4: With Credentials

```powershell
$cred = Get-Credential
.\New-RscServiceAccount.ps1 `
    -ServiceAccountName "ProdBackupService" `
    -Credential $cred `
    -OutputPath "C:\SecureCredentials"
```

### Example 5: Display Help

```powershell
.\New-RscServiceAccount.ps1 -Help
```

---

## Step-by-Step Guide

### Complete Walkthrough

#### Step 1: Run the Script

```powershell
.\New-RscServiceAccount.ps1 -ServiceAccountName "FilesetBackupAutomation"
```

#### Step 2: Connect to RSC

The script will connect to Rubrik Security Cloud:
- If no credentials provided: Opens browser for interactive login
- If credentials provided: Uses supplied PSCredential

#### Step 3: Create Custom Role (Manual)

The script will display the permissions needed:

```
Role Name: Fileset Snapshot Operator
Permissions:
  - Fileset: VIEW_FILESET
  - Fileset: BACKUP_FILESET
  - SLA: VIEW_SLA
  - Host: VIEW_HOST
  - Cluster: VIEW_CLUSTER
```

**Manual Steps in RSC UI:**

1. Log in to Rubrik Security Cloud
2. Click on your profile icon (top-right) → **Settings**
3. In left sidebar: **Roles** → **Create Role**
4. Fill in:
   - **Name**: `Fileset Snapshot Operator`
   - **Description**: Role for automated Fileset snapshots
5. **Add Permissions**:
   - Click **Add Permission**
   - Select object type and operations as shown above
   - Repeat for all 5 permissions
6. Click **Create**

Confirm in the script when complete: `Y`

#### Step 4: Create Service Account (Manual)

The script will guide you:

**Manual Steps in RSC UI:**

1. Navigate to: **Settings** → **Service Accounts**
2. Click **Create Service Account**
3. Fill in:
   - **Name**: `FilesetBackupAutomation`
   - **Description**: Service account for automated Fileset snapshots
   - **Role**: Select `Fileset Snapshot Operator`
4. Click **Create**
5. **IMPORTANT**: Click **Download Credentials** immediately
6. Save the JSON file to the specified output path

The script can optionally open RSC in your browser automatically.

#### Step 5: Verify Download

The script will check for JSON files in the output directory:

```
Found 1 JSON file(s) in output directory
  - service-account-rk1234.json
```

#### Step 6: Review Summary

```
=====================================================
 SERVICE ACCOUNT SETUP SUMMARY
=====================================================

Service Account Name:
  FilesetBackupAutomation

Description:
  Service account for automated Fileset snapshots

Role:
  Fileset Snapshot Operator

Permissions:
  - Fileset: Read, On-Demand Backup
  - SLA Domain: Read
  - Host: Read
  - Cluster: Read

Credentials Location:
  C:\Scripts

NEXT STEPS:
  1. Copy the JSON credentials file to your script directory
  2. Run New-RscFileSnapshot.ps1 - it will auto-configure the Service Account
  3. The JSON file will be automatically deleted after configuration

=====================================================
```

---

## Troubleshooting

### Common Issues

#### 1. Module Not Found

```
Error: Module RubrikSecurityCloud not found
```

**Solution**:
```powershell
Install-Module -Name RubrikSecurityCloud -Scope CurrentUser -Force
```

#### 2. Authentication Failed

```
Error connecting to Rubrik Security Cloud
```

**Solutions**:
- Verify your RSC credentials
- Check network connectivity
- Ensure you have administrator access
- Try interactive authentication (without `-Credential` parameter)

#### 3. Insufficient Permissions

```
Error: You don't have permission to create roles/service accounts
```

**Solution**: Contact your Rubrik administrator to grant you:
- Organization Admin role, or
- Custom role with permissions to manage Service Accounts and Roles

#### 4. JSON File Not Found

```
WARNING: No JSON files found in output path
```

**Solutions**:
- Ensure you clicked **Download Credentials** in RSC UI
- Check the download location in your browser
- Manually move the file to the specified output path
- Verify file extension is `.json`

#### 5. Browser Doesn't Open

```
Would you like to open RSC in your browser? (Y/N)
```

**Solution**: 
- If browser doesn't open automatically, manually navigate to:
  `https://rubrik.my.rubrik.com`

#### 6. Role Already Exists

If the role name already exists in RSC:
- Use a different role name with `-RoleName` parameter, or
- Use the existing role if it has the same permissions

---

## Security Considerations

### Best Practices

1. **Principle of Least Privilege**: This script creates roles with minimum required permissions only

2. **Credential Storage**: 
   - Store JSON credentials securely
   - Never commit JSON files to version control
   - The `New-RscFileSnapshot.ps1` script automatically deletes the JSON file after configuration

3. **Service Account Rotation**:
   - Periodically rotate Service Account credentials
   - Delete old Service Accounts that are no longer in use

4. **Access Control**:
   - Restrict who can create Service Accounts
   - Monitor Service Account usage in RSC audit logs

5. **Network Security**:
   - Use HTTPS for all RSC connections
   - Consider VPN/firewall rules for production environments

### JSON Credentials File Security

⚠️ **IMPORTANT**: The JSON credentials file contains sensitive authentication tokens

**Encryption Process:**

When you use the `New-RscFileSnapshot.ps1` script (or manually run `Set-RscServiceAccountFile`), the following happens:

1. **Input**: Clear-text JSON file downloaded from RSC
2. **Processing**: `Set-RscServiceAccountFile` reads the JSON and creates an encrypted XML file
3. **Storage**: Encrypted file is saved to PowerShell profile directory:
   - **Windows**: `C:\Users\YourUser\Documents\WindowsPowerShell\rubrik-powershell-sdk\rsc_service_account_default.xml`
   - **Linux**: `~/.config/powershell/rubrik-powershell-sdk/rsc_service_account_default.xml`
   - **Mac**: `~/.config/powershell/rubrik-powershell-sdk/rsc_service_account_default.xml`
4. **Cleanup**: Original JSON file is automatically deleted
5. **Security**: Encrypted file uses:
   - **Windows**: Data Protection API (DPAPI) - only the creating user can decrypt
   - **Linux/Mac**: Platform-specific secure storage

**To find the encrypted file location:**
```powershell
# Show the profile directory path
$PROFILE

# Show the encrypted credentials path
$encryptedPath = Join-Path (Split-Path $PROFILE) "rubrik-powershell-sdk\rsc_service_account_default.xml"
Write-Host "Encrypted credentials location: $encryptedPath"

# Check if it exists
Test-Path $encryptedPath
```

**Do:**
- ✅ Let `Set-RscServiceAccountFile` create the encrypted file automatically
- ✅ Delete the original JSON after encryption (automatic)
- ✅ Backup the encrypted XML file for disaster recovery (same user only)
- ✅ Use file system permissions to restrict access to the profile directory

**Don't:**
- ❌ Commit JSON or XML files to Git repositories
- ❌ Share the encrypted XML (it won't work for other users anyway)
- ❌ Store JSON in publicly accessible locations
- ❌ Try to decrypt the XML manually (use `Connect-Rsc` instead)

---

## Integration with New-RscFileSnapshot

### Workflow

1. **Create Service Account** (this script):
```powershell
.\New-RscServiceAccount.ps1 -ServiceAccountName "FilesetBackup"
# JSON file saved to current directory
```

2. **Copy JSON to Script Directory**:
```powershell
Copy-Item "service-account-*.json" "C:\Scripts\RubrikBackup\"
```

3. **Run Snapshot Script** (auto-configures):
```powershell
cd C:\Scripts\RubrikBackup
.\New-RscFileSnapshot.ps1 -SlaName "Gold"
# Script automatically:
# - Detects JSON file
# - Runs Set-RscServiceAccountFile to create encrypted XML
# - Stores encrypted credentials in PowerShell profile directory
# - Deletes JSON file for security
# - Connects using encrypted credentials
# - Runs snapshot
```

4. **Verify Encrypted Credentials**:
```powershell
# Check if encrypted file was created
$encryptedPath = Join-Path (Split-Path $PROFILE) "rubrik-powershell-sdk\rsc_service_account_default.xml"
if (Test-Path $encryptedPath) {
    Write-Host "✓ Encrypted credentials configured at: $encryptedPath" -ForegroundColor Green
} else {
    Write-Host "✗ Encrypted credentials not found" -ForegroundColor Red
}
```

5. **Subsequent Runs** (no JSON needed):
```powershell
# Future executions use the encrypted credentials automatically
.\New-RscFileSnapshot.ps1 -SlaName "Gold"
# Connect-Rsc reads from: $PROFILE\..\rubrik-powershell-sdk\rsc_service_account_default.xml
```

### Understanding the Credential Storage

**First Run (with JSON):**
```
1. JSON file in script directory
   ↓
2. Set-RscServiceAccountFile processes JSON
   ↓
3. Creates encrypted XML: $PROFILE\..\rubrik-powershell-sdk\rsc_service_account_default.xml
   ↓
4. Deletes JSON file
   ↓
5. Connect-Rsc uses encrypted XML
```

**Subsequent Runs (no JSON):**
```
1. No JSON file found
   ↓
2. Connect-Rsc automatically uses encrypted XML
   ↓
3. Authentication succeeds
```

### Multi-User Considerations

⚠️ **Important**: The encrypted XML file is **user-specific**

- Each Windows/Linux user needs their own JSON file
- The encrypted file created by User A cannot be used by User B
- For scheduled tasks running as SYSTEM, create the encrypted file while running as SYSTEM:
  ```powershell
  # Run PowerShell as SYSTEM using PsExec
  PsExec.exe -i -s powershell.exe
  
  # Then configure the Service Account
  Set-RscServiceAccountFile C:\path\to\service-account.json
  ```

---

## Output Structure

### Console Output

The script provides color-coded output:

- **Cyan**: Informational messages
- **Green**: Success messages
- **Yellow**: Warnings and prompts
- **Red**: Errors

### Files Created

```
OutputPath/
└── service-account-XXXXX.json    # Downloaded from RSC (manual step)
```

### Exit Codes

- **0**: Success or user cancelled
- **1**: Error occurred

---

## Automation Considerations

While this script guides manual steps, you can automate the workflow around it:

### Automated Credential Distribution

```powershell
# Run Service Account creation (manual steps)
.\New-RscServiceAccount.ps1 -ServiceAccountName "BackupSvc" -OutputPath "C:\Temp"

# After manual completion, distribute credentials
$jsonFile = Get-ChildItem "C:\Temp\service-account-*.json" | Select-Object -First 1
Copy-Item $jsonFile.FullName "\\fileserver\scripts\"

# Clean up temporary location
Remove-Item $jsonFile.FullName -Force
```

### Scheduled Re-creation (for rotation)

```powershell
# Monthly service account rotation
$monthYear = Get-Date -Format "yyyy-MM"
$accountName = "FilesetBackup-$monthYear"

.\New-RscServiceAccount.ps1 `
    -ServiceAccountName $accountName `
    -OutputPath "C:\Credentials\$monthYear"
```

---

## Command Reference

### Display Help

```powershell
.\New-RscServiceAccount.ps1 -Help
.\New-RscServiceAccount.ps1 -?
```

### Check Version

```powershell
Get-Help .\New-RscServiceAccount.ps1 -Full
```

### Verify Prerequisites

```powershell
# Check PowerShell version
$PSVersionTable.PSVersion

# Check RSC module
Get-Module -ListAvailable RubrikSecurityCloud

# Test RSC connectivity
Connect-Rsc
Get-RscCluster
Disconnect-Rsc
```

---

## Support

For issues and questions:
- **GitHub Issues**: https://github.com/mbriotto/New-RscFileSnapshot/issues
- **Rubrik PowerShell SDK**: https://github.com/rubrikinc/rubrik-powershell-sdk
- **Rubrik Security Cloud**: Contact Rubrik Support
- **Documentation**: https://docs.rubrik.com

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## Related Tools

- **New-RscFileSnapshot**: Main snapshot automation script
- **Rubrik PowerShell SDK**: Official Rubrik PowerShell module
- **Rubrik Security Cloud**: Web-based management interface

---

## Version History

- **1.0** (January 2026): Initial release

---

## License

This program is free software: you can redistribute it and/or modify it under the terms of the **GNU General Public License v3.0** as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but **WITHOUT ANY WARRANTY**; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see https://www.gnu.org/licenses/.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

---

## Author

GitHub: [@mbriotto](https://github.com/mbriotto)  
Repository: https://github.com/mbriotto/New-RscFileSnapshot

---

## Acknowledgments

- Rubrik for the Rubrik Security Cloud platform
- Rubrik PowerShell SDK team for the excellent tooling
- Community contributors

---

## FAQ

### Q: Why can't this script fully automate role and Service Account creation?

**A**: The current Rubrik PowerShell SDK has limitations for programmatic role and Service Account creation. This script provides a guided manual process with automation where possible.

### Q: Can I use an existing role instead of creating a new one?

**A**: Yes! If you have an existing role with the required permissions, you can skip the role creation step and assign that role when creating the Service Account.

### Q: What happens to the JSON file after I configure it?

**A**: The `Set-RscServiceAccountFile` command (used by `New-RscFileSnapshot.ps1`) performs these steps:
1. Reads the JSON credentials
2. Creates an encrypted XML file in your PowerShell profile directory
3. Prompts you to delete the JSON file (or deletes it automatically with `-DisablePrompts`)
4. The encrypted XML is stored at: `$PROFILE\..\rubrik-powershell-sdk\rsc_service_account_default.xml`

### Q: Where exactly is the encrypted credentials file stored?

**A**: The location depends on your operating system and PowerShell profile:
- **Windows**: `C:\Users\YourUser\Documents\WindowsPowerShell\rubrik-powershell-sdk\rsc_service_account_default.xml`
- **Windows (PowerShell 7+)**: `C:\Users\YourUser\Documents\PowerShell\rubrik-powershell-sdk\rsc_service_account_default.xml`
- **Linux/Mac**: `~/.config/powershell/rubrik-powershell-sdk/rsc_service_account_default.xml`

To find your exact location:
```powershell
Join-Path (Split-Path $PROFILE) "rubrik-powershell-sdk\rsc_service_account_default.xml"
```

### Q: Can I use this Service Account for other operations?

**A**: The Service Account has minimal permissions specifically for Fileset snapshots. For other operations, create separate Service Accounts with appropriate permissions.

### Q: How do I rotate Service Account credentials?

**A**: Create a new Service Account with a new name (e.g., `FilesetBackup-2026-02`), update your scripts to use the new credentials, then delete the old Service Account.

### Q: Is this compatible with Rubrik CDM (on-premises)?

**A**: This script is designed for Rubrik Security Cloud (SaaS). For on-premises CDM, use the Rubrik CDM PowerShell module instead.

---

**For the complete snapshot automation solution, see the main [README.md](README.md) documentation.**