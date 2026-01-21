# New-RscFileSnapshotScheduler.ps1

PowerShell script for creating Windows Scheduled Tasks to automate Rubrik Fileset snapshots.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)

## Overview

`New-RscFileSnapshotScheduler.ps1` automates the creation of Windows Scheduled Tasks that execute `New-RscFileSnapshot.ps1` at configurable intervals. The script supports boot-time execution with delays, recurring schedules, and intelligent duplicate prevention.

### Key Features

- ✅ **Boot Execution**: Automatically runs snapshots after PC startup (configurable delay)
- ✅ **Recurring Schedule**: Execute at specific times and intervals (hourly to weekly)
- ✅ **Duplicate Prevention**: Avoids running at boot if already executed recently
- ✅ **Flexible Configuration**: All `New-RscFileSnapshot.ps1` parameters supported
- ✅ **Smart Defaults**: Works out-of-the-box with minimal configuration
- ✅ **Multiple Instances Protection**: Prevents overlapping executions
- ✅ **Comprehensive Validation**: Checks permissions, paths, and configuration
- ✅ **Administrator Privileges Check**: Ensures proper permissions before task creation

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

**Important**: Service Account credentials must be configured BEFORE creating scheduled tasks.

#### How to configure:

1. **Create Service Account in Rubrik**
   - Use [New-RscServiceAccount.ps1](New-RscServiceAccount.ps1-README.md) for guided creation
   - Or create manually in RSC web UI

2. **Download JSON credentials**
   - Download the Service Account JSON file from Rubrik Security Cloud

3. **Configure credentials**
   - Place JSON file in the script directory
   - Run `New-RscFileSnapshot.ps1 -SlaName 'Gold'` once
   - This will automatically configure encrypted credentials and delete the JSON file

4. **Verify configuration**
   - Run `Check-RscServiceAccountStatus.ps1` to verify credentials exist

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

### Default Configuration (Recommended)

```powershell
# 1. Ensure Service Account credentials are configured
#    (Run New-RscFileSnapshot.ps1 once to configure if not already done)

# 2. Run PowerShell as Administrator

# 3. Execute scheduler:
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold"
```

**What happens:**
1. ✅ Verifies script path and SLA parameter
2. ✅ Creates scheduled task with:
   - Runs 15 minutes after PC startup
   - Runs daily at 2:00 AM
   - Prevents duplicate execution at boot if already run recently
   - Uses local hostname and first available Fileset
   - Calls New-RscFileSnapshot.ps1 which uses existing encrypted credentials

### Important Note on Credentials

The scheduler creates a task that calls `New-RscFileSnapshot.ps1`. This script requires encrypted credentials to be configured BEFORE creating the scheduled task.

**To configure credentials**:
```powershell
# Place Service Account JSON in script directory, then run:
.\New-RscFileSnapshot.ps1 -SlaName "Gold"
# This configures encrypted credentials and deletes the JSON file
```

**To verify credentials are configured**:
```powershell
.\Check-RscServiceAccountStatus.ps1
```

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

### Example 1: Default Configuration (with auto-detected JSON)

```powershell
# Ensure service-account-*.json is in script directory
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold"
```

**Behavior:**
- Auto-detects and configures Service Account JSON
- Runs 15 minutes after boot
- Runs daily at 2:00 AM
- Prevents duplicate at boot if already run recently

### Example 2: Specify JSON Path

```powershell
.\New-RscFileSnapshotScheduler.ps1 `
    -SlaName "Gold" `
    -ServiceAccountJsonPath "C:\SecureFolder\rubrik-credentials.json"
```

**Behavior:**
- Uses specified JSON file path
- Creates encrypted credentials
- Deletes original JSON after configuration

### Example 3: Boot Only (No Recurring)

```powershell
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold" -EnableRecurringSchedule No
```

**Behavior:**
- Runs 15 minutes after boot
- No recurring schedule
- Useful for laptops that aren't always on

### Example 4: Recurring Only (No Boot)

```powershell
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold" -EnableBootExecution No
```

**Behavior:**
- Does NOT run at boot
- Runs daily at 2:00 AM
- Useful for servers with predictable uptime

### Example 5: Custom Boot Delay

```powershell
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold" -BootDelayMinutes 30
```

**Behavior:**
- Runs 30 minutes after boot (instead of 15)
- Runs daily at 2:00 AM
- Good for systems with slow startup

### Example 6: Every 12 Hours

```powershell
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Silver" -RecurringTime "14:00" -RecurringIntervalHours 12
```

**Behavior:**
- Runs 15 minutes after boot
- Runs at 2:00 PM and repeats every 12 hours (2:00 PM, 2:00 AM, 2:00 PM...)

### Example 7: Every 6 Hours (High Frequency)

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

### Execution Flow (NEW - 5 Steps)

```
Step 1: Import RubrikSecurityCloud Module
   ↓
   Check if module is loaded
   ↓
   Import module if needed
   ↓
Step 2: Configure Service Account (MANDATORY)
   ↓
   Detect JSON file (auto or specified path)
   ↓
   Run Set-RscServiceAccountFile
   ↓
   Create encrypted credentials XML
   ↓
   Delete original JSON file
   ↓
Step 3: Validate Environment
   ↓
   Check Administrator privileges
   ↓
   Verify script paths
   ↓
Step 4: Build Command Arguments
   ↓
   Construct PowerShell command
   ↓
Step 5: Create Scheduled Task
   ↓
   Register task with triggers
   ↓
   Configure advanced settings
   ↓
Complete
```

### Service Account Configuration Process (NEW)

```
JSON File Detection
   ↓
Auto-detect in script directory OR use -ServiceAccountJsonPath
   ↓
Validation
   ↓
File exists? → Yes → Continue
            → No  → ERROR: Exit with instructions
   ↓
Configuration
   ↓
Run: Set-RscServiceAccountFile -DisablePrompts
   ↓
Encrypted XML Created
   ↓
Location: $PROFILE\..\rubrik-powershell-sdk\rsc_service_account_default.xml
   ↓
Security Cleanup
   ↓
Original JSON file deleted
   ↓
Verification
   ↓
Check encrypted file exists
   ↓
Success
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
Connect-Rsc (uses encrypted credentials automatically)
   ↓
Wait until 2:00 AM
   ↓
Execute snapshot
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

#### 2. "No Service Account JSON file found" ⚠️ **NEW**

**Error:**
```
ERROR: No Service Account JSON file found in script directory.
A Rubrik Service Account JSON file is REQUIRED to create the scheduled task.
```

**Solutions:**

**Option A - Place JSON in script directory (recommended):**
```powershell
# Download JSON from Rubrik Security Cloud
# Then copy to script directory
Copy-Item "C:\Downloads\service-account-*.json" "C:\Scripts\RubrikBackup\"
```

**Option B - Specify JSON path:**
```powershell
.\New-RscFileSnapshotScheduler.ps1 `
    -SlaName "Gold" `
    -ServiceAccountJsonPath "C:\Credentials\rubrik-service-account.json"
```

**Option C - Create Service Account:**
```powershell
# Use the helper script
.\New-RscServiceAccount.ps1 -ServiceAccountName "FilesetBackupAutomation"
```

#### 3. "Failed to configure Service Account" ⚠️ **NEW**

**Error:**
```
ERROR: Failed to configure Service Account: [error details]
```

**Common Causes & Solutions:**

**Invalid JSON file:**
```powershell
# Verify JSON is valid
Get-Content "service-account-*.json" | ConvertFrom-Json

# Re-download from Rubrik Security Cloud if corrupted
```

**Permissions issue:**
```powershell
# Check write permissions to profile directory
Test-Path (Split-Path $PROFILE) -PathType Container

# Run PowerShell as Administrator
Start-Process powershell -Verb RunAs
```

**Module version mismatch:**
```powershell
# Update to latest module version
Update-Module -Name RubrikSecurityCloud -Force
```

#### 4. "This script requires Administrator privileges"

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

#### 5. "Parameter -SlaName is required"

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

#### 7. Task Doesn't Execute

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
- Service Account not configured (should be impossible with new version)
- Service Account expired or deleted in Rubrik
- Network not available when task runs
- Rubrik cluster unreachable
- Incorrect SLA name

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

**Check Service Account:**
```powershell
# Verify encrypted credentials exist
$encryptedPath = Join-Path (Split-Path $PROFILE) "rubrik-powershell-sdk\rsc_service_account_default.xml"
Test-Path $encryptedPath

# Test connection
Connect-Rsc
Get-RscCluster  # Should work if credentials are valid
Disconnect-Rsc
```

**Common Issues:**
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
