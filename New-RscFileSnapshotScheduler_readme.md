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

### 3. New-RscFileSnapshot.ps1

The main snapshot script must be accessible. By default, the scheduler looks in the same directory.

### 4. Rubrik PowerShell SDK

```powershell
Install-Module -Name RubrikSecurityCloud -Scope CurrentUser
```

---

## Installation

### Method 1: Clone Repository

```powershell
git clone https://github.com/mbriotto/New-RscFileSnapshot.git
cd New-RscFileSnapshot
```

### Method 2: Download Script

```powershell
# Download scheduler
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/mbriotto/New-RscFileSnapshot/main/New-RscFileSnapshotScheduler.ps1" -OutFile "New-RscFileSnapshotScheduler.ps1"

# Download main script (if not already present)
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/mbriotto/New-RscFileSnapshot/main/New-RscFileSnapshot.ps1" -OutFile "New-RscFileSnapshot.ps1"
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
# Run PowerShell as Administrator
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold"
```

This creates a task that:
- ✅ Runs 15 minutes after PC startup
- ✅ Runs daily at 2:00 AM
- ✅ Prevents duplicate execution at boot if already run recently
- ✅ Uses local hostname and first available Fileset

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

**Note:** `-SlaName` is **REQUIRED**. Running the script without this parameter will display the help text.

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

### Example 1: Default Configuration

```powershell
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold"
```

**Behavior:**
- Runs 15 minutes after boot
- Runs daily at 2:00 AM
- Prevents duplicate at boot if already run recently

### Example 2: Boot Only (No Recurring)

```powershell
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold" -EnableRecurringSchedule No
```

**Behavior:**
- Runs 15 minutes after boot
- No recurring schedule
- Useful for laptops that aren't always on

### Example 3: Recurring Only (No Boot)

```powershell
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold" -EnableBootExecution No
```

**Behavior:**
- Does NOT run at boot
- Runs daily at 2:00 AM
- Useful for servers with predictable uptime

### Example 4: Custom Boot Delay

```powershell
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold" -BootDelayMinutes 30
```

**Behavior:**
- Runs 30 minutes after boot (instead of 15)
- Runs daily at 2:00 AM
- Good for systems with slow startup

### Example 5: Every 12 Hours

```powershell
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Silver" -RecurringTime "14:00" -RecurringIntervalHours 12
```

**Behavior:**
- Runs 15 minutes after boot
- Runs at 2:00 PM and repeats every 12 hours (2:00 PM, 2:00 AM, 2:00 PM...)

### Example 6: Every 6 Hours (High Frequency)

```powershell
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Platinum" -RecurringTime "00:00" -RecurringIntervalHours 6
```

**Behavior:**
- Runs 15 minutes after boot
- Runs at midnight, 6 AM, noon, 6 PM (every 6 hours)

### Example 7: Allow Boot Duplicates

```powershell
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold" -PreventDuplicateExecution No
```

**Behavior:**
- Runs at boot AND at 2:00 AM (even if already run)
- Boot execution repeats every 24 hours

### Example 8: Specific Host and Fileset

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

### Example 9: Linux Server

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

### Example 10: Custom Script Path and Task Name

```powershell
.\New-RscFileSnapshotScheduler.ps1 `
    -SlaName "Gold" `
    -ScriptPath "C:\Scripts\Rubrik\New-RscFileSnapshot.ps1" `
    -TaskName "Production DB Backup"
```

**Behavior:**
- Uses script from custom location
- Creates task with custom name

### Example 11: Run as Current User

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

### Execution Flow

```
PC Boots
   â†"
Wait 15 minutes (configurable)
   â†"
Check: Has task run in last 24h?
   â†" No                    â†" Yes
Execute snapshot      Skip execution
   â†"
Wait until 2:00 AM
   â†"
Execute snapshot
   â†"
Wait 24 hours
   â†"
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

### Delete Task

```powershell
Unregister-ScheduledTask -TaskName "Rubrik Fileset Backup - Auto" -Confirm:$false
```

---

## Troubleshooting

### Common Issues

#### 1. "This script requires Administrator privileges"

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

#### 2. "Parameter -SlaName is required"

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

#### 3. "New-RscFileSnapshot.ps1 not found"

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

#### 4. Task Doesn't Execute

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
- Service Account JSON not configured
- Network not available when task runs
- Rubrik cluster unreachable
- Incorrect SLA name

#### 5. Task Runs But Fails

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

**Common Issues:**
- Service Account expired or deleted
- SLA policy renamed/deleted
- Host or Fileset no longer exists
- Network connectivity issues

#### 6. Multiple Tasks Running

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

#### 7. Task Result Code 0x1 (General Error)

**Diagnosis:**
```powershell
# Test script manually
cd C:\Path\To\Scripts
.\New-RscFileSnapshot.ps1 -SlaName "Gold"
```

**Common Causes:**
- Service Account not configured (no JSON file processed)
- Missing Rubrik PowerShell module
- Execution policy blocking script

**Solutions:**
```powershell
# Check execution policy
Get-ExecutionPolicy

# Set execution policy (if needed)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Verify module
Get-Module -ListAvailable RubrikSecurityCloud
```

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

### Scenario 4: Maintenance Windows

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

### Scenario 5: Multi-Server Environment

Deploy to multiple servers:

```powershell
# Create deployment script
$servers = @("FILESRV01", "FILESRV02", "FILESRV03")

foreach ($server in $servers) {
    Invoke-Command -ComputerName $server -ScriptBlock {
        param($SlaName)
        
        # Copy scripts if needed
        # Then create task
        & "C:\Scripts\New-RscFileSnapshotScheduler.ps1" -SlaName $SlaName
    } -ArgumentList "Gold"
}
```

### Scenario 6: Different SLAs by Day

For weekly rotation (requires manual task editing):

```powershell
# Monday-Friday: Gold SLA
# Weekend: Silver SLA
# This requires creating two separate tasks and manually configuring triggers
```

---

## Integration with Service Accounts

### Initial Setup

1. **Create Service Account:**
```powershell
.\New-RscServiceAccount.ps1 -ServiceAccountName "FilesetBackup"
```

2. **Place JSON in Script Directory:**
```powershell
Copy-Item "service-account-*.json" "C:\Scripts\"
```

3. **Create Scheduled Task:**
```powershell
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold"
```

4. **First Execution:**
   - Task runs at scheduled time
   - Detects JSON file
   - Configures encrypted credentials
   - Deletes JSON file
   - Performs snapshot

5. **Subsequent Executions:**
   - Uses encrypted credentials automatically
   - No JSON file needed

---

## Security Considerations

### 1. Service Account Credentials

- JSON credentials are automatically encrypted after first use
- Encrypted file location: `$PROFILE\..\rubrik-powershell-sdk\rsc_service_account_default.xml`
- Only the creating user can decrypt (DPAPI on Windows)

### 2. Task Execution Account

**SYSTEM Account (Default):**
- ✅ Runs even when user is logged off
- ✅ Works for all users
- ⚠️ Requires SYSTEM to configure Service Account JSON

**Current User:**
- ✅ Uses user's existing credentials
- ⚠️ Only runs when user is logged in
- ✅ Good for testing

### 3. Log Files

- May contain sensitive information
- Secure the log directory
- Default retention: 30 days

### 4. Script Execution Policy

```powershell
# View current policy
Get-ExecutionPolicy

# Recommended for production
Set-ExecutionPolicy RemoteSigned -Scope LocalMachine
```

---

## Command Reference

### Create Task

```powershell
# Minimal
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold"

# Full options
.\New-RscFileSnapshotScheduler.ps1 `
    -SlaName "Gold" `
    -ScriptPath "C:\Scripts\New-RscFileSnapshot.ps1" `
    -TaskName "My Custom Task" `
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
- **1**: Error occurred (check console output)

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

### Q: How do I see all available parameters and options?

**A:** Use the `-Help` parameter:

```powershell
.\New-RscFileSnapshotScheduler.ps1 -Help
# or
.\New-RscFileSnapshotScheduler.ps1 -?

# Running without parameters also displays help
.\New-RscFileSnapshotScheduler.ps1
```

The help screen shows all available parameters, their defaults, and usage examples.

### Q: Can I create multiple tasks with different schedules?

**A:** Yes! Just use different task names:

```powershell
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold" -TaskName "Morning Backup" -RecurringTime "08:00"
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Silver" -TaskName "Evening Backup" -RecurringTime "20:00"
```

### Q: What happens if the PC is off at the scheduled time?

**A:** The task is configured with `StartWhenAvailable`, so it will run as soon as possible after the PC is turned on.

### Q: How do I schedule weekly backups?

**A:** Set `RecurringIntervalHours` to 168 (7 days × 24 hours):

```powershell
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Silver" -RecurringIntervalHours 168
```

### Q: Can I run snapshots every 30 minutes?

**A:** Yes, but be aware of Rubrik's rate limits:

```powershell
# Not recommended - may hit rate limits
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Platinum" -RecurringTime "00:00" -RecurringIntervalHours 0.5
```

**Note:** The script currently only accepts whole hours. For sub-hourly schedules, manually edit the task after creation.

### Q: How do I update an existing task?

**A:** Run the scheduler script again with the same task name. It will remove the old task and create a new one:

```powershell
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold" -RecurringIntervalHours 12
```

### Q: What's the difference between PreventDuplicateExecution Yes/No?

**A:**

- **Yes**: Boot trigger runs once, recurring trigger handles subsequent executions (recommended)
- **No**: Boot trigger repeats every 24 hours AND recurring trigger also runs (may cause duplicates)

### Q: Can I use this on a server that's always on?

**A:** Yes! You may want to disable boot execution:

```powershell
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold" -EnableBootExecution No
```

---

**For the complete Rubrik automation solution, see:**
- [New-RscFileSnapshot.ps1 README](New-RscFileSnapshot_readme.md)
- [New-RscServiceAccount.ps1 README](New-RscServiceAccount_readme.md)
