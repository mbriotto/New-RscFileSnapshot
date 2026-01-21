# Check-RscServiceAccountStatus.ps1

**Version:** 1.0  
**Author:** [mbriotto](https://github.com/mbriotto)  
**Release Date:** January 2026

## Overview

`Check-RscServiceAccountStatus.ps1` is a diagnostic PowerShell script designed to verify and manage Rubrik Security Cloud (RSC) Service Account encrypted credentials across different execution contexts. The script checks for credential files in multiple locations and provides an interactive menu for credential management.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Credential Locations](#credential-locations)
- [Output Examples](#output-examples)
- [Interactive Deletion Menu](#interactive-deletion-menu)
- [Understanding SYSTEM Account Types](#understanding-system-account-types)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [License](#license)

---

## Features

### ✅ Comprehensive Credential Detection
- **Current User Credentials**: Checks for encrypted credentials in the current user's profile
- **SYSTEM Account (Standard)**: Verifies credentials for scheduled tasks running as SYSTEM
- **SYSTEM Account (PsExec)**: Detects credentials created when using PsExec to run scripts as SYSTEM
- **Module Verification**: Confirms RubrikSecurityCloud PowerShell module installation

### 🔍 Detailed Information Display
- Credential file location
- File size (bytes)
- Creation timestamp
- Last modification timestamp
- Last access timestamp

### 🎯 Intelligent Analysis
- Identifies which execution contexts will work or fail
- Provides contextual recommendations
- Explains the difference between SYSTEM account types
- Detects duplicate SYSTEM configurations

### 🗑️ Interactive Credential Management
- Delete specific credential files individually
- Delete all credential files at once
- Option to exit without deleting anything
- Safety confirmations before deletion
- Administrator privilege detection

---

## Prerequisites

### Required
- **Operating System**: Windows 10/11 or Windows Server 2016+
- **PowerShell**: Version 5.1 or later
- **Permissions**: 
  - Standard user permissions for checking current user credentials
  - Administrator permissions for checking/deleting SYSTEM credentials

### Optional
- **RubrikSecurityCloud Module**: For connecting to Rubrik Security Cloud
- **PsExec**: For SYSTEM credential location detection (must be in script directory)

---

## Installation

1. Download the script:
```powershell
# Clone the repository or download directly
git clone https://github.com/mbriotto/rubrik-scripts.git
cd rubrik-scripts
```

2. Verify the script is not blocked:
```powershell
Unblock-File -Path .\Check-RscServiceAccountStatus.ps1
```

3. (Optional) Place `PsExec.exe` in the same directory to enable PsExec credential detection:
```
C:\Scripts\
├── Check-RscServiceAccountStatus.ps1
└── PsExec.exe  (optional)
```

---

## Usage

### Basic Usage

Run the script without parameters to perform a complete check:

```powershell
.\Check-RscServiceAccountStatus.ps1
```

### Display Help

Show detailed help information:

```powershell
.\Check-RscServiceAccountStatus.ps1 -Help
```

or

```powershell
.\Check-RscServiceAccountStatus.ps1 -?
```

### Running as Administrator

To check and delete SYSTEM credentials, run PowerShell as Administrator:

```powershell
# Right-click PowerShell and select "Run as Administrator"
cd C:\Scripts
.\Check-RscServiceAccountStatus.ps1
```

---

## Credential Locations

The script checks for encrypted credential files in the following locations:

### 1. Current User
**Path (PowerShell 5.1):**
```
%USERPROFILE%\Documents\WindowsPowerShell\rubrik-powershell-sdk\rsc_service_account_default.xml
```

**Path (PowerShell 7+):**
```
%USERPROFILE%\Documents\PowerShell\rubrik-powershell-sdk\rsc_service_account_default.xml
```

**Used by:** Manual script execution by the current user

---

### 2. SYSTEM Account (Standard)
**Path (PowerShell 5.1):**
```
C:\Windows\System32\config\systemprofile\Documents\WindowsPowerShell\rubrik-powershell-sdk\rsc_service_account_default.xml
```

**Path (PowerShell 7+):**
```
C:\Windows\System32\config\systemprofile\Documents\PowerShell\rubrik-powershell-sdk\rsc_service_account_default.xml
```

**Used by:** Windows scheduled tasks running as SYSTEM

---

### 3. SYSTEM Account (PsExec)
**Path (PowerShell 5.1):**
```
C:\Windows\SysWOW64\config\systemprofile\Documents\WindowsPowerShell\rubrik-powershell-sdk\rsc_service_account_default.xml
```

**Path (PowerShell 7+):**
```
C:\Windows\SysWOW64\config\systemprofile\Documents\PowerShell\rubrik-powershell-sdk\rsc_service_account_default.xml
```

**Used by:** Scripts executed via PsExec as SYSTEM

---

## Output Examples

### Example 1: Current User Only Configured

```
==========================================================
 RUBRIK SERVICE ACCOUNT STATUS CHECK
==========================================================

Checking RubrikSecurityCloud module...
 [+] Module installed: Version 1.0.0

==========================================================

Checking CURRENT USER (John Doe) credentials...
Expected location: C:\Users\John Doe\Documents\WindowsPowerShell\rubrik-powershell-sdk\rsc_service_account_default.xml

 [+] CREDENTIALS FOUND

Credential File Details:
  Account: CURRENT USER (John Doe)
  Location: C:\Users\John Doe\Documents\WindowsPowerShell\rubrik-powershell-sdk\rsc_service_account_default.xml
  Size: 3364 bytes
  Created: 01/15/2026 10:30:00
  Last Modified: 01/15/2026 10:30:00
  Last Accessed: 01/20/2026 14:25:00

==========================================================

Checking SYSTEM ACCOUNT (Standard) credentials...
Expected location: C:\Windows\System32\config\systemprofile\Documents\WindowsPowerShell\rubrik-powershell-sdk\rsc_service_account_default.xml

 [-] CREDENTIALS NOT FOUND

==========================================================

Checking for PsExec availability...
 [-] PsExec NOT found in script directory

==========================================================

SUMMARY:

 [+] CURRENT USER (John Doe): CONFIGURED
 [-] SYSTEM ACCOUNT (Standard): NOT CONFIGURED

Status: 1 credential file(s) found

What this means:
  [OK] Manual script execution as current user: WILL WORK
  [!!] Scheduled tasks running as SYSTEM: WILL FAIL

Recommendation:
  Configure SYSTEM credentials for scheduled tasks
  Use PsExec to run script as SYSTEM with JSON file
```

---

### Example 2: All Credentials Configured

```
SUMMARY:

 [+] CURRENT USER (Jane Smith): CONFIGURED
 [+] SYSTEM ACCOUNT (Standard): CONFIGURED
 [+] SYSTEM ACCOUNT (PsExec): CONFIGURED

Understanding SYSTEM Account Locations:
  - SYSTEM (Standard):  Used by regular scheduled tasks
  - SYSTEM (PsExec):    Used when running scripts via PsExec as SYSTEM

  These are DIFFERENT locations. You may need credentials in one or both,
  depending on how you run your scripts.

Status: 3 credential file(s) found

What this means:
  [OK] Manual script execution as current user: WILL WORK
  [OK] Scheduled tasks running as SYSTEM: WILL WORK

Note:
  You have SYSTEM credentials in both standard and PsExec locations
  This is usually not necessary - consider keeping only one
```

---

### Example 3: No Credentials Found

```
SUMMARY:

 [-] CURRENT USER (Admin): NOT CONFIGURED
 [-] SYSTEM ACCOUNT (Standard): NOT CONFIGURED
 [-] SYSTEM ACCOUNT (PsExec): NOT CONFIGURED

Status: No Service Accounts are configured

What this means:
  - You MUST provide a JSON file for first-time setup
  - Place the Service Account JSON file in the script directory
  - Run your Rubrik script to configure

Steps to configure:
  1. Download Service Account JSON from Rubrik Security Cloud
     - Login to your Rubrik Security Cloud console
     - Go to: Settings -> Service Accounts -> Create/Download

  2. Place JSON file in your script directory
     Example: C:\Scripts\service-account-12345.json

  3. Run your Rubrik snapshot/backup script
```

---

## Interactive Deletion Menu

After displaying the credential status, the script presents an interactive menu for credential management:

### Menu Example

```
==========================================================
 CREDENTIAL DELETION MENU
==========================================================

Found 2 credential file(s):

  [1] CURRENT USER (John Doe)
      C:\Users\John Doe\Documents\WindowsPowerShell\rubrik-powershell-sdk\rsc_service_account_default.xml

  [2] SYSTEM ACCOUNT (Standard)
      C:\Windows\System32\config\systemprofile\Documents\WindowsPowerShell\rubrik-powershell-sdk\rsc_service_account_default.xml

  [A] Delete ALL credential files
  [0] Exit WITHOUT deleting anything

Select an option:
```

### Menu Options

| Option | Action | Confirmation Required |
|--------|--------|----------------------|
| **1, 2, 3...** | Delete specific credential file | Type `YES` |
| **A** | Delete all found credential files | Type `DELETE ALL` |
| **0** | Exit without deleting anything | None |

### Deletion Example - Single File

```
Select an option: 1

You selected: CURRENT USER (John Doe)

WARNING: This will permanently delete the credential file!
Type 'YES' to confirm deletion, or anything else to cancel: YES

Attempting to delete: CURRENT USER (John Doe)
Location: C:\Users\John Doe\Documents\WindowsPowerShell\rubrik-powershell-sdk\rsc_service_account_default.xml
 [+] Successfully deleted

Credential file deleted.
```

### Deletion Example - All Files

```
Select an option: A

WARNING: You are about to delete ALL 2 credential file(s)!

  - CURRENT USER (John Doe)
  - SYSTEM ACCOUNT (Standard)

Type 'DELETE ALL' to confirm, or anything else to cancel: DELETE ALL

Attempting to delete: CURRENT USER (John Doe)
Location: C:\Users\John Doe\Documents\WindowsPowerShell\rubrik-powershell-sdk\rsc_service_account_default.xml
 [+] Successfully deleted

Attempting to delete: SYSTEM ACCOUNT (Standard)
Location: C:\Windows\System32\config\systemprofile\Documents\WindowsPowerShell\rubrik-powershell-sdk\rsc_service_account_default.xml
 [+] Successfully deleted

Summary: Deleted 2 of 2 credential file(s)
```

### Permission Denied Example

```
Attempting to delete: SYSTEM ACCOUNT (Standard)
Location: C:\Windows\System32\config\systemprofile\Documents\WindowsPowerShell\rubrik-powershell-sdk\rsc_service_account_default.xml
 [-] ERROR: Access to the path '...' is denied.
     TIP: Run PowerShell as Administrator to delete SYSTEM credentials
```

---

## Understanding SYSTEM Account Types

### SYSTEM (Standard)
- **Created by:** Running scripts directly as SYSTEM or via scheduled tasks
- **Location:** `C:\Windows\System32\config\systemprofile\Documents\`
- **Used by:** 
  - Windows Task Scheduler tasks running as SYSTEM
  - Services running as SYSTEM
  - Direct SYSTEM context execution

### SYSTEM (PsExec)
- **Created by:** Using PsExec to elevate to SYSTEM context
- **Location:** `C:\Windows\SysWOW64\config\systemprofile\Documents\`
- **Used by:**
  - Scripts executed via `PsExec.exe -s powershell.exe script.ps1`
  - 32-bit processes running in WOW64 subsystem

### When to Use Each

| Scenario | Required Credentials |
|----------|---------------------|
| Manual script execution | Current User |
| Scheduled task (normal) | SYSTEM (Standard) |
| PsExec SYSTEM execution | SYSTEM (PsExec) |
| Both manual + scheduled | Current User + SYSTEM (Standard) |

### Do You Need Both SYSTEM Types?

**Usually NO.** Most users only need one:
- If you use **Task Scheduler**: Configure SYSTEM (Standard)
- If you use **PsExec**: Configure SYSTEM (PsExec)

Having both is redundant unless you specifically use both execution methods.

---

## Troubleshooting

### Issue: "Module NOT installed"

**Problem:** RubrikSecurityCloud PowerShell module is not installed.

**Solution:**
```powershell
# Install for current user
Install-Module -Name RubrikSecurityCloud -Scope AllUsers

# OR install for all users (requires admin)
Install-Module -Name RubrikSecurityCloud -Scope AllUsers
```

---

### Issue: "CREDENTIALS NOT FOUND" for Current User

**Problem:** No encrypted credentials exist for the current user.

**Solution:**
1. Download Service Account JSON from Rubrik Security Cloud:
   - Login to your Rubrik Security Cloud console
   - Navigate to Settings → Service Accounts
   - Create or download an existing Service Account JSON file

2. Place the JSON file in your script directory:
   ```
   C:\Scripts\service-account-12345.json
   ```

3. Run any Rubrik script that connects to RSC:
   ```powershell
   # The script will automatically detect and encrypt the JSON
   .\Your-Rubrik-Script.ps1 -SlaName "Gold"
   ```

---

### Issue: "Access Denied" When Deleting SYSTEM Credentials

**Problem:** Insufficient permissions to delete SYSTEM credential files.

**Solution:**
1. Close PowerShell
2. Right-click PowerShell and select "Run as Administrator"
3. Run the script again:
   ```powershell
   cd C:\Scripts
   .\Check-RscServiceAccountStatus.ps1
   ```

---

### Issue: PsExec Not Detected

**Problem:** Script shows "PsExec NOT found" even though you use it.

**Solution:**
1. Download PsExec from Microsoft Sysinternals:
   - https://docs.microsoft.com/en-us/sysinternals/downloads/psexec

2. Place `PsExec.exe` or `PsExec64.exe` in the same directory as the script:
   ```
   C:\Scripts\
   ├── Check-RscServiceAccountStatus.ps1
   └── PsExec.exe
   ```

3. Run the script again - it will now check the PsExec location

---

### Issue: Menu Shows Empty Choices

**Problem:** Credential deletion menu displays numbered options but no names.

**Solution:** This was a known issue in early versions. Ensure you have version 1.0 or later:
```powershell
# Check version in script header
Get-Content .\Check-RscServiceAccountStatus.ps1 | Select-String "Version:"
```

---

### Issue: Scheduled Task Still Fails After Configuring SYSTEM Credentials

**Problem:** Scheduled task reports authentication errors despite SYSTEM credentials being present.

**Possible Causes:**
1. **Wrong SYSTEM location:** Task is using System32 but credentials are in SysWOW64 (or vice versa)
2. **Credentials expired:** Service Account was revoked or expired in Rubrik Security Cloud
3. **PowerShell version mismatch:** Task runs PowerShell 7 but credentials are in PowerShell 5.1 location

**Solution:**
```powershell
# 1. Verify which location is needed
# Run as SYSTEM using PsExec to test:
PsExec.exe -s powershell.exe

# 2. Inside SYSTEM context, check which path is active:
$PROFILE
# This shows whether it's System32 or SysWOW64

# 3. Reconfigure credentials in the correct location
# Place JSON file and run your Rubrik script as SYSTEM

# 4. Verify credentials exist in the correct location
.\Check-RscServiceAccountStatus.ps1
```

---

## FAQ

### Q: What is this script used for?

**A:** This script helps you verify and manage encrypted Rubrik Security Cloud Service Account credentials across different execution contexts (manual vs. scheduled tasks).

---

### Q: Do I need administrator privileges to run this script?

**A:** 
- **No** - To check current user credentials
- **Yes** - To check or delete SYSTEM credentials (requires "Run as Administrator")

---

### Q: Will this script delete my credentials automatically?

**A:** No. The script only displays credential status. Deletion is optional and requires explicit confirmation via the interactive menu.

---

### Q: What happens if I delete credentials?

**A:** Scripts that rely on encrypted credentials will fail and prompt for a JSON Service Account file on next execution. You can reconfigure by:
1. Placing a Service Account JSON file in the script directory
2. Running your Rubrik script again

---

### Q: Can I run this script on a schedule?

**A:** Yes, but it's designed for interactive use. For automated monitoring, consider redirecting output:
```powershell
.\Check-RscServiceAccountStatus.ps1 > credential-status.log
```

However, the interactive deletion menu will not work in non-interactive sessions.

---

### Q: Why do I have credentials in multiple SYSTEM locations?

**A:** This happens when you configure credentials using different methods:
- **System32**: Created by running as SYSTEM via Task Scheduler or services
- **SysWOW64**: Created by running as SYSTEM via PsExec

Usually, you only need one. The script will recommend which to keep.

---

### Q: How do I create Service Account credentials?

**A:** 
1. Login to your Rubrik Security Cloud console
2. Navigate to: Settings → Service Accounts
3. Click "Create Service Account" or download existing
4. Save the JSON file
5. Place it in your script directory
6. Run your Rubrik script - it will automatically encrypt and store the credentials

---

### Q: Is this script safe to use?

**A:** Yes. The script:
- Only reads credential files (never modifies them automatically)
- Requires explicit confirmation before deletion
- Does not transmit any data outside your system
- Does not log or store sensitive information
- Is open source and can be audited

---

### Q: What if I accidentally delete my credentials?

**A:** Simply reconfigure by placing your Service Account JSON file back in the script directory and running any Rubrik script. The credentials will be re-encrypted and stored.

---

### Q: Does this work with PowerShell Core (7+)?

**A:** Yes. The script automatically detects PowerShell version and checks the appropriate credential locations for both Windows PowerShell 5.1 and PowerShell 7+.

---

### Q: Can I check credentials on remote computers?

**A:** Not directly. This script is designed to run locally. For remote checking, you would need to:
```powershell
# Use PowerShell remoting
Enter-PSSession -ComputerName RemotePC
cd C:\Scripts
.\Check-RscServiceAccountStatus.ps1
Exit-PSSession
```

---

## License

This script is provided as-is under the MIT License. See the repository for full license terms.

---

## Contributing

Contributions, issues, and feature requests are welcome!

**Repository:** https://github.com/mbriotto/rubrik-scripts

**Issues:** https://github.com/mbriotto/rubrik-scripts/issues

---

## Changelog

### Version 1.0 (January 2026) - Initial Release

**Features:**
- Check RubrikSecurityCloud module installation status
- Check encrypted credentials for CURRENT USER
- Check encrypted credentials for SYSTEM account (standard location)
- Check encrypted credentials for SYSTEM via PsExec (if PsExec detected)
- Interactive deletion menu for credential management
- Detailed credential file information (size, dates, location)
- Contextual recommendations based on configuration status
- Safety confirmations before deletion
- Administrator privilege detection

---

## Support

For questions, issues, or support:

1. **GitHub Issues:** https://github.com/mbriotto/rubrik-scripts/issues
2. **Rubrik Documentation:** https://docs.rubrik.com
3. **Rubrik Community:** https://community.rubrik.com

---

**Last Updated:** January 2026  
**Script Version:** 1.0
