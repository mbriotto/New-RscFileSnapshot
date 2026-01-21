# New-RscServiceAccount.ps1

PowerShell **interactive guide** for creating Service Accounts in Rubrik Security Cloud with minimum required permissions for Fileset snapshots.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)

---

## ⚠️ IMPORTANT - SDK LIMITATION NOTICE

**This script cannot fully automate Service Account creation** due to Rubrik PowerShell SDK limitations.

The script provides an **interactive guide** for manual steps in the RSC web interface.

**Reference:** https://github.com/rubrikinc/rubrik-powershell-sdk

---

## Overview

`New-RscServiceAccount.ps1` is an **interactive guide** that helps you create Service Accounts in Rubrik Security Cloud (RSC) with the exact permissions needed to run the `New-RscFileSnapshot.ps1` script. 

Due to SDK limitations, manual steps in the RSC web interface are required.

---

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Parameters](#parameters)
- [Permissions Granted](#permissions-granted)
- [Step-by-Step Guide](#step-by-step-guide)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)
- [Integration with New-RscFileSnapshot](#integration-with-new-rscfilesnapshot)

---

## Features

### What This Script Provides:

✅ **Verified Connectivity**: Confirms access to RSC before starting  
✅ **Exact Specifications**: Shows precise permissions and configuration  
✅ **Step-by-Step Instructions**: Clear guidance for web UI navigation  
✅ **Browser Integration**: Optionally opens RSC in your browser  
✅ **Download Validation**: Checks that JSON credentials were saved  
✅ **Colored Output**: Clear, color-coded console messages  
✅ **Comprehensive Documentation**: Full audit trail of what was created  
✅ **Safe Defaults**: Sensible default values for all optional parameters  
✅ **Error Handling**: Graceful handling of network issues and user cancellation  

---

## Prerequisites

### 1. Rubrik PowerShell SDK

```powershell
# Run as Administrator
Install-Module -Name RubrikSecurityCloud -Scope AllUsers
```

Verify installation:
```powershell
Get-Module -ListAvailable RubrikSecurityCloud
```

**Note**: Using `-Scope AllUsers` ensures the module is available system-wide, including for scheduled tasks.

### 2. Rubrik Security Cloud Access

- Administrator access to Rubrik Security Cloud
- Permissions to create Service Accounts and Roles
- Access to your organization's Rubrik Security Cloud URL

### 3. PowerShell Version

- PowerShell 5.1 or higher
- Windows PowerShell or PowerShell Core

### 4. Web Browser

- Required for RSC web interface access
- Modern browser (Chrome, Edge, Firefox, Safari)

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

### Display Help

```powershell
.\New-RscServiceAccount.ps1 -Help
.\New-RscServiceAccount.ps1 -?
```

### Basic Syntax

```powershell
.\New-RscServiceAccount.ps1 -ServiceAccountName <Name> [OPTIONS]
```

### Quick Start

```powershell
# Run the interactive guide
.\New-RscServiceAccount.ps1 -ServiceAccountName "FilesetBackupAutomation"
```

The script will:
1. Display SDK limitation notice
2. Connect to Rubrik Security Cloud
3. Guide you through creating a custom role (manual)
4. Guide you through creating the Service Account (manual)
5. Verify the JSON credentials file is downloaded
6. Provide comprehensive next steps

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

The script guides you to create a custom role with the **minimum permissions** required for Fileset snapshots:

### Object-Level Permissions

| Object Type | Operations | Purpose |
|-------------|------------|---------|
| **Fileset** | `VIEW_FILESET`<br>`BACKUP_FILESET` | Read Fileset configuration<br>Trigger on-demand backups |
| **SLA Domain** | `VIEW_SLA` | Read SLA policies |
| **Host** | `VIEW_HOST` | Read host information |
| **Cluster** | `VIEW_CLUSTER` | Read cluster configuration |

### Security Principle

This follows the **Principle of Least Privilege**:
- Only permissions absolutely required for snapshots
- No write access to SLAs, hosts, or clusters
- No ability to delete or modify Filesets
- No access to other workload types (VMs, databases, etc.)

---

## Step-by-Step Guide

### Complete Interactive Walkthrough

#### Prerequisites Check

```powershell
# Verify PowerShell version
$PSVersionTable.PSVersion  # Should be 5.1 or higher

# Verify SDK is installed
Get-Module -ListAvailable RubrikSecurityCloud
```

#### Step 1: Run the Script

```powershell
.\New-RscServiceAccount.ps1 -ServiceAccountName "FilesetBackupAutomation"
```

#### Step 2: SDK Limitation Notice

The script displays:
```
========================================================================
 ⚠️  RUBRIK POWERSHELL SDK LIMITATION
========================================================================

The Rubrik PowerShell SDK (RubrikSecurityCloud module) does not currently
expose GraphQL mutations or API endpoints for:

  ❌ Creating custom roles programmatically
  ❌ Creating Service Accounts via automation
  ❌ Assigning permissions to roles via code

As a result, this script provides an INTERACTIVE GUIDED PROCESS for the
manual steps required in the Rubrik Security Cloud web interface.

Reference: https://github.com/rubrikinc/rubrik-powershell-sdk
```

#### Step 3: Connect to RSC

The script connects to verify access:
- If no credentials: Opens browser for interactive login
- If credentials provided: Uses supplied PSCredential

```
Connecting to Rubrik Security Cloud...
(This verifies you have access to RSC)

✓ Connected to Rubrik cluster: Production-Cluster
```

#### Step 4: Create Custom Role (MANUAL)

The script displays:

```
========================================================================
 STEP 1: CREATE CUSTOM ROLE (Manual Steps Required)
========================================================================

⚠️  Due to SDK limitations, you must create the role manually in RSC

Role Configuration:
  Name: Fileset Snapshot Operator
  Description: Custom role for automated Fileset snapshots

Required Permissions (minimum principle):
  - Fileset: VIEW_FILESET
    (Read Fileset configuration and properties)
  - Fileset: BACKUP_FILESET
    (Trigger on-demand Fileset snapshots)
  - SLA: VIEW_SLA
    (Read SLA Domain policies)
  - Host: VIEW_HOST
    (Read host information and configuration)
  - Cluster: VIEW_CLUSTER
    (Read cluster details and status)
```

**Manual Steps in RSC UI:**

1. **Navigate to Roles:**
   - Click profile icon (top-right) → **Settings**
   - Left sidebar → **Roles**

2. **Create New Role:**
   - Click **Create Role**
   - Name: `Fileset Snapshot Operator`
   - Description: `Custom role for automated Fileset snapshots`

3. **Add Each Permission:**
   - Click **Add Permission** (repeat 5 times)
   - Configure each permission as shown above

4. **Save:**
   - Review all 5 permissions are added
   - Click **Create**

**Script Prompt:**
```
Would you like to open Rubrik Security Cloud in your browser now? (Y/N)
```

**Confirmation:**
```
Have you successfully created the role 'Fileset Snapshot Operator'? (Y/N)
```

#### Step 5: Create Service Account (MANUAL)

The script displays:

```
========================================================================
 STEP 2: CREATE SERVICE ACCOUNT (Manual Steps Required)
========================================================================

⚠️  Due to SDK limitations, you must create the Service Account manually in RSC

Service Account Configuration:
  Name: FilesetBackupAutomation
  Description: Service account for automated Fileset snapshots
  Role: Fileset Snapshot Operator
```

**Manual Steps in RSC UI:**

1. **Navigate to Service Accounts:**
   - Settings → **Service Accounts**

2. **Create New Service Account:**
   - Click **Create Service Account**

3. **Fill Details:**
   - Name: `FilesetBackupAutomation`
   - Description: `Service account for automated Fileset snapshots`
   - Click **Next**

4. **Assign Role:**
   - Select: `Fileset Snapshot Operator`
   - Click **Next** or **Create**

5. **Download Credentials (CRITICAL!):**
   - ⚠️ **This is your ONLY chance!**
   - Click **Download Credentials** immediately
   - Save to the output directory shown by the script
   - File will be named like: `service-account-rk1234.json`

**Script Prompt:**
```
Would you like to open Rubrik Security Cloud in your browser now? (Y/N)
```

**Confirmation:**
```
Have you successfully created the Service Account and downloaded the JSON file? (Y/N)
```

#### Step 6: Verify Download

The script checks for the JSON file:

```
========================================================================
 STEP 3: VERIFY CREDENTIALS DOWNLOAD
========================================================================

Checking for JSON credentials file in: C:\Scripts

✓ Found 1 JSON file(s) in output directory:
  - service-account-rk1234.json
    Size: 2.34 KB
    Created: 01/18/2026 14:23:45
```

If no file is found:
```
✗ WARNING: No JSON files found in C:\Scripts

Please ensure you:
  1. Clicked 'Download Credentials' in the RSC interface
  2. Saved the file to: C:\Scripts
  3. The file has a .json extension

Enter the full path to the JSON file (or press Enter to skip):
```

#### Step 7: Review Summary

```
========================================================================
 SERVICE ACCOUNT SETUP SUMMARY
========================================================================

✓ Configuration Completed Successfully

Service Account Details:
  Name:        FilesetBackupAutomation
  Description: Service account for automated Fileset snapshots
  Role:        Fileset Snapshot Operator

Permissions Granted:
  - Fileset: Read, On-Demand Backup
  - SLA Domain: Read
  - Host: Read
  - Cluster: Read

Credentials Location:
  C:\Scripts

========================================================================
 NEXT STEPS
========================================================================

1. Copy the JSON credentials file to your script directory
   Example:
   Copy-Item 'C:\Scripts\service-account-*.json' 'C:\Scripts\'

2. Run New-RscFileSnapshot.ps1
   The script will automatically:
   - Detect the JSON file
   - Configure encrypted credentials (via Set-RscServiceAccountFile)
   - Store encrypted XML in PowerShell profile directory
   - Delete the JSON file for security

3. Verify encrypted credentials were created
   Location: $PROFILE\..\rubrik-powershell-sdk\rsc_service_account_default.xml

4. Subsequent executions will use encrypted credentials automatically
   No JSON file needed after first run!
```

---

## Examples

### Example 1: Basic Creation (Default Settings)

```powershell
.\New-RscServiceAccount.ps1 -ServiceAccountName "FilesetBackupAutomation"
```

**Result:**
- Interactive guide for creating role and Service Account
- Default role name: `Fileset Snapshot Operator`
- Credentials saved to current directory

### Example 2: Custom Output Location

```powershell
.\New-RscServiceAccount.ps1 `
    -ServiceAccountName "BackupService" `
    -OutputPath "C:\Credentials\Rubrik"
```

**Result:**
- JSON credentials saved to `C:\Credentials\Rubrik`
- Creates output directory if it doesn't exist

### Example 3: Custom Role Name and Description

```powershell
.\New-RscServiceAccount.ps1 `
    -ServiceAccountName "ProdFilesetAutomation" `
    -RoleName "Production Fileset Operator" `
    -ServiceAccountDescription "Automated snapshots for production filesets only"
```

**Result:**
- Custom role name used in instructions
- Custom description provided

### Example 4: With Explicit Credentials

```powershell
$cred = Get-Credential
.\New-RscServiceAccount.ps1 `
    -ServiceAccountName "AutoSnapshotService" `
    -Credential $cred `
    -OutputPath "\\NetworkShare\Rubrik\Credentials"
```

**Result:**
- Uses provided credentials for RSC connection
- Saves to network share

### Example 5: Multiple Service Accounts

```powershell
# Development environment
.\New-RscServiceAccount.ps1 `
    -ServiceAccountName "Dev-FilesetBackup" `
    -RoleName "Dev Fileset Operator" `
    -OutputPath "C:\Credentials\Dev"

# Production environment
.\New-RscServiceAccount.ps1 `
    -ServiceAccountName "Prod-FilesetBackup" `
    -RoleName "Prod Fileset Operator" `
    -OutputPath "C:\Credentials\Prod"
```

**Result:**
- Separate Service Accounts for different environments
- Different roles with potentially different permissions

---

## Troubleshooting

### Common Issues

#### 1. SDK Module Not Found

```
Error: Module RubrikSecurityCloud not found
```

**Solution:**
```powershell
Install-Module -Name RubrikSecurityCloud -Scope AllUsers -Force
Import-Module RubrikSecurityCloud
```

#### 2. Connection Failed

```
✗ ERROR connecting to Rubrik Security Cloud
```

**Solutions:**
- Verify network connectivity to RSC
- Check credentials are correct
- Ensure you have admin access to RSC
- Try interactive authentication (omit `-Credential`)

#### 3. Insufficient RSC Permissions

```
Error: You don't have permission to create roles/Service Accounts
```

**Solution:** Contact your Rubrik administrator to grant:
- Organization Admin role, **or**
- Custom role with permissions to manage Service Accounts and Roles

#### 4. Browser Doesn't Open

```
Would you like to open RSC in your browser? (Y/N)
```

**Solution:**
- If auto-open fails, manually navigate to your Rubrik Security Cloud console
- Check your default browser settings
- Try different browser

#### 5. JSON File Not Found

```
✗ WARNING: No JSON files found in output directory
```

**Solutions:**
- Verify you clicked "Download Credentials" in RSC
- Check browser's download folder
- Manually move file to specified output path
- Ensure file has `.json` extension

#### 6. Role Already Exists

If the role name already exists:

**Option 1 - Use Different Name:**
```powershell
.\New-RscServiceAccount.ps1 `
    -ServiceAccountName "FilesetBackup" `
    -RoleName "Fileset Snapshot Operator v2"
```

**Option 2 - Use Existing Role:**
- During the interactive process, skip role creation
- Assign the existing role when creating Service Account

#### 7. Service Account Name Already Exists

**Solution:** Use a different name:
```powershell
.\New-RscServiceAccount.ps1 `
    -ServiceAccountName "FilesetBackup-2026-01"
```

---

## Integration with New-RscFileSnapshot

### Complete Workflow

#### 1. Create Service Account (This Script)

```powershell
.\New-RscServiceAccount.ps1 `
    -ServiceAccountName "FilesetBackup" `
    -OutputPath "C:\Scripts"

# Follow interactive guide to:
# - Create role manually
# - Create Service Account manually
# - Download JSON credentials
```

#### 2. Verify JSON File

```powershell
Get-ChildItem "C:\Scripts\service-account-*.json"
```

#### 3. First Run of Snapshot Script

```powershell
cd C:\Scripts

# First execution - configures Service Account
.\New-RscFileSnapshot.ps1 -SlaName "Gold"

# The script automatically:
# 1. Detects JSON file in script directory
# 2. Runs Set-RscServiceAccountFile
# 3. Creates encrypted XML: $PROFILE\..\rubrik-powershell-sdk\rsc_service_account_default.xml
# 4. Deletes JSON file for security
# 5. Connects using encrypted credentials
# 6. Executes snapshot
```

#### 4. Verify Encrypted Credentials

```powershell
# Check encrypted file location
$encryptedPath = Join-Path (Split-Path $PROFILE) "rubrik-powershell-sdk\rsc_service_account_default.xml"

if (Test-Path $encryptedPath) {
    Write-Host "✓ Encrypted credentials configured" -ForegroundColor Green
    Write-Host "  Location: $encryptedPath" -ForegroundColor Gray
} else {
    Write-Host "✗ Encrypted credentials not found" -ForegroundColor Red
}
```

#### 5. Subsequent Executions

```powershell
# Future runs - uses encrypted credentials automatically
.\New-RscFileSnapshot.ps1 -SlaName "Gold"

# No JSON file needed!
# Connect-Rsc reads from encrypted XML automatically
```

### Security Flow

```
Step 1: Create Service Account (Manual via this script)
   ↓
Step 2: Download JSON credentials (Manual in RSC UI)
   ↓
Step 3: JSON file in script directory (Clear-text, temporary)
   ↓
Step 4: First run of New-RscFileSnapshot.ps1
   ↓
Step 5: Set-RscServiceAccountFile processes JSON
   ↓
Step 6: Creates encrypted XML (DPAPI on Windows)
   ↓
Step 7: JSON file deleted automatically (Security)
   ↓
Step 8: Future runs use encrypted XML (Permanent, secure)
```

### Multi-User Considerations

⚠️ **Important:** Encrypted credentials are **user-specific**

**Scenario 1 - User A creates credentials:**
```powershell
# User A runs:
.\New-RscFileSnapshot.ps1 -SlaName "Gold"
# Encrypted XML created for User A only

# User B tries to run:
.\New-RscFileSnapshot.ps1 -SlaName "Gold"
# ERROR: Cannot decrypt User A's credentials
```

**Solution:** Each user needs their own JSON file:
```powershell
# User B gets their own Service Account
.\New-RscServiceAccount.ps1 -ServiceAccountName "FilesetBackup-UserB"
# Download JSON, run New-RscFileSnapshot.ps1 to configure
```

**Scenario 2 - Scheduled Task (SYSTEM account):**
```powershell
# Must configure credentials as SYSTEM
# Option 1: Use PsExec
PsExec.exe -i -s powershell.exe

# Then as SYSTEM:
cd C:\Scripts
.\New-RscFileSnapshot.ps1 -SlaName "Gold"
# This creates encrypted credentials for SYSTEM account

# Option 2: Configure in Scheduled Task script
# See New-RscFileSnapshotScheduler.ps1 which handles this automatically
```

---

## Output Structure

### Console Output

Color-coded for clarity:

- **Cyan**: Informational messages
- **Green**: Success messages  
- **Yellow**: Warnings and prompts
- **Red**: Errors and critical notices
- **White**: Configuration details
- **Gray**: Supplementary information

### Files Created

```
OutputPath/
└── service-account-XXXXX.json    # Downloaded manually from RSC
                                   # Deleted after first use by New-RscFileSnapshot.ps1

PowerShell Profile Directory/
└── rubrik-powershell-sdk/
    └── rsc_service_account_default.xml  # Created by Set-RscServiceAccountFile
                                          # Encrypted (DPAPI on Windows)
                                          # Permanent credentials storage
```

### Exit Codes

- **0**: Success or user cancelled gracefully
- **1**: Error occurred (connection failed, permissions issue, etc.)

---

## Security Considerations

### Principle of Least Privilege

The role created has **only** the permissions needed:

✅ **Granted:**
- Read Filesets
- Trigger Fileset snapshots
- Read SLAs
- Read Hosts
- Read Clusters

❌ **NOT Granted:**
- Modify/delete Filesets
- Create/modify SLAs
- Modify host configuration
- Access to VMs, databases, or other workloads
- User management
- System configuration

### Credential Security

**JSON File (Temporary):**
- Clear-text credentials
- Should be deleted after use (automatic)
- Never commit to version control
- Don't store in shared locations

**Encrypted XML (Permanent):**
- Windows: DPAPI encryption (user-specific)
- Linux/Mac: Platform-specific secure storage
- Cannot be decrypted by other users
- Cannot be transferred between systems

**Best Practices:**
```powershell
# ✅ DO:
# - Let Set-RscServiceAccountFile handle encryption
# - Delete JSON after first use (automatic)
# - Backup encrypted XML for disaster recovery (same user only)
# - Use file system permissions to protect profile directory

# ❌ DON'T:
# - Commit JSON or XML to Git
# - Share encrypted XML (won't work anyway)
# - Store JSON in public locations
# - Try to manually decrypt XML
```

### Service Account Rotation

**Best Practice:** Rotate credentials periodically

```powershell
# Example: Monthly rotation
$monthYear = Get-Date -Format "yyyy-MM"

# Create new Service Account
.\New-RscServiceAccount.ps1 `
    -ServiceAccountName "FilesetBackup-$monthYear" `
    -OutputPath "C:\Credentials\$monthYear"

# Update scripts to use new credentials
# (Replace JSON file and re-run New-RscFileSnapshot.ps1)

# Delete old Service Account in RSC UI
# (Settings → Service Accounts → Delete)
```

### Audit Trail

The interactive guide provides documentation:
- Exact permissions granted
- Service Account name and description
- Role name and permissions
- Timestamp of creation
- User who created it

Save the console output for compliance:
```powershell
.\New-RscServiceAccount.ps1 -ServiceAccountName "FilesetBackup" | Tee-Object -FilePath "C:\Audit\SA-Creation-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
```

---

## Command Reference

### Display Help

```powershell
.\New-RscServiceAccount.ps1 -Help
.\New-RscServiceAccount.ps1 -?
```

### Check SDK Version

```powershell
Get-Module -ListAvailable RubrikSecurityCloud | Select-Object Name, Version
```

### Verify Prerequisites

```powershell
# PowerShell version
$PSVersionTable.PSVersion

# SDK installed
Get-Module -ListAvailable RubrikSecurityCloud

# Test RSC connectivity
Connect-Rsc
Get-RscCluster
Disconnect-Rsc
```

### List Existing Service Accounts (Manual)

```powershell
# Currently no cmdlet available
# Must check in RSC UI: Settings → Service Accounts
```

### Check Encrypted Credentials

```powershell
$encPath = Join-Path (Split-Path $PROFILE) "rubrik-powershell-sdk\rsc_service_account_default.xml"
if (Test-Path $encPath) {
    Get-Item $encPath | Select-Object FullName, Length, CreationTime, LastWriteTime
}
```

---

## Support

For issues and questions:

- **GitHub Issues**: https://github.com/mbriotto/New-RscFileSnapshot/issues
- **Rubrik PowerShell SDK**: https://github.com/rubrikinc/rubrik-powershell-sdk
- **Rubrik Security Cloud**: Contact Rubrik Support
- **Documentation**: https://docs.rubrik.com

## Contributing

We welcome contributions! If Rubrik adds SDK support for role/Service Account creation, please submit a PR to enhance automation.

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AutomatedSACreation`)
3. Commit changes (`git commit -m 'Add automated SA creation via new SDK cmdlets'`)
4. Push to branch (`git push origin feature/AutomatedSACreation`)
5. Open Pull Request

---

## Related Tools

- **New-RscFileSnapshot**: Main snapshot automation script
- **New-RscFileSnapshotScheduler**: Scheduled task creation automation
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
- Rubrik PowerShell SDK team for excellent tooling
- Community contributors

**Note:** This script will be updated when Rubrik enhances the PowerShell SDK with role and Service Account management cmdlets.

---

## FAQ

### Q: Why can't this script fully automate Service Account creation?

**A:** The Rubrik PowerShell SDK does not currently provide cmdlets for creating roles or Service Accounts. Manual steps in the RSC web interface are required.

**Reference:** https://github.com/rubrikinc/rubrik-powershell-sdk

### Q: When will full automation be available?

**A:** When Rubrik updates the PowerShell SDK to include the necessary cmdlets. Monitor the SDK GitHub repository for updates.

### Q: Can I automate this using direct API calls?

**A:** Not recommended. The required API endpoints are not publicly documented, and the interactive guide is the most reliable current approach.

### Q: What happens to the JSON file after I configure it?

**A:** The workflow is:
1. **Manual download** from RSC → JSON file (clear-text)
2. **First run** of `New-RscFileSnapshot.ps1` detects JSON
3. **Set-RscServiceAccountFile** creates encrypted XML
4. **JSON deleted** automatically for security
5. **Future runs** use encrypted XML from PowerShell profile directory

### Q: Can I use an existing role instead of creating a new one?

**A:** Yes! During the interactive process:
1. When prompted about role creation, note you'll use an existing role
2. Continue to Service Account creation
3. When assigning role in RSC UI, select your existing role

Make sure the existing role has all required permissions.

### Q: How do I rotate Service Account credentials?

**A:** Best practice for rotation:
```powershell
# 1. Create new Service Account with date suffix
.\New-RscServiceAccount.ps1 -ServiceAccountName "FilesetBackup-2026-02"

# 2. Update your scripts to use new JSON
# (Replace JSON file in script directory)

# 3. Run snapshot script to configure new credentials
.\New-RscFileSnapshot.ps1 -SlaName "Gold"

# 4. Delete old Service Account in RSC UI
# Settings → Service Accounts → [Old SA] → Delete
```

### Q: Is this compatible with Rubrik CDM (on-premises)?

**A:** No. This script is designed specifically for **Rubrik Security Cloud (RSC)** - the SaaS platform.

For on-premises Rubrik CDM, use the `Rubrik` PowerShell module instead:
```powershell
Install-Module -Name Rubrik
```

### Q: Can I contribute to make this fully automated?

**A:** Yes! If/when Rubrik adds the required SDK cmdlets, we welcome PRs to add automation. Monitor https://github.com/rubrikinc/rubrik-powershell-sdk for SDK updates.

---

**For the complete snapshot automation solution, see the main [README.md](README.md) and [New-RscFileSnapshot.ps1 README](New-RscFileSnapshot.ps1-README.md) documentation.**
