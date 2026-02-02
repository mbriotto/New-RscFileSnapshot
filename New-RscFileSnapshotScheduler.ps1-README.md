# New-RscFileSnapshotScheduler.ps1

PowerShell script for creating Windows Scheduled Tasks to automate Rubrik Fileset snapshots.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)

## Overview

`New-RscFileSnapshotScheduler.ps1` automates the creation of Windows Scheduled Tasks that execute `New-RscFileSnapshot.ps1` at configurable intervals. The script supports boot-time execution with delays, recurring schedules, and intelligent duplicate prevention.

**NEW in v1.1**: Automatic SYSTEM account authentication verification and configuration!

### Key Features

- ✅ **Boot Execution**: Automatically runs snapshots after PC startup (configurable delay)
- ✅ **Recurring Schedule**: Execute at specific times and intervals (hourly to weekly)
- ✅ **Duplicate Prevention**: Avoids running at boot if already executed recently
- ✅ **Flexible Configuration**: All `New-RscFileSnapshot.ps1` parameters supported
- ✅ **Smart Defaults**: Works out-of-the-box with minimal configuration
- ✅ **Multiple Instances Protection**: Prevents overlapping executions
- ✅ **Comprehensive Validation**: Checks permissions, paths, and configuration
- ✅ **Administrator Privileges Check**: Ensures proper permissions before task creation
- ✅ **Automatic SYSTEM Authentication**: Verifies and configures RSC authentication for SYSTEM account

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage](#usage)
- [Parameters](#parameters)
- [Configuration Examples](#configuration-examples)
- [How It Works](#how-it-works)
- [Task Management](#task-management)
- [Troubleshooting](#troubleshooting)
- [Advanced Scenarios](#advanced-scenarios)

---

## Prerequisites

### 1. Windows Operating System

- Windows 10/11 or Windows Server 2016+
- PowerShell 5.1 or higher

### 2. Administrator Privileges

```powershell
# Check if running as Administrator
([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
```

### 3. Rubrik PowerShell SDK

```powershell
# IMPORTANT: Must use -Scope AllUsers for scheduled tasks to work
# SYSTEM account needs access to the module
Install-Module -Name RubrikSecurityCloud -Scope AllUsers
```

Verify installation:
```powershell
Get-Module -ListAvailable RubrikSecurityCloud
```

**Critical**: The module MUST be installed with `-Scope AllUsers` (not `CurrentUser`) for scheduled tasks to access it when running as SYSTEM account.

### 4. Service Account Credentials

You need to configure Rubrik Service Account credentials before running the scheduler.

**Important**: Service Account credentials must be configured for the SYSTEM account when using default task settings.

#### Automatic Configuration (Recommended - NEW in v1.1)

The scheduler script now **automatically handles SYSTEM account authentication**:

1. **Create Service Account in Rubrik**
   - Use [New-RscServiceAccount.ps1](New-RscServiceAccount.ps1-README.md) for guided creation
   - Or create manually in RSC web UI

2. **Download JSON credentials**
   - Download the Service Account JSON file from Rubrik Security Cloud

3. **Run the scheduler with JSON path**
   ```powershell
   # The script will automatically configure SYSTEM authentication
   .\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold" -ServiceAccountJsonPath "C:\Creds\rubrik.json"
   ```
   
   OR place the JSON file in the script directory:
   ```powershell
   # Script will auto-detect JSON file and configure authentication
   Copy-Item "C:\Downloads\service-account-*.json" $PSScriptRoot
   .\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold"
   ```

**What happens automatically**:
- Script verifies if SYSTEM account is authenticated
- If not authenticated, automatically configures it using the provided JSON
- Verifies authentication after configuration
- Creates the scheduled task only after successful authentication
- Task execution will work immediately without manual intervention

#### Manual Configuration (Legacy Method)

If you prefer to configure authentication manually or if automatic configuration fails:

```powershell
# 1. Run PowerShell as SYSTEM using PsExec
PsExec.exe -i -s powershell.exe

# 2. In the SYSTEM PowerShell session, configure authentication
Import-Module RubrikSecurityCloud
Set-RscServiceAccountFile -InputFilePath "C:\Path\To\service-account.json"

# 3. Test the connection
Connect-Rsc
Get-RscCluster
Disconnect-Rsc

# 4. Exit SYSTEM session and run the scheduler as your regular admin user
exit
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold"
```

**See also:** [New-RscServiceAccount.ps1](New-RscServiceAccount.ps1-README.md) for guided Service Account creation.

### 5. New-RscFileSnapshot.ps1

The main snapshot script must be accessible. By default, the scheduler looks in the same directory.

---

## Installation

### Method 1: Clone Repository

```powershell
git clone https://github.com/mbriotto/New-RscFileSnapshot.git
cd New-RscFileSnapshot
```

### Method 2: Download Scripts

```powershell
# Download scheduler
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/mbriotto/New-RscFileSnapshot/main/New-RscFileSnapshotScheduler.ps1" -OutFile "New-RscFileSnapshotScheduler.ps1"

# Download main script (if not already present)
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/mbriotto/New-RscFileSnapshot/main/New-RscFileSnapshot.ps1" -OutFile "New-RscFileSnapshot.ps1"
```

### Method 3: Complete Setup

```powershell
# 1. Install module
Install-Module -Name RubrikSecurityCloud -Scope AllUsers

# 2. Download scripts
git clone https://github.com/mbriotto/rubrik-scripts.git
cd rubrik-scripts

# 3. Create and configure Service Account
# Follow New-RscServiceAccount.ps1 guide to create Service Account in RSC

# 4. Download Service Account JSON from Rubrik Security Cloud

# 5. Place JSON file in script directory and configure credentials
Copy-Item "C:\Downloads\service-account-*.json" "."
.\New-RscFileSnapshot.ps1 -SlaName "Gold"  # Configures credentials, deletes JSON

# 6. Run scheduler to create automated task
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold"
```

---

## Quick Start

### View Help

```powershell
# Display help
.\New-RscFileSnapshotScheduler.ps1 -Help
# or
.\New-RscFileSnapshotScheduler.ps1 -?

# Running without parameters also shows help
.\New-RscFileSnapshotScheduler.ps1
```

### Default Configuration (Recommended) - NEW Simplified Process

```powershell
# 1. Run PowerShell as Administrator

# 2. First time setup - provide Service Account JSON:
.\New-RscFileSnapshotScheduler.ps1 `
    -SlaName "Gold" `
    -ServiceAccountJsonPath "C:\Downloads\service-account-rsc123.json"

# OR simply place JSON in script directory and run:
Copy-Item "C:\Downloads\service-account-*.json" .
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold"
```

**What happens automatically:**
1. ✅ Verifies script path and SLA parameter
2. ✅ Checks SYSTEM account authentication status
3. ✅ **Automatically configures SYSTEM authentication** if needed using the JSON file
4. ✅ Verifies authentication was successful
5. ✅ Creates scheduled task with:
   - Runs 15 minutes after PC startup
   - Runs daily at 2:00 AM
   - Prevents duplicate execution at boot if already run recently
   - Uses local hostname and first available Fileset
   - Executes as SYSTEM account with verified authentication

### Subsequent Task Creations

After initial setup, you can create additional tasks without providing the JSON again:

```powershell
# SYSTEM is already authenticated, no JSON needed
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Silver" -FilesetName "Archives*"
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Bronze" -RecurringTime "14:00"
```

### Important Note on Authentication

**NEW in v1.1**: Authentication is handled automatically!

- The script verifies SYSTEM account authentication status
- If not authenticated, it automatically configures it using the provided JSON file
- Authentication is verified before task creation
- You only need to provide the JSON file once during initial setup
- All subsequent scheduled tasks use the configured authentication

### Verify Task Creation

```powershell
Get-ScheduledTask -TaskName "Rubrik Fileset Backup - Auto" | Get-ScheduledTaskInfo
```

---

## Usage

### Display Help

```powershell
.\New-RscFileSnapshotScheduler.ps1 -Help
.\New-RscFileSnapshotScheduler.ps1 -?

# Running without parameters shows help and required parameter error
.\New-RscFileSnapshotScheduler.ps1
```

### Basic Syntax

```powershell
.\New-RscFileSnapshotScheduler.ps1 -SlaName <SLA> [OPTIONS]
```

**Note:** `-SlaName` is **REQUIRED**. A Service Account JSON file is also **REQUIRED**.

---

## Parameters

### Required Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `-SlaName` | String | SLA policy name for snapshots |

### Script Location Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-ScriptPath` | String | Same directory | Path to `New-RscFileSnapshot.ps1` |
| `-TaskName` | String | `Rubrik Fileset Backup - Auto` | Name of scheduled task |
| `-ServiceAccountJsonPath` | String | Auto-detect | Path to Service Account JSON file for SYSTEM authentication (NEW in v1.1) |

### Snapshot Parameters (Passed to New-RscFileSnapshot.ps1)

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-HostName` | String | Local FQDN | Target host name |
| `-OsType` | String | `Windows` | Operating system (`Windows` or `Linux`) |
| `-FilesetName` | String | First available | Fileset name (supports wildcards) |
| `-SkipConnectivityCheck` | String | `No` | Skip ping test (`Yes` or `No`) |

### Boot Execution Parameters

| Parameter | Type | Default | Range | Description |
|-----------|------|---------|-------|-------------|
| `-EnableBootExecution` | String | `Yes` | `Yes`/`No` | Run at PC startup |
| `-BootDelayMinutes` | Int | `15` | 1-1440 | Delay after boot in minutes |

### Recurring Schedule Parameters

| Parameter | Type | Default | Range | Description |
|-----------|------|---------|-------|-------------|
| `-EnableRecurringSchedule` | String | `Yes` | `Yes`/`No` | Enable recurring execution |
| `-RecurringTime` | String | `02:00` | HH:MM | Execution time (24-hour format) |
| `-RecurringIntervalHours` | Int | `24` | 1-168 | Interval in hours |

### Execution Control Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-PreventDuplicateExecution` | String | `Yes` | Prevent boot run if recently executed |
| `-RunAsUser` | String | `SYSTEM` | Account to run task (`SYSTEM` or `CurrentUser`) |

---

## Configuration Examples

### Example 1: Default Configuration (First Time Setup)

```powershell
# First time - provide JSON file (auto-configures SYSTEM authentication)
.\New-RscFileSnapshotScheduler.ps1 `
    -SlaName "Gold" `
    -ServiceAccountJsonPath "C:\Downloads\service-account-rsc123.json"
```

**Behavior:**
- ✅ Automatically verifies SYSTEM authentication
- ✅ Configures SYSTEM authentication using provided JSON
- ✅ Verifies authentication was successful
- ✅ Creates task: Runs 15 min after boot + daily at 2:00 AM
- ✅ Prevents duplicate at boot if already run recently

### Example 2: Auto-Detect JSON in Script Directory

```powershell
# Place JSON in script directory, script will auto-detect it
Copy-Item "C:\Downloads\service-account-*.json" $PSScriptRoot
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold"
```

**Behavior:**
- Script automatically finds and uses JSON file
- Configures SYSTEM authentication
- Creates task with default settings

### Example 3: Subsequent Task Creation (No JSON Needed)

```powershell
# After initial setup, SYSTEM is already authenticated
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Silver" -FilesetName "Archives*"
```

**Behavior:**
- Skips authentication setup (already configured)
- Creates new task using existing SYSTEM credentials
- Works immediately without manual intervention

### Example 4: Boot Only (No Recurring)

```powershell
.\New-RscFileSnapshotScheduler.ps1 `
    -SlaName "Gold" `
    -EnableRecurringSchedule No `
    -ServiceAccountJsonPath "C:\Creds\rubrik.json"
```

**Behavior:**
- Runs 15 minutes after boot
- No recurring schedule
- Useful for laptops that aren't always on

### Example 5: Recurring Only (No Boot)

```powershell
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold" -EnableBootExecution No
```

**Behavior:**
- Does NOT run at boot
- Runs daily at 2:00 AM
- Useful for servers with predictable uptime

### Example 6: Custom Boot Delay

```powershell
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold" -BootDelayMinutes 30
```

**Behavior:**
- Runs 30 minutes after boot (instead of 15)
- Runs daily at 2:00 AM
- Good for systems with slow startup

### Example 7: Every 12 Hours

```powershell
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Silver" -RecurringTime "14:00" -RecurringIntervalHours 12
```

**Behavior:**
- Runs 15 minutes after boot
- Runs at 2:00 PM and repeats every 12 hours (2:00 PM, 2:00 AM, 2:00 PM...)

### Example 8: Every 6 Hours (High Frequency)

```powershell
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Platinum" -RecurringTime "00:00" -RecurringIntervalHours 6
```

**Behavior:**
- Runs 15 minutes after boot
- Runs at midnight, 6 AM, noon, 6 PM (every 6 hours)

### Example 8: Allow Boot Duplicates

```powershell
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold" -PreventDuplicateExecution No
```

**Behavior:**
- Runs at boot AND at 2:00 AM (even if already run)
- Boot execution repeats every 24 hours

### Example 9: Specific Host and Fileset

```powershell
.\New-RscFileSnapshotScheduler.ps1 `
    -SlaName "Gold" `
    -HostName "FILESRV01" `
    -FilesetName "UserProfiles" `
    -RecurringTime "03:00"
```

**Behavior:**
- Targets specific host and Fileset
- Runs at 3:00 AM daily

### Example 10: Linux Server

```powershell
.\New-RscFileSnapshotScheduler.ps1 `
    -SlaName "Silver" `
    -HostName "ubuntu-server" `
    -OsType Linux `
    -FilesetName "home-*"
```

**Behavior:**
- Targets Linux host
- Uses wildcard Fileset matching

### Example 11: Custom Script Path and Task Name

```powershell
.\New-RscFileSnapshotScheduler.ps1 `
    -SlaName "Gold" `
    -ScriptPath "C:\Scripts\Rubrik\New-RscFileSnapshot.ps1" `
    -TaskName "Production DB Backup"
```

**Behavior:**
- Uses script from custom location
- Creates task with custom name

### Example 12: Run as Current User

```powershell
.\New-RscFileSnapshotScheduler.ps1 `
    -SlaName "Gold" `
    -RunAsUser CurrentUser
```

**Behavior:**
- Runs with current user's credentials instead of SYSTEM
- Useful for testing or user-specific configurations

---

## How It Works

### Execution Flow (NEW in v1.1 - 6 Steps with Automatic Authentication)

```
Step 1: Validate Environment
   ↓
   Check Administrator privileges
   ↓
   Verify script paths
   ↓
Step 2: Check SYSTEM Authentication Status (NEW)
   ↓
   Test if SYSTEM account can authenticate to RSC
   ↓
   Already authenticated? → Yes → Skip to Step 4
                        → No  → Continue to Step 3
   ↓
Step 3: Configure SYSTEM Authentication (NEW - Automatic)
   ↓
   Detect JSON file (auto-detect or specified path)
   ↓
   Create temporary setup script
   ↓
   Run setup as SYSTEM using scheduled task
   ↓
   Configure encrypted credentials for SYSTEM
   ↓
   Verify authentication successful
   ↓
Step 4: Build Command Arguments
   ↓
   Construct PowerShell command with parameters
   ↓
Step 5: Create Scheduled Task
   ↓
   Create boot trigger (if enabled)
   ↓
   Create recurring trigger (if enabled)
   ↓
   Configure task settings (battery, network, etc.)
   ↓
   Register task with SYSTEM principal
   ↓
Step 6: Apply Advanced Configuration
   ↓
   Configure boot delay via COM interface
   ↓
   Apply duplicate prevention settings
   ↓
Complete
```

### SYSTEM Authentication Configuration (NEW in v1.1)

The script now **automatically handles SYSTEM account authentication**:

```
JSON File Detection
   ↓
Check -ServiceAccountJsonPath parameter
   ↓ Not provided
Auto-detect *.json files in script directory
   ↓
File Found?
   ↓ Yes                    ↓ No
Continue              Show error + exit
   ↓
Test SYSTEM Authentication
   ↓
Create temporary test task as SYSTEM
   ↓
Try to Connect-Rsc and Get-RscCluster
   ↓
Already authenticated?
   ↓ Yes                    ↓ No
Skip configuration    Configure now
   ↓                        ↓
                    Create setup script
                    ↓
                    Run as SYSTEM via scheduled task
                    ↓
                    Set-RscServiceAccountFile
                    ↓
                    Wait for completion
                    ↓
                    Cleanup temporary files
   ↓
Verify Authentication
   ↓
Test SYSTEM authentication again
   ↓
Success?
   ↓ Yes                    ↓ No
Continue              Show manual steps + exit
   ↓
Create Scheduled Task
```

### Traditional Configuration Flow (Still Available)

If automatic configuration fails, you can still configure manually:

```
Manual Configuration (Legacy)
   ↓
Run PowerShell as SYSTEM (using PsExec)
   ↓
PsExec.exe -i -s powershell.exe
   ↓
In SYSTEM PowerShell session:
   ↓
Import-Module RubrikSecurityCloud
   ↓
Set-RscServiceAccountFile -InputFilePath "path\to\file.json"
   ↓
Connect-Rsc (to verify)
   ↓
Exit SYSTEM session
   ↓
Run scheduler as regular admin user
```

### Task Execution Flow (After Creation)

```
PC Boots
   ↓
Wait 15 minutes (configurable)
   ↓
Check: Has task run in last 24h?
   ↓ No                    ↓ Yes
Execute snapshot      Skip execution
   ↓
powershell.exe runs as SYSTEM
   ↓
Import RubrikSecurityCloud module
   ↓
Connect-Rsc (uses SYSTEM encrypted credentials automatically)
   ↓
Get-RscHost and Get-RscFileset
   ↓
New-RscFilesetSnapshot
   ↓
Snapshot created successfully
   ↓
Wait until 2:00 AM
   ↓
Execute snapshot again
   ↓
Wait 24 hours
   ↓
Repeat
```

### Duplicate Prevention Logic

When `PreventDuplicateExecution` is `Yes`:

1. **Boot trigger**: Runs once at boot (after delay), does NOT repeat
2. **Recurring trigger**: Handles all subsequent executions
3. **Result**: If PC boots at 1:00 PM and recurring is at 2:00 AM:
   - Boot execution runs at 1:15 PM
   - Next execution at 2:00 AM (13 hours later)
   - No duplicate at 1:15 PM the next day

When `PreventDuplicateExecution` is `No`:

1. **Boot trigger**: Runs at boot AND repeats every 24 hours from boot time
2. **Recurring trigger**: Runs at specified time
3. **Result**: May run twice if boot time and recurring time are close

### Multiple Instances Protection

The task is configured with `MultipleInstances = IgnoreNew`:
- If a snapshot is already running, new instances are ignored
- Prevents overlapping executions
- Ensures only one snapshot runs at a time

---

## Task Management

### View Task Details

```powershell
# Full task details
Get-ScheduledTask -TaskName "Rubrik Fileset Backup - Auto" | Format-List *

# Task info (last/next run)
Get-ScheduledTask -TaskName "Rubrik Fileset Backup - Auto" | Get-ScheduledTaskInfo

# Task triggers
(Get-ScheduledTask -TaskName "Rubrik Fileset Backup - Auto").Triggers
```

### Manually Execute Task

```powershell
Start-ScheduledTask -TaskName "Rubrik Fileset Backup - Auto"
```

### View Task History

```powershell
# Last 10 events
Get-WinEvent -LogName 'Microsoft-Windows-TaskScheduler/Operational' | 
    Where-Object {$_.Message -like '*Rubrik Fileset Backup - Auto*'} | 
    Select-Object TimeCreated, Id, Message -First 10

# Task execution results
Get-ScheduledTask -TaskName "Rubrik Fileset Backup - Auto" | 
    Get-ScheduledTaskInfo | 
    Select-Object LastRunTime, LastTaskResult, NextRunTime
```

### Check Service Account Configuration

```powershell
# Check if encrypted credentials exist
$encryptedPath = Join-Path (Split-Path $PROFILE) "rubrik-powershell-sdk\rsc_service_account_default.xml"
Test-Path $encryptedPath

# View encrypted file location
Write-Host "Encrypted credentials: $encryptedPath"

# Test connection with credentials
Connect-Rsc
Get-RscCluster
Disconnect-Rsc
```

### Disable Task

```powershell
Disable-ScheduledTask -TaskName "Rubrik Fileset Backup - Auto"
```

### Enable Task

```powershell
Enable-ScheduledTask -TaskName "Rubrik Fileset Backup - Auto"
```

### Modify Task

To modify the task, run the scheduler script again with new parameters. The script will remove the old task and create a new one.

```powershell
# Example: Change to every 6 hours
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold" -RecurringIntervalHours 6
```

**Note:** The Service Account is already configured, so the script will skip that step if the encrypted credentials file exists.

### Delete Task

```powershell
Unregister-ScheduledTask -TaskName "Rubrik Fileset Backup - Auto" -Confirm:$false
```

---

## Troubleshooting

### Common Issues

#### 1. "RubrikSecurityCloud module is not installed"

**Error:**
```
ERROR: RubrikSecurityCloud module is not installed.
```

**Solution:**
```powershell
Install-Module -Name RubrikSecurityCloud -Scope AllUsers -Force
```

Verify:
```powershell
Get-Module -ListAvailable RubrikSecurityCloud
```

#### 2. "SYSTEM account is not authenticated" ⚠️ **NEW in v1.1**

**Error:**
```
SYSTEM account is not authenticated - configuration required
Service Account JSON file not found
```

**Solution A - Provide JSON file (Automatic Configuration):**
```powershell
# Option 1: Specify JSON path
.\New-RscFileSnapshotScheduler.ps1 `
    -SlaName "Gold" `
    -ServiceAccountJsonPath "C:\Downloads\service-account-rsc123.json"

# Option 2: Place JSON in script directory
Copy-Item "C:\Downloads\service-account-*.json" .
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold"
```

**Solution B - Manual Configuration (if automatic fails):**
```powershell
# 1. Download PsExec from Sysinternals
# https://docs.microsoft.com/en-us/sysinternals/downloads/psexec

# 2. Run PowerShell as SYSTEM
PsExec.exe -i -s powershell.exe

# 3. In SYSTEM PowerShell, configure authentication
Import-Module RubrikSecurityCloud
Set-RscServiceAccountFile -InputFilePath "C:\Path\To\service-account.json"
Connect-Rsc  # Test connection
Disconnect-Rsc
exit

# 4. Run scheduler as regular admin
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold"
```

#### 3. "Failed to configure SYSTEM account authentication" ⚠️ **NEW in v1.1**

**Error:**
```
ERROR: Failed to configure SYSTEM account authentication (Exit Code: XXX)
```

**Common Causes & Solutions:**

**Module not installed with AllUsers scope:**
```powershell
# Uninstall current module
Uninstall-Module -Name RubrikSecurityCloud -AllVersions

# Reinstall with AllUsers scope (REQUIRED)
Install-Module -Name RubrikSecurityCloud -Scope AllUsers -Force

# Verify
Get-Module -ListAvailable RubrikSecurityCloud
```

**Invalid JSON file:**
```powershell
# Test JSON validity
Get-Content "service-account-*.json" | ConvertFrom-Json

# Re-download from Rubrik Security Cloud if corrupted
```

**Execution policy restrictions:**
```powershell
# Check execution policy
Get-ExecutionPolicy

# Set to appropriate level
Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
```

**Permissions issue:**
```powershell
# Ensure running as Administrator
([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Check SYSTEM profile directory exists
Test-Path "C:\Windows\System32\config\systemprofile\Documents\WindowsPowerShell"
```

#### 4. "Service Account JSON file not found"

**Error:**
```
ERROR: No Service Account JSON file found in script directory.
```

**Solutions:**

**Option A - Download and provide JSON:**
```powershell
# 1. Download JSON from Rubrik Security Cloud UI
# 2. Provide path to scheduler
.\New-RscFileSnapshotScheduler.ps1 `
    -SlaName "Gold" `
    -ServiceAccountJsonPath "C:\Downloads\service-account-rsc123.json"
```

**Option B - Create Service Account:**
```powershell
# Use the helper script
.\New-RscServiceAccount.ps1 -ServiceAccountName "FilesetBackupAutomation"
# Then download the JSON file from RSC
```

#### 5. "This script requires Administrator privileges"

**Error:**
```
ERROR: This script requires Administrator privileges to create scheduled tasks.
```

**Solution:**
```powershell
# Right-click PowerShell → "Run as Administrator"
# Or from command line:
Start-Process powershell -Verb RunAs
```

#### 6. "Parameter -SlaName is required"

**Error:**
```
ERROR: Parameter -SlaName is required.
```

**Cause:** Script executed without the mandatory `-SlaName` parameter.

**Solution:**
```powershell
# Provide the SlaName parameter
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold"

# View help for more options
.\New-RscFileSnapshotScheduler.ps1 -Help
```

#### 6. "New-RscFileSnapshot.ps1 not found"

**Error:**
```
ERROR: New-RscFileSnapshot.ps1 not found at: C:\Scripts\New-RscFileSnapshot.ps1
```

**Solutions:**
```powershell
# Option 1: Specify correct path
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold" -ScriptPath "C:\Correct\Path\New-RscFileSnapshot.ps1"

# Option 2: Place scripts in same directory
Copy-Item "C:\Downloads\New-RscFileSnapshot.ps1" "C:\Scripts\"
cd C:\Scripts
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold"
```

#### 7. Task Doesn't Execute ⚠️ **UPDATED for v1.1**

**Diagnosis:**
```powershell
# Check task status
Get-ScheduledTask -TaskName "Rubrik Fileset Backup - Auto"

# Check last result (0 = success)
Get-ScheduledTask -TaskName "Rubrik Fileset Backup - Auto" | Get-ScheduledTaskInfo | Select LastTaskResult

# View error details
Get-WinEvent -LogName 'Microsoft-Windows-TaskScheduler/Operational' -MaxEvents 50 | 
    Where-Object {$_.Message -like '*Rubrik Fileset Backup - Auto*' -and $_.LevelDisplayName -eq 'Error'}
```

**Common Causes:**

1. **SYSTEM Account Not Authenticated (v1.1 should prevent this):**
```powershell
# Verify SYSTEM authentication manually
# Run PowerShell as SYSTEM
PsExec.exe -i -s powershell.exe

# In SYSTEM PowerShell session
Import-Module RubrikSecurityCloud
Connect-Rsc  # Should work without prompts
Get-RscCluster
Disconnect-Rsc
exit
```

2. **Service Account expired or deleted in Rubrik:**
   - Check Service Account status in Rubrik Security Cloud UI
   - Regenerate credentials if needed
   - Re-run scheduler with new JSON file

3. **Network not available when task runs:**
   - Increase boot delay: `-BootDelayMinutes 30`
   - Check Task Scheduler history for network-related errors

4. **Module not installed with AllUsers scope:**
```powershell
# Verify module installation scope
Get-Module -ListAvailable RubrikSecurityCloud | Select-Object Name, Path

# Path should contain "Program Files" not "Documents"
# Correct: C:\Program Files\WindowsPowerShell\Modules\RubrikSecurityCloud
# Wrong:   C:\Users\...\Documents\WindowsPowerShell\Modules\RubrikSecurityCloud

# Fix if needed
Uninstall-Module RubrikSecurityCloud -AllVersions
Install-Module RubrikSecurityCloud -Scope AllUsers -Force
```

#### 8. Task Runs But Fails

**Check Logs:**
```powershell
# Navigate to log directory
cd C:\Path\To\New-RscFileSnapshot.ps1\Logs

# View latest log
Get-ChildItem -Filter "New-RscFileSnapshot_*.log" | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 1 | 
    Get-Content -Tail 50
```

**Check SYSTEM Account Authentication (NEW):**
```powershell
# Test SYSTEM authentication
PsExec.exe -i -s powershell.exe

# In SYSTEM PowerShell
$encryptedPath = "C:\Windows\System32\config\systemprofile\Documents\WindowsPowerShell\rubrik-powershell-sdk\rsc_service_account_default.xml"
Test-Path $encryptedPath  # Should be True

Import-Module RubrikSecurityCloud
Connect-Rsc
Get-RscCluster  # Should work if credentials are valid
Disconnect-Rsc
exit
```

**Common Issues:**
- SYSTEM account credentials not configured (v1.1 should prevent this)
- Service Account expired or deleted
- SLA policy renamed/deleted
- Host or Fileset no longer exists
- Network connectivity issues

#### 9. Multiple Tasks Running

**Check:**
```powershell
Get-ScheduledTask | Where-Object {$_.TaskName -like '*Rubrik*'}
```

**Solution:**
Remove duplicates:
```powershell
Get-ScheduledTask | 
    Where-Object {$_.TaskName -like '*Rubrik*' -and $_.TaskName -ne 'Rubrik Fileset Backup - Auto'} | 
    Unregister-ScheduledTask -Confirm:$false
```

#### 10. Task Result Code 0x1 (General Error)

**Diagnosis:**
```powershell
# Test script manually
cd C:\Path\To\Scripts
.\New-RscFileSnapshot.ps1 -SlaName "Gold"
```

**Common Causes:**
- Service Account not configured properly
- Missing Rubrik PowerShell module
- Execution policy blocking script

**Solutions:**
```powershell
# Check module
Get-Module -ListAvailable RubrikSecurityCloud

# Check encrypted credentials
$encryptedPath = Join-Path (Split-Path $PROFILE) "rubrik-powershell-sdk\rsc_service_account_default.xml"
if (Test-Path $encryptedPath) {
    Write-Host "✓ Encrypted credentials found"
} else {
    Write-Host "✗ Encrypted credentials missing - re-run scheduler script"
}

# Check execution policy
Get-ExecutionPolicy

# Set execution policy (if needed)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### 11. "WARNING: Original JSON file still exists" ⚠️ **NEW**

**Warning:**
```
WARNING: Original JSON file still exists: C:\Scripts\service-account-123.json
Consider deleting this file manually for security
```

**Explanation:** The script couldn't automatically delete the JSON file (possibly due to file permissions or locks).

**Solution:**
```powershell
# Manually delete the JSON file
Remove-Item "C:\Scripts\service-account-*.json" -Force

# Verify deletion
Get-ChildItem "C:\Scripts\*.json"
```

**Security Note:** The JSON file contains sensitive credentials and should be deleted after the encrypted file is created.

---

## Advanced Scenarios

### Scenario 1: Multiple Filesets, Different Schedules

Create separate tasks for different Filesets:

```powershell
# Production data - every 6 hours
.\New-RscFileSnapshotScheduler.ps1 `
    -SlaName "Platinum" `
    -FilesetName "Production*" `
    -RecurringIntervalHours 6 `
    -TaskName "Rubrik - Production Backup"

# User data - daily
.\New-RscFileSnapshotScheduler.ps1 `
    -SlaName "Gold" `
    -FilesetName "Users*" `
    -RecurringTime "03:00" `
    -TaskName "Rubrik - User Backup"

# Archives - weekly (Sunday at 1 AM)
# Note: Weekly schedule requires additional configuration
.\New-RscFileSnapshotScheduler.ps1 `
    -SlaName "Silver" `
    -FilesetName "Archives*" `
    -EnableBootExecution No `
    -RecurringTime "01:00" `
    -TaskName "Rubrik - Archive Backup"
```

**Note:** All tasks will use the same encrypted Service Account credentials (already configured from first run).

### Scenario 2: High-Availability Setup

For critical systems, create overlapping schedules:

```powershell
# Primary schedule - every 4 hours
.\New-RscFileSnapshotScheduler.ps1 `
    -SlaName "Platinum" `
    -RecurringTime "00:00" `
    -RecurringIntervalHours 4 `
    -TaskName "Rubrik - Primary Schedule"

# Backup schedule - every 4 hours, offset by 2 hours
.\New-RscFileSnapshotScheduler.ps1 `
    -SlaName "Platinum" `
    -RecurringTime "02:00" `
    -RecurringIntervalHours 4 `
    -EnableBootExecution No `
    -TaskName "Rubrik - Backup Schedule"
```

Result: Snapshots every 2 hours (0:00, 2:00, 4:00, 6:00...)

### Scenario 3: Workstation Roaming Users

For laptops that aren't always on:

```powershell
.\New-RscFileSnapshotScheduler.ps1 `
    -SlaName "Gold" `
    -EnableRecurringSchedule No `
    -BootDelayMinutes 20 `
    -PreventDuplicateExecution No
```

**Behavior:**
- Runs 20 minutes after every boot
- No time-based schedule (since laptop may be off)
- Repeats every 24 hours from boot time

### Scenario 4: Initial Setup with Service Account Configuration

Complete first-time setup:

```powershell
# Step 1: Install module (if not already installed)
Install-Module -Name RubrikSecurityCloud -Scope AllUsers

# Step 2: Download Service Account JSON from Rubrik Security Cloud
# Place it in C:\Scripts\RubrikBackup\

# Step 3: Run scheduler (first time - configures Service Account)
cd C:\Scripts\RubrikBackup
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold"

# Step 4: Verify encrypted credentials created
$encryptedPath = Join-Path (Split-Path $PROFILE) "rubrik-powershell-sdk\rsc_service_account_default.xml"
Test-Path $encryptedPath  # Should return True

# Step 5: Verify JSON was deleted
Get-ChildItem "C:\Scripts\RubrikBackup\*.json"  # Should return nothing

# Step 6: Create additional tasks (Service Account already configured)
.\New-RscFileSnapshotScheduler.ps1 `
    -SlaName "Silver" `
    -FilesetName "Archives*" `
    -TaskName "Rubrik - Archive Backup"
```

### Scenario 5: Maintenance Windows

Avoid backup during business hours:

```powershell
# Overnight backups only - every 2 hours from 10 PM to 6 AM
.\New-RscFileSnapshotScheduler.ps1 `
    -SlaName "Gold" `
    -RecurringTime "22:00" `
    -RecurringIntervalHours 2 `
    -EnableBootExecution No
```

**Note:** For complex scheduling (e.g., weekdays only), you may need to create the task manually or use multiple tasks.

### Scenario 6: Multi-Server Environment

Deploy to multiple servers:

```powershell
# Deployment script
$servers = @("FILESRV01", "FILESRV02", "FILESRV03")

# Step 1: Copy scripts and Service Account JSON to each server
foreach ($server in $servers) {
    $destPath = "\\$server\C$\Scripts\RubrikBackup"
    
    # Create directory
    New-Item -Path $destPath -ItemType Directory -Force
    
    # Copy files
    Copy-Item ".\*.ps1" -Destination $destPath
    Copy-Item ".\service-account-*.json" -Destination $destPath
}

# Step 2: Execute scheduler on each server remotely
foreach ($server in $servers) {
    Invoke-Command -ComputerName $server -ScriptBlock {
        param($SlaName)
        
        cd C:\Scripts\RubrikBackup
        
        # Run as Administrator
        & ".\New-RscFileSnapshotScheduler.ps1" -SlaName $SlaName
    } -ArgumentList "Gold"
}

# Step 3: Verify tasks created
foreach ($server in $servers) {
    Invoke-Command -ComputerName $server -ScriptBlock {
        Get-ScheduledTask -TaskName "Rubrik Fileset Backup - Auto" | 
            Get-ScheduledTaskInfo | 
            Select-Object PSComputerName, LastRunTime, NextRunTime
    }
}
```

### Scenario 7: Service Account Rotation

Rotate Service Account credentials periodically:

```powershell
# Step 1: Create new Service Account in Rubrik Security Cloud
# Download new JSON file

# Step 2: Remove old encrypted credentials
$encryptedPath = Join-Path (Split-Path $PROFILE) "rubrik-powershell-sdk\rsc_service_account_default.xml"
Remove-Item $encryptedPath -Force

# Step 3: Place new JSON in script directory
Copy-Item "C:\Downloads\service-account-new-*.json" "C:\Scripts\RubrikBackup\"

# Step 4: Re-run scheduler to configure new Service Account
cd C:\Scripts\RubrikBackup
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold"

# The script will:
# - Detect the new JSON file
# - Create new encrypted credentials
# - Delete the new JSON file
# - Update the scheduled task (or skip if already exists)

# Step 5: Delete old Service Account in Rubrik Security Cloud
```

---

## Integration with Service Accounts

### Complete Workflow (NEW)

#### 1. First-Time Setup

```powershell
# A. Install Module
Install-Module -Name RubrikSecurityCloud -Scope AllUsers

# B. Create Service Account (use helper script or manual)
.\New-RscServiceAccount.ps1 -ServiceAccountName "FilesetBackupAutomation"
# OR manually download JSON from Rubrik Security Cloud

# C. Place JSON in script directory
Copy-Item "C:\Downloads\service-account-*.json" "C:\Scripts\RubrikBackup\"

# D. Run Scheduler (auto-configures Service Account)
cd C:\Scripts\RubrikBackup
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold"
```

**What happens:**
1. Script imports RubrikSecurityCloud module
2. Script finds `service-account-*.json` in directory
3. Runs `Set-RscServiceAccountFile -DisablePrompts`
4. Creates encrypted XML: `$PROFILE\..\rubrik-powershell-sdk\rsc_service_account_default.xml`
5. Deletes original JSON file
6. Creates scheduled task

#### 2. Subsequent Task Creations

```powershell
# No JSON file needed - encrypted credentials already exist
.\New-RscFileSnapshotScheduler.ps1 `
    -SlaName "Silver" `
    -FilesetName "Archives*" `
    -TaskName "Rubrik - Archive Backup"
```

**What happens:**
1. Script checks for encrypted credentials (found)
2. Skips Service Account configuration
3. Creates new scheduled task
4. All tasks use same encrypted credentials

#### 3. Verify Configuration

```powershell
# Check encrypted credentials exist
$encryptedPath = Join-Path (Split-Path $PROFILE) "rubrik-powershell-sdk\rsc_service_account_default.xml"

if (Test-Path $encryptedPath) {
    Write-Host "✓ Service Account configured" -ForegroundColor Green
    Write-Host "  Location: $encryptedPath" -ForegroundColor Gray
    
    # Test connection
    Connect-Rsc
    $cluster = Get-RscCluster
    Write-Host "✓ Connection successful: $($cluster.Name)" -ForegroundColor Green
    Disconnect-Rsc
} else {
    Write-Host "✗ Service Account not configured" -ForegroundColor Red
    Write-Host "  Run scheduler script with JSON file" -ForegroundColor Yellow
}
```

---

## Security Considerations

### Service Account Credentials Storage

**Encryption Process:**

1. **Input**: Clear-text JSON file downloaded from Rubrik
2. **Processing**: `Set-RscServiceAccountFile` creates encrypted XML
3. **Storage**: `$PROFILE\..\rubrik-powershell-sdk\rsc_service_account_default.xml`
4. **Cleanup**: Original JSON automatically deleted
5. **Security**: 
   - **Windows**: DPAPI encryption (only creating user can decrypt)
   - **Linux/Mac**: Platform-specific secure storage

**Encrypted Credentials Location:**

```powershell
# Windows
C:\Users\YourUser\Documents\WindowsPowerShell\rubrik-powershell-sdk\rsc_service_account_default.xml

# Windows (PowerShell 7+)
C:\Users\YourUser\Documents\PowerShell\rubrik-powershell-sdk\rsc_service_account_default.xml

# Linux/Mac
~/.config/powershell/rubrik-powershell-sdk/rsc_service_account_default.xml
```

### Best Practices

#### ✅ DO

```powershell
# 1. Use separate Service Accounts for different purposes
# Production snapshots
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Platinum" -TaskName "Prod-Backup"

# Test snapshots (different Service Account)
# (Configure different Service Account first, then run)

# 2. Delete JSON files immediately after configuration
# The script does this automatically, but verify:
Get-ChildItem "*.json"  # Should return nothing after running scheduler

# 3. Protect encrypted credentials file
$encryptedPath = Join-Path (Split-Path $PROFILE) "rubrik-powershell-sdk\rsc_service_account_default.xml"
icacls $encryptedPath  # Verify only your user has access

# 4. Rotate Service Accounts periodically (e.g., every 90 days)
# See Scenario 7 in Advanced Scenarios

# 5. Monitor task execution
Get-ScheduledTask -TaskName "Rubrik*" | Get-ScheduledTaskInfo
```

#### ❌ DON'T

```powershell
# ❌ DON'T store JSON files in Git repositories
# ❌ DON'T share encrypted XML files (they won't work anyway)
# ❌ DON'T use same Service Account for prod and test
# ❌ DON'T commit credentials to version control
# ❌ DON'T store JSON in publicly accessible locations
```

### Multi-User Considerations

⚠️ **Important**: Encrypted credentials are **user-specific**

- Each Windows user needs their own Service Account configuration
- Encrypted file created by User A cannot be used by User B
- For scheduled tasks running as SYSTEM:

```powershell
# Option A: Configure while running as SYSTEM (recommended for scheduled tasks)
# Use PsExec to run PowerShell as SYSTEM
PsExec.exe -i -s powershell.exe

# Then in the SYSTEM PowerShell session:
cd C:\Scripts\RubrikBackup
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold"

# Option B: Configure as current user, run task as current user
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold" -RunAsUser CurrentUser
```

---

## Command Reference

### Create Task

```powershell
# Minimal (auto-detects JSON in script directory)
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold"

# With specific JSON path
.\New-RscFileSnapshotScheduler.ps1 `
    -SlaName "Gold" `
    -ServiceAccountJsonPath "C:\Credentials\rubrik.json"

# Full options
.\New-RscFileSnapshotScheduler.ps1 `
    -SlaName "Gold" `
    -ScriptPath "C:\Scripts\New-RscFileSnapshot.ps1" `
    -TaskName "My Custom Task" `
    -ServiceAccountJsonPath "C:\Creds\rubrik.json" `
    -HostName "FILESRV01" `
    -OsType Windows `
    -FilesetName "UserData" `
    -SkipConnectivityCheck No `
    -EnableBootExecution Yes `
    -BootDelayMinutes 15 `
    -EnableRecurringSchedule Yes `
    -RecurringTime "02:00" `
    -RecurringIntervalHours 24 `
    -PreventDuplicateExecution Yes `
    -RunAsUser SYSTEM
```

### Check Module Status

```powershell
# Check if module is loaded
Get-Module -Name RubrikSecurityCloud

# Check if module is installed
Get-Module -ListAvailable -Name RubrikSecurityCloud

# Get module version
(Get-Module -ListAvailable -Name RubrikSecurityCloud).Version
```

### Check Service Account Status

```powershell
# Check if encrypted credentials exist
$encryptedPath = Join-Path (Split-Path $PROFILE) "rubrik-powershell-sdk\rsc_service_account_default.xml"
Test-Path $encryptedPath

# View file properties
Get-Item $encryptedPath | Select-Object FullName, Length, LastWriteTime, Attributes

# Test connection
Connect-Rsc
Get-RscCluster
Disconnect-Rsc
```

### List All Rubrik Tasks

```powershell
Get-ScheduledTask | Where-Object {$_.TaskName -like '*Rubrik*'} | Format-Table TaskName, State, LastRunTime, NextRunTime
```

### Export Task Definition

```powershell
Export-ScheduledTask -TaskName "Rubrik Fileset Backup - Auto" | Out-File "C:\Backup\RubrikTask.xml"
```

### Import Task Definition

```powershell
Register-ScheduledTask -Xml (Get-Content "C:\Backup\RubrikTask.xml" | Out-String) -TaskName "Rubrik Fileset Backup - Auto"
```

---

## Exit Codes

- **0**: Success or help requested
- **1**: Error occurred (check console output for details)

---

## Version History

- **1.1** (February 2026): 
  - Added automatic SYSTEM account authentication verification
  - Added automatic SYSTEM authentication configuration
  - Improved error handling for authentication failures
  - Added ServiceAccountJsonPath parameter
  - Enhanced troubleshooting documentation
  - Task creation now verifies authentication before proceeding
  
- **1.0** (January 2026): Initial release

---

## License

This program is free software: you can redistribute it and/or modify it under the terms of the **GNU General Public License v3.0** as published by the Free Software Foundation.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

---

## Author

GitHub: [@mbriotto](https://github.com/mbriotto)  
Repository: https://github.com/mbriotto/New-RscFileSnapshot

---

## Related Scripts

- **New-RscFileSnapshot.ps1**: Main snapshot execution script
- **New-RscServiceAccount.ps1**: Service Account creation helper

---

## Support

For issues and questions:
- **GitHub Issues**: https://github.com/mbriotto/New-RscFileSnapshot/issues
- **Rubrik PowerShell SDK**: https://github.com/rubrikinc/rubrik-powershell-sdk
- **Rubrik Security Cloud**: Contact Rubrik Support

---

## FAQ

### Q: Do I need Administrator privileges to run this script?

**A:** No. Creating scheduled tasks in Windows requires Administrator privileges. However, you can run the Service Account configuration part without admin rights (only the task creation requires it).

---

**For the complete Rubrik automation solution, see:**
- [New-RscFileSnapshot.ps1 README](New-RscFileSnapshot.ps1-README.md)
- [New-RscServiceAccount.ps1 README](New-RscServiceAccount.ps1-README.md)
- [Main Project README](README.md)
