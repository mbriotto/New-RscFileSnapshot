# New-RscFileSnapshot.ps1

PowerShell script for executing on-demand Rubrik Security Cloud Fileset snapshots with automatic Service Account configuration and comprehensive logging.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)

---

## Overview

`New-RscFileSnapshot.ps1` is the core snapshot execution script that connects to Rubrik Security Cloud, identifies your filesets, and initiates on-demand backups. The script features automatic module installation, automatic Service Account configuration, intelligent host/fileset detection, and comprehensive logging.

**Version**: 1.1 - Module Auto-Installation Update

---

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Parameters](#parameters)
- [Service Account Configuration](#service-account-configuration)
- [Running as SYSTEM Account (Task Scheduler)](#running-as-system-account-task-scheduler)
- [Logging](#logging)
- [Usage Examples](#usage-examples)
- [How It Works](#how-it-works)
- [Troubleshooting](#troubleshooting)
- [Integration](#integration)
- [FAQ](#faq)

---

## Features

### ✅ Automatic Module Management
- **Auto-detection**: Checks if RubrikSecurityCloud module is installed
- **Auto-installation**: Installs module automatically if missing
- **SYSTEM account support**: Works seamlessly when run by Task Scheduler as SYSTEM
- **Version verification**: Displays loaded module version for troubleshooting

### ✅ Automatic Service Account Configuration
- **First-run detection**: Automatically finds JSON files in script directory
- **Credential encryption**: Calls `Set-RscServiceAccountFile` to create encrypted credentials
- **Secure cleanup**: Deletes JSON file after encryption for security
- **Subsequent runs**: Uses encrypted credentials automatically

### ✅ Intelligent Host Detection
- **Auto-detection**: Uses local FQDN if `-HostName` not specified
- **Cluster IP extraction**: Automatically extracts cluster IP from host's CdmLink
- **Connectivity testing**: Optional ping verification before snapshot

### ✅ Flexible Fileset Selection
- **Exact match**: Specify exact fileset name
- **Wildcard support**: Use patterns like `User*` to match fileset names
- **Fallback**: Automatically selects first fileset if not specified

### ✅ Comprehensive Logging
- **Optional file logging**: Enable/disable via parameter
- **Timestamped logs**: Each run creates a new log file
- **Automatic cleanup**: Configurable retention period (default 30 days)
- **Detailed information**: Connection status, host/fileset details, snapshot results

### ✅ Error Handling
- **Graceful failures**: Comprehensive error messages
- **Safe disconnect**: Always disconnects from RSC properly
- **Exit codes**: 0 for success, 1 for errors

---

## Prerequisites

### 1. Rubrik PowerShell SDK

**The script automatically installs the module if missing**, but you can install it manually:

```powershell
# Manual installation (optional - script handles this automatically)
Install-Module -Name RubrikSecurityCloud -Scope CurrentUser

# Or for all users (requires admin rights)
Install-Module -Name RubrikSecurityCloud -Scope AllUsers
```

Verify:
```powershell
Get-Module -ListAvailable RubrikSecurityCloud
```

**For Task Scheduler / SYSTEM account:**
- The module will be automatically installed on first run
- No manual installation required
- Works seamlessly with scheduled tasks

### 2. Rubrik Service Account

You need a Service Account JSON file from Rubrik Security Cloud with minimum permissions:
- Fileset: Read, On-Demand Backup
- SLA Domain: Read
- Host: Read
- Cluster: Read

**See**: [New-RscServiceAccount.ps1](New-RscServiceAccount.ps1-README.md) for guided creation

### 3. System Requirements

- PowerShell 5.1 or higher
- Windows 10/11 or Windows Server 2016+
- Network access to Rubrik Security Cloud
- Network access to Rubrik cluster (for connectivity check)

---

## Installation

### Option 1: Clone Repository

```powershell
git clone https://github.com/mbriotto/rubrik-scripts.git
cd rubrik-scripts
```

### Option 2: Direct Download

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/mbriotto/rubrik-scripts/main/New-RscFileSnapshot.ps1" -OutFile "New-RscFileSnapshot.ps1"
```

### Option 3: Complete Setup

```powershell
# 1. Initialize environment
.\Initialize-RubrikEnvironment.cmd

# 2. Create Service Account (interactive guide)
.\New-RscServiceAccount.ps1 -ServiceAccountName 'FilesetBackup'

# 3. Download JSON from RSC and place in script directory

# 4. Ready to use!
.\New-RscFileSnapshot.ps1 -SlaName 'Gold'
```

---

## Quick Start

### Display Help

```powershell
.\New-RscFileSnapshot.ps1 -Help
.\New-RscFileSnapshot.ps1 -?
```

### Minimal Usage (First Run)

```powershell
# 1. Ensure Service Account JSON file is in script directory
# 2. Run snapshot:

.\New-RscFileSnapshot.ps1 -SlaName 'Gold'
```

**What happens:**
1. ✅ Script detects JSON file
2. ✅ Calls `Set-RscServiceAccountFile` to encrypt credentials
3. ✅ Deletes JSON file for security
4. ✅ Uses local FQDN as hostname
5. ✅ Selects first available fileset
6. ✅ Applies 'Gold' SLA policy
7. ✅ Initiates snapshot
8. ✅ Creates log file (if logging enabled)

### Subsequent Runs

```powershell
# No JSON file needed - uses encrypted credentials
.\New-RscFileSnapshot.ps1 -SlaName 'Gold'
```

---

## Parameters

### Required Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `-SlaName` | String | **REQUIRED**. Name of the SLA policy to apply |

### Optional Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-HostName` | String | Local FQDN | Name of the host in Rubrik |
| `-OsType` | String | `Windows` | Operating system (`Windows` or `Linux`) |
| `-FilesetName` | String | First fileset | Name of fileset (supports wildcards) |
| `-Credential` | PSCredential | - | Credentials for Connect-Rsc |
| `-SkipConnectivityCheck` | String | `No` | Skip ping test (`Yes` or `No`) |
| `-EnableFileLog` | String | `Yes` | Enable file logging (`Yes` or `No`) |
| `-LogFilePath` | String | `$PSScriptRoot\Logs` | Path to log folder |
| `-LogRetentionDays` | Int | `30` | Days to retain logs (1-365) |
| `-Help` / `-?` | Switch | - | Display help and exit |

---

## Service Account Configuration

### First-Time Setup

The script automatically configures Service Account credentials on first run:

```powershell
# Step 1: Download Service Account JSON from RSC
# Step 2: Place JSON file in script directory

C:\Scripts\Rubrik\
├── New-RscFileSnapshot.ps1
└── service-account-rk12345.json  ← Place here

# Step 3: Run script
.\New-RscFileSnapshot.ps1 -SlaName 'Gold'
```

**Automatic Process:**

```
1. Script detects *.json file in directory
   │
   ├─→ If multiple JSON files: Prompts for selection
   └─→ If single JSON file: Uses it automatically

2. Calls Set-RscServiceAccountFile
   │
   └─→ Creates encrypted credential file:
       %USERPROFILE%\Documents\WindowsPowerShell\
       rubrik-powershell-sdk\rsc_service_account_default.xml

3. Deletes original JSON file for security

4. Proceeds with snapshot using encrypted credentials
```

### Credential Storage

**Location (Windows):**
```
%USERPROFILE%\Documents\WindowsPowerShell\rubrik-powershell-sdk\rsc_service_account_default.xml
```

**Location (SYSTEM account):**
```
C:\Windows\System32\config\systemprofile\Documents\WindowsPowerShell\rubrik-powershell-sdk\rsc_service_account_default.xml
```

**Security:**
- Encrypted using Windows Data Protection API (DPAPI)
- User-specific (cannot be decrypted by other users)
- Cannot be transferred between systems

### Verification

```powershell
# Check if credentials exist
$encPath = Join-Path (Split-Path $PROFILE) "rubrik-powershell-sdk\rsc_service_account_default.xml"
Test-Path $encPath

# View file properties
Get-Item $encPath | Select-Object FullName, Length, CreationTime, LastWriteTime

# Test connection
Connect-Rsc
Get-RscCluster
Disconnect-Rsc
```

---

## Running as SYSTEM Account (Task Scheduler)

### Understanding SYSTEM Account Execution

When the script runs via Task Scheduler with the SYSTEM account, it operates in a different user context with its own profile and module paths.

### Automatic Module Installation

The script automatically handles module installation for SYSTEM account:

```
First Run as SYSTEM:
1. Script detects RubrikSecurityCloud module is missing
2. Automatically installs module for CurrentUser (SYSTEM's profile)
3. Imports the module
4. Continues with snapshot execution

Subsequent Runs:
1. Script finds module already installed
2. Imports the module
3. Continues with snapshot execution
```

### SYSTEM Profile Locations

**Module Path:**
```
C:\Windows\System32\config\systemprofile\Documents\WindowsPowerShell\Modules\
```

**Credentials Path:**
```
C:\Windows\System32\config\systemprofile\Documents\WindowsPowerShell\rubrik-powershell-sdk\rsc_service_account_default.xml
```

### Initial Setup for SYSTEM Account

You have two options for initial setup:

#### Option A: Let the Scheduled Task Handle Everything (Recommended)

```powershell
# 1. Create scheduled task normally
.\New-RscFileSnapshotScheduler.ps1 -SlaName 'Gold'

# 2. Place Service Account JSON in script directory
Copy-Item "service-account-*.json" "C:\Scripts\Rubrik\"

# 3. Run the scheduled task manually once (or wait for first scheduled run)
# The script will:
#   - Auto-install RubrikSecurityCloud module for SYSTEM
#   - Configure Service Account credentials for SYSTEM
#   - Delete the JSON file
#   - Execute the snapshot
```

#### Option B: Manual Configuration as SYSTEM

```powershell
# 1. Download PsExec from Microsoft Sysinternals
# https://learn.microsoft.com/en-us/sysinternals/downloads/psexec

# 2. Open PowerShell as Administrator and run:
.\PsExec64.exe -i -s powershell.exe

# 3. In the SYSTEM PowerShell window:
cd C:\Scripts\Rubrik

# 4. Verify module installation (script does this automatically, but you can check):
Get-Module -ListAvailable RubrikSecurityCloud

# 5. Run the script once to configure credentials:
.\New-RscFileSnapshot.ps1 -SlaName 'Gold'
# This will:
#   - Install module if missing
#   - Configure Service Account from JSON
#   - Test the connection

# 6. Exit SYSTEM PowerShell
exit
```

### Verification

Check if everything is configured correctly for SYSTEM account:

```powershell
# Use PsExec to check as SYSTEM
.\PsExec64.exe -i -s powershell.exe

# In SYSTEM PowerShell:
# Check module
Get-Module -ListAvailable RubrikSecurityCloud

# Check credentials
$credPath = "C:\Windows\System32\config\systemprofile\Documents\WindowsPowerShell\rubrik-powershell-sdk\rsc_service_account_default.xml"
Test-Path $credPath

# Test connection
Import-Module RubrikSecurityCloud
Connect-Rsc
Get-RscCluster
Disconnect-Rsc
```

### Troubleshooting SYSTEM Execution

**Issue: Module not found when running as SYSTEM**
- **Solution**: The script now auto-installs. If manual installation needed:
  ```powershell
  # As SYSTEM (using PsExec):
  Install-Module RubrikSecurityCloud -Scope CurrentUser -Force
  ```

**Issue: Credentials work for your user but not for SYSTEM**
- **Solution**: Credentials are user-specific. Configure separately for SYSTEM using one of the options above.

**Issue: Script works manually but fails in scheduled task**
- **Checklist**:
  1. ✅ Task configured to run as SYSTEM
  2. ✅ Service Account JSON placed in script directory for first run
  3. ✅ Script has auto-installed module (check first run logs)
  4. ✅ Encrypted credentials created in SYSTEM profile
  5. ✅ Check log files for detailed error messages

---

## Logging

### Log File Structure

**Default location**: `$PSScriptRoot\Logs\`

**File naming**: `New-RscFileSnapshot_YYYYMMDD_HHmmss.log`

**Example**: `New-RscFileSnapshot_20260120_143052.log`

### Log Content

```
================================================================================
Script started: 2026-01-20 14:30:52
Parameters:
  HostName: FILESRV01.domain.com
  OsType: Windows
  SlaName: Gold
  FilesetName: (auto-select first)
  SkipConnectivityCheck: No
  EnableFileLog: Yes
  LogFilePath: C:\Scripts\Rubrik\Logs
  LogRetentionDays: 30
================================================================================

[2026-01-20 14:30:52] [INFO] Connecting to Rubrik RSC...
[2026-01-20 14:30:54] [INFO] Connected to Rubrik cluster: Production-Cluster
[2026-01-20 14:30:54] [INFO] Searching for host 'FILESRV01.domain.com' (OsType: Windows)...
[2026-01-20 14:30:55] [INFO] Host found: FILESRV01.domain.com
[2026-01-20 14:30:55] [INFO] Extracting cluster IP from host's CdmLink...
[2026-01-20 14:30:55] [INFO] Cluster IP extracted from CdmLink: 192.168.1.100
[2026-01-20 14:30:55] [INFO] Testing connectivity to 192.168.1.100...
[2026-01-20 14:30:56] [INFO] Rubrik cluster reachable.
[2026-01-20 14:30:56] [WARN] FilesetName not specified: falling back to first Fileset 'UserProfiles'.
[2026-01-20 14:30:56] [INFO] Fileset selected: UserProfiles
[2026-01-20 14:30:57] [INFO] SLA selected: Gold
[2026-01-20 14:30:57] [INFO] Starting snapshot creation...
[2026-01-20 14:30:57] [INFO] Initiating snapshot for Fileset 'UserProfiles'...
[2026-01-20 14:31:00] [INFO] Snapshot initiated successfully. AsyncRequest ID: 12345678-90ab-cdef-1234-567890abcdef
[2026-01-20 14:31:01] [INFO] Disconnection from Rubrik completed.

================================================================================
Script completed: 2026-01-20 14:31:01
Result: SUCCESS
================================================================================
```

### Log Rotation

**Automatic cleanup**: Old logs are deleted based on retention period

```powershell
# Default: 30 days
.\New-RscFileSnapshot.ps1 -SlaName 'Gold'

# Custom retention: 7 days
.\New-RscFileSnapshot.ps1 -SlaName 'Gold' -LogRetentionDays 7

# Custom retention: 90 days
.\New-RscFileSnapshot.ps1 -SlaName 'Gold' -LogRetentionDays 90
```

### Disable Logging

```powershell
.\New-RscFileSnapshot.ps1 -SlaName 'Gold' -EnableFileLog No
```

---

## Usage Examples

### Example 1: Local Host, Auto-Select Fileset

```powershell
# Uses local FQDN, first available fileset
.\New-RscFileSnapshot.ps1 -SlaName 'Gold'
```

---

### Example 2: Specific Host and Fileset

```powershell
.\New-RscFileSnapshot.ps1 `
    -HostName 'FILESRV01' `
    -SlaName 'Gold' `
    -FilesetName 'UserProfiles'
```

---

### Example 3: Linux Host with Wildcard Fileset

```powershell
.\New-RscFileSnapshot.ps1 `
    -HostName 'ubuntu-web01' `
    -OsType Linux `
    -SlaName 'Silver' `
    -FilesetName '/var/www*'
```

---

### Example 4: Skip Connectivity Check

```powershell
# Useful when cluster is behind firewall/VPN
.\New-RscFileSnapshot.ps1 `
    -SlaName 'Gold' `
    -SkipConnectivityCheck Yes
```

---

### Example 5: Custom Log Location

```powershell
.\New-RscFileSnapshot.ps1 `
    -SlaName 'Gold' `
    -LogFilePath 'C:\Logs\Rubrik' `
    -LogRetentionDays 90
```

---

### Example 6: No Logging

```powershell
.\New-RscFileSnapshot.ps1 `
    -SlaName 'Gold' `
    -EnableFileLog No
```

---

### Example 7: With Explicit Credentials

```powershell
$cred = Get-Credential

.\New-RscFileSnapshot.ps1 `
    -SlaName 'Gold' `
    -Credential $cred
```

---

## How It Works

### Execution Flow

```
START
  │
  ├─→ Parse parameters (validate SlaName required)
  │
  ├─→ Set HostName (use local FQDN if not specified)
  │
  ├─→ Initialize logging (if enabled)
  │
  ├─→ Clean old logs (based on retention period)
  │
  ├─→ Check for Service Account configuration
  │   │
  │   ├─→ If encrypted credentials exist:
  │   │   └─→ Use existing credentials
  │   │
  │   └─→ If no encrypted credentials:
  │       ├─→ Search for *.json files
  │       ├─→ Select JSON file (prompt if multiple)
  │       ├─→ Call Set-RscServiceAccountFile
  │       ├─→ Delete JSON file
  │       └─→ Log configuration complete
  │
  ├─→ Connect to Rubrik RSC
  │   └─→ Connect-Rsc (with optional credentials)
  │
  ├─→ Get cluster information
  │   └─→ Get-RscCluster
  │
  ├─→ Retrieve host
  │   └─→ Get-RscHost -OsType <type> -Name <hostname>
  │
  ├─→ Extract cluster IP from host's CdmLink
  │   └─→ Parse URI from CdmLink property
  │
  ├─→ Test cluster connectivity (unless skipped)
  │   └─→ Test-Connection -ComputerName <clusterIP>
  │
  ├─→ Get filesets for host
  │   └─→ Get-RscFileset
  │
  ├─→ Select fileset
  │   ├─→ If FilesetName specified:
  │   │   ├─→ Try exact match
  │   │   └─→ Try wildcard match
  │   └─→ If not specified: use first fileset
  │
  ├─→ Get SLA policy
  │   └─→ Get-RscSla -Name <SlaName>
  │
  ├─→ Create snapshot
  │   ├─→ New-RscMutation -GqlMutation createFilesetSnapshot
  │   ├─→ Set input parameters (fileset ID, SLA ID)
  │   └─→ Invoke mutation
  │
  ├─→ Log results
  │   └─→ Write summary and AsyncRequest ID
  │
  ├─→ Disconnect from RSC
  │   └─→ Disconnect-Rsc
  │
  └─→ Display execution summary
      └─→ Host, Fileset, SLA, Cluster IP, AsyncRequest ID, Log file
```

### GraphQL Mutation

The script uses the following GraphQL mutation:

```graphql
mutation createFilesetSnapshot($input: CreateFilesetSnapshotInput!) {
  createFilesetSnapshot(input: $input) {
    id
  }
}
```

**Input:**
```json
{
  "input": {
    "id": "Fileset-12345678-90ab-cdef-1234-567890abcdef",
    "config": {
      "slaId": "SLA-12345678-90ab-cdef-1234-567890abcdef"
    }
  }
}
```

**Output:**
```json
{
  "data": {
    "createFilesetSnapshot": {
      "id": "AsyncRequest-12345678-90ab-cdef-1234-567890abcdef"
    }
  }
}
```

---

## Troubleshooting

### Issue: "Parameter -SlaName is required"

**Problem**: Script was run without specifying SLA

**Solution**:
```powershell
.\New-RscFileSnapshot.ps1 -SlaName 'Gold'
```

---

### Issue: "No JSON files found" but credentials don't exist

**Problem**: First-time run without Service Account JSON

**Solution**:
```powershell
# 1. Download Service Account JSON from RSC
# 2. Copy to script directory
Copy-Item "C:\Downloads\service-account-rk12345.json" "C:\Scripts\Rubrik\"

# 3. Run script again
.\New-RscFileSnapshot.ps1 -SlaName 'Gold'
```

---

### Issue: "Host 'HOSTNAME' not found"

**Problem**: Hostname doesn't match what's in Rubrik

**Solutions**:

```powershell
# Option 1: Check exact hostname in Rubrik
# Login to RSC → Hosts → Copy exact name

# Option 2: Try FQDN
.\New-RscFileSnapshot.ps1 -HostName 'server01.domain.com' -SlaName 'Gold'

# Option 3: Try short name
.\New-RscFileSnapshot.ps1 -HostName 'SERVER01' -SlaName 'Gold'

# Option 4: Check OS type
.\New-RscFileSnapshot.ps1 -HostName 'linuxserver' -OsType Linux -SlaName 'Gold'
```

---

### Issue: "Fileset 'NAME' not found"

**Problem**: Fileset name doesn't match or multiple matches

**Solutions**:

```powershell
# Option 1: Let script auto-select first fileset
.\New-RscFileSnapshot.ps1 -SlaName 'Gold'  # Don't specify -FilesetName

# Option 2: Use exact fileset name
.\New-RscFileSnapshot.ps1 -SlaName 'Gold' -FilesetName 'UserProfiles'

# Option 3: Use wildcard
.\New-RscFileSnapshot.ps1 -SlaName 'Gold' -FilesetName 'User*'
```

---

### Issue: "SLA 'NAME' not found"

**Problem**: SLA name doesn't exist or is misspelled

**Solution**:
```powershell
# Check available SLAs in Rubrik:
Connect-Rsc
Get-RscSla | Select-Object Name
Disconnect-Rsc

# Use exact name
.\New-RscFileSnapshot.ps1 -SlaName 'Gold'
```

---

### Issue: "Rubrik cluster NOT reachable"

**Problem**: Cannot ping cluster IP

**Solutions**:

```powershell
# Option 1: Skip connectivity check
.\New-RscFileSnapshot.ps1 -SlaName 'Gold' -SkipConnectivityCheck Yes

# Option 2: Verify network connectivity
# Check if cluster is accessible via browser/ping manually

# Option 3: Check firewall rules
# Ensure ICMP (ping) is allowed to cluster
```

---

### Issue: Credentials work for current user but not for scheduled tasks

**Problem**: Encrypted credentials are user-specific

**Solution**: See the dedicated section: [Running as SYSTEM Account (Task Scheduler)](#running-as-system-account-task-scheduler)

The script now automatically handles module installation and credential configuration for SYSTEM account. Simply:
1. Place the Service Account JSON in the script directory
2. Run the scheduled task once (manually or wait for schedule)
3. The script will auto-configure everything

For manual setup, see the detailed instructions in the SYSTEM Account section above.

---

## Integration

### Called by Task Scheduler

```xml
<!-- Task Scheduler XML fragment -->
<Actions>
  <Exec>
    <Command>PowerShell.exe</Command>
    <Arguments>
      -NoProfile -ExecutionPolicy Bypass
      -File "C:\Scripts\Rubrik\New-RscFileSnapshot.ps1"
      -SlaName "Gold"
      -EnableFileLog Yes
      -LogFilePath "C:\Logs\Rubrik"
    </Arguments>
  </Exec>
</Actions>
```

**See**: [New-RscFileSnapshotScheduler.ps1](New-RscFileSnapshotScheduler.ps1-README.md) for automated task creation

---

### Called by Custom Scripts

```powershell
# Example wrapper script

# Run snapshot and capture exit code
& "C:\Scripts\Rubrik\New-RscFileSnapshot.ps1" -SlaName 'Gold' -HostName 'FILESRV01'

if ($LASTEXITCODE -eq 0) {
    Write-Host "Snapshot successful!" -ForegroundColor Green
    # Send success email, update database, etc.
} else {
    Write-Host "Snapshot failed!" -ForegroundColor Red
    # Send alert email, create ticket, etc.
}
```

---

### PowerShell Remoting

```powershell
# Run snapshot on remote computer

$session = New-PSSession -ComputerName 'FILESRV01'

Invoke-Command -Session $session -ScriptBlock {
    param($SlaName)
    
    cd C:\Scripts\Rubrik
    .\New-RscFileSnapshot.ps1 -SlaName $SlaName
    
} -ArgumentList 'Gold'

Remove-PSSession $session
```

---

## FAQ

### Q: Do I need to provide the JSON file every time?

**A**: No! The JSON file is only needed on the **first run**. After that, the script uses encrypted credentials stored in your PowerShell profile directory.

---

### Q: Where are the encrypted credentials stored?

**A**: 
```
%USERPROFILE%\Documents\WindowsPowerShell\rubrik-powershell-sdk\rsc_service_account_default.xml
```

For PowerShell 7+:
```
%USERPROFILE%\Documents\PowerShell\rubrik-powershell-sdk\rsc_service_account_default.xml
```

---

### Q: Can I use the same credentials on multiple computers?

**A**: No. Encrypted credentials are user-specific and computer-specific due to Windows DPAPI. You must configure Service Account credentials separately on each computer.

---

### Q: How do I rotate Service Account credentials?

**A**:
```powershell
# 1. Delete existing encrypted credentials
$encPath = Join-Path (Split-Path $PROFILE) "rubrik-powershell-sdk\rsc_service_account_default.xml"
Remove-Item $encPath

# 2. Download new Service Account JSON from RSC

# 3. Place new JSON in script directory

# 4. Run script (will reconfigure automatically)
.\New-RscFileSnapshot.ps1 -SlaName 'Gold'
```

---

### Q: What happens to the JSON file after first run?

**A**: The script automatically **deletes** the JSON file for security after creating encrypted credentials. The original clear-text credentials are removed.

---

### Q: Can I specify a different SLA for each run?

**A**: Yes! The SLA is specified via parameter each time:

```powershell
.\New-RscFileSnapshot.ps1 -SlaName 'Gold'    # Run 1
.\New-RscFileSnapshot.ps1 -SlaName 'Silver'  # Run 2
.\New-RscFileSnapshot.ps1 -SlaName 'Bronze'  # Run 3
```

---

### Q: How do I backup multiple filesets?

**A**: Run the script multiple times with different fileset names:

```powershell
.\New-RscFileSnapshot.ps1 -SlaName 'Gold' -FilesetName 'UserProfiles'
.\New-RscFileSnapshot.ps1 -SlaName 'Gold' -FilesetName 'AppData'
.\New-RscFileSnapshot.ps1 -SlaName 'Silver' -FilesetName 'TempFiles'
```

Or create multiple scheduled tasks (see [New-RscFileSnapshotScheduler.ps1](New-RscFileSnapshotScheduler.ps1-README.md))

---

### Q: Can I run snapshots for multiple hosts?

**A**: Yes! Specify different hostnames:

```powershell
.\New-RscFileSnapshot.ps1 -HostName 'SERVER01' -SlaName 'Gold'
.\New-RscFileSnapshot.ps1 -HostName 'SERVER02' -SlaName 'Gold'
.\New-RscFileSnapshot.ps1 -HostName 'LINUXSRV' -OsType Linux -SlaName 'Silver'
```

---

### Q: How do I verify the snapshot was successful?

**A**: Check:

1. **Script output**: Shows AsyncRequest ID if successful
2. **Log file**: Contains detailed execution steps
3. **Rubrik Security Cloud**: Login → Activity → Filter by host/fileset
4. **Exit code**: `$LASTEXITCODE` is 0 for success, 1 for failure

---

### Q: What's the difference between this and New-RscFileSnapshotScheduler.ps1?

**A**: 
- **New-RscFileSnapshot.ps1**: Executes a single snapshot (manual or scheduled)
- **New-RscFileSnapshotScheduler.ps1**: Creates Windows Scheduled Tasks that call New-RscFileSnapshot.ps1 automatically

---

### Q: Can I run this script without logging?

**A**: Yes:
```powershell
.\New-RscFileSnapshot.ps1 -SlaName 'Gold' -EnableFileLog No
```

---

### Q: How do I change log retention?

**A**:
```powershell
# Keep logs for 7 days
.\New-RscFileSnapshot.ps1 -SlaName 'Gold' -LogRetentionDays 7

# Keep logs for 90 days
.\New-RscFileSnapshot.ps1 -SlaName 'Gold' -LogRetentionDays 90
```

---

## Exit Codes

- **0**: Success - Snapshot initiated successfully
- **1**: Failure - Error occurred (see log for details)

---

## Version History

### Version 1.1 (January 2026) - Module Auto-Installation Update

**New Features:**
- **Automatic module detection and installation**: Script now automatically checks for and installs RubrikSecurityCloud module if missing
- **SYSTEM account support**: Seamless operation when run by Task Scheduler as SYSTEM
- **Enhanced error handling**: Better error messages for module-related issues
- **Installation fallback**: Tries CurrentUser scope first, then AllUsers if needed

**Improvements:**
- Added `Initialize-RubrikModule` function for module management
- Enhanced documentation with dedicated SYSTEM account section
- Updated troubleshooting guide with module-specific solutions

### Version 1.0 (January 2026) - Initial Release

**Features:**
- On-demand Fileset snapshot execution
- Automatic Service Account configuration (JSON → encrypted XML)
- Intelligent host detection (auto-use local FQDN)
- Flexible fileset selection (exact, wildcard, or auto-select)
- Cluster IP auto-extraction from CdmLink
- Optional connectivity testing
- Comprehensive file logging with rotation
- Graceful error handling
- Safe RSC disconnection

---

## License

This program is free software: you can redistribute it and/or modify it under the terms of the **GNU General Public License v3.0** as published by the Free Software Foundation.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

---

## Author

**GitHub**: [@mbriotto](https://github.com/mbriotto)  
**Repository**: https://github.com/mbriotto/rubrik-scripts

---

## Related Scripts

- **New-RscServiceAccount.ps1**: Service Account creation guide
- **New-RscFileSnapshotScheduler.ps1**: Task scheduling automation
- **Check-RscServiceAccountStatus.ps1**: Credential verification

---

## Support

For issues and questions:

- **GitHub Issues**: https://github.com/mbriotto/rubrik-scripts/issues
- **Rubrik PowerShell SDK**: https://github.com/rubrikinc/rubrik-powershell-sdk
- **Rubrik Security Cloud Documentation**: https://docs.rubrik.com/
- **Rubrik Support**: https://support.rubrik.com/

---

**Last Updated**: January 2026  
**Script Version**: 1.1 - Module Auto-Installation Update
