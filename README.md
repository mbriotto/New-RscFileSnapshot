# Rubrik Security Cloud - Fileset Snapshot Automation

Complete PowerShell automation suite for Rubrik Security Cloud Fileset snapshots with Windows Task Scheduler integration.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Windows](https://img.shields.io/badge/Windows-10%2F11%2BServer-blue.svg)](https://www.microsoft.com/windows)

---

## 📋 Table of Contents

- [Overview](#overview)
- [Repository Structure](#repository-structure)
- [Project Components](#project-components)
- [Quick Start Guide](#quick-start-guide)
- [Complete Setup Workflow](#complete-setup-workflow)
- [Script Interactions](#script-interactions)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage Examples](#usage-examples)
- [Troubleshooting](#troubleshooting)
- [Support](#support)
- [License](#license)

---

## Repository Structure

```
rubrik-scripts/
├── .gitignore                                          # Git ignore rules
├── LICENSE                                             # GNU GPL v3.0 License
├── README.md                                           # This file
│
├── Initialize-RubrikEnvironment.cmd                    # Setup script
├── Initialize-RubrikEnvironment.cmd-README.md          # Setup documentation
│
├── New-RscServiceAccount.ps1                           # Service Account creator
├── New-RscServiceAccount.ps1-README.md                 # Service Account docs
│
├── New-RscFileSnapshot.ps1                             # Snapshot executor
├── New-RscFileSnapshot.ps1-README.md                   # Snapshot docs
│
├── New-RscFileSnapshotScheduler.ps1                    # Task scheduler
├── New-RscFileSnapshotScheduler.ps1-README.md          # Scheduler docs
│
├── Check-RscServiceAccountStatus.ps1                   # Credential checker
└── Check-RscServiceAccountStatus.ps1-README.md         # Checker docs
```

---

## Overview

This project provides a complete automation solution for backing up Windows/Linux filesets to Rubrik Security Cloud (RSC). It includes:

✅ **Environment initialization** - Automated RSC PowerShell module setup  
✅ **Service Account creation** - Interactive guide for minimal-privilege accounts  
✅ **On-demand snapshots** - Manual and automated fileset backups  
✅ **Task scheduling** - Windows Scheduled Tasks for recurring backups  
✅ **Credential verification** - Diagnostic tool for troubleshooting authentication  

---

## Project Components

### 1. Initialize-RubrikEnvironment.cmd
**Purpose**: Initial environment setup  
**What it does**:
- Installs RubrikSecurityCloud PowerShell module if missing
- Imports the module into the current session
- Unblocks all PowerShell scripts in the directory
- Displays next steps for configuration

**When to use**: First time setup on a new system

📖 [Full Documentation](Initialize-RubrikEnvironment.cmd-README.md)

---

### 2. New-RscServiceAccount.ps1
**Purpose**: Create Service Accounts with minimum required permissions  
**What it does**:
- Connects to Rubrik Security Cloud to verify access
- Provides step-by-step instructions for creating a custom role
- Guides through Service Account creation in RSC web interface
- Validates JSON credentials file download
- Documents exact permissions granted (Principle of Least Privilege)

**When to use**: Creating new Service Accounts for automation

**Note**: Due to SDK limitations, this is an interactive guide requiring manual steps in RSC web UI

📖 [Full Documentation](New-RscServiceAccount.ps1-README.md)

---

### 3. New-RscFileSnapshot.ps1
**Purpose**: Execute on-demand Fileset snapshots  
**What it does**:
- Authenticates to Rubrik Security Cloud
- Auto-detects local hostname (or uses specified host)
- Selects target Fileset (by name or first available)
- Applies specified SLA policy
- Initiates snapshot via GraphQL mutation
- Automatically configures Service Account from JSON file on first run
- Provides comprehensive logging (optional)

**When to use**: 
- Manual snapshot execution
- Testing backup configuration
- Called by scheduled tasks for automated backups

📖 [Full Documentation](New-RscFileSnapshot.ps1-README.md)

---

### 4. New-RscFileSnapshotScheduler.ps1
**Purpose**: Create Windows Scheduled Tasks for automated backups  
**What it does**:
- Creates scheduled task with configurable triggers
- Supports boot execution with delay
- Supports recurring schedules (hourly to weekly)
- Implements duplicate prevention logic
- Passes all parameters to New-RscFileSnapshot.ps1
- Validates permissions and configuration
- Provides comprehensive task management

**When to use**: Setting up automated recurring backups

📖 [Full Documentation](New-RscFileSnapshotScheduler.ps1-README.md)

---

### 5. Check-RscServiceAccountStatus.ps1
**Purpose**: Verify and manage Service Account credentials  
**What it does**:
- Checks RubrikSecurityCloud module installation
- Verifies encrypted credentials for:
  - Current user
  - SYSTEM account (standard location)
  - SYSTEM account (PsExec location)
- Displays detailed file information
- Provides contextual recommendations
- Interactive deletion menu for credential management

**When to use**: 
- Troubleshooting authentication issues
- Verifying scheduled task configuration
- Managing credential files

📖 [Full Documentation](Check-RscServiceAccountStatus.ps1-README.md)

---

## Quick Start Guide

### Step 1: Initialize Environment (One-time)

```cmd
REM Run as Administrator
cd C:\Scripts\Rubrik
Initialize-RubrikEnvironment.cmd
```

**What happens:**
- ✅ RubrikSecurityCloud module installed (if needed)
- ✅ Module imported into session
- ✅ All .ps1 scripts unblocked
- ✅ Next steps displayed

---

### Step 2: Create Service Account (One-time)

```powershell
# Interactive guide for creating Service Account
.\New-RscServiceAccount.ps1 -ServiceAccountName 'FilesetBackupAutomation'
```

**What happens:**
- ✅ Connects to RSC to verify access
- ✅ Displays exact role permissions required
- ✅ Guides through role creation (manual steps)
- ✅ Guides through Service Account creation (manual steps)
- ✅ Validates JSON credentials download

**Manual steps in RSC web UI:**
1. Create custom role with specified permissions
2. Create Service Account and assign role
3. Download JSON credentials file

**Result**: Service Account JSON file saved locally

---

### Step 3: Test Manual Snapshot (First run)

```powershell
# Place downloaded JSON file in script directory first
.\New-RscFileSnapshot.ps1 -SlaName 'Gold'
```

**What happens on first run:**
- ✅ Detects JSON file in script directory
- ✅ Calls Set-RscServiceAccountFile to create encrypted credentials
- ✅ Deletes JSON file for security
- ✅ Executes snapshot using encrypted credentials
- ✅ Creates log file (optional)

**What happens on subsequent runs:**
- ✅ Uses existing encrypted credentials (no JSON needed)
- ✅ Executes snapshot
- ✅ Appends to log file

---

### Step 4: Set Up Automated Backups (Optional)

```powershell
# Run as Administrator
.\New-RscFileSnapshotScheduler.ps1 -SlaName 'Gold'
```

**What happens:**
- ✅ Creates Windows Scheduled Task
- ✅ Default schedule: 15 min after boot + daily at 2 AM
- ✅ Prevents duplicate execution at boot
- ✅ Runs as SYSTEM account
- ✅ Optional: Test run to verify configuration

**Result**: Automated recurring backups configured

---

### Step 5: Verify Configuration (Optional)

```powershell
# Check credential status
.\Check-RscServiceAccountStatus.ps1
```

**What happens:**
- ✅ Shows module installation status
- ✅ Lists all credential locations
- ✅ Provides execution context analysis
- ✅ Offers credential deletion if needed

---

## Complete Setup Workflow

```
┌─────────────────────────────────────────────────────────────┐
│  STEP 1: Initialize Environment                             │
│  Initialize-RubrikEnvironment.cmd                           │
│                                                              │
│  Installs module, unblocks scripts, displays next steps     │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 2: Create Service Account                             │
│  New-RscServiceAccount.ps1 -ServiceAccountName 'Backup'     │
│                                                              │
│  Interactive guide → Manual RSC UI steps → JSON download    │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 3: Place JSON File                                    │
│  Copy JSON file to script directory                         │
│                                                              │
│  C:\Scripts\Rubrik\service-account-rk12345.json             │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 4: First Snapshot Run                                 │
│  New-RscFileSnapshot.ps1 -SlaName 'Gold'                    │
│                                                              │
│  Auto-detects JSON → Creates encrypted XML → Deletes JSON   │
│  Executes snapshot → Creates log                            │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 5A: Manual Execution (as needed)                      │
│  New-RscFileSnapshot.ps1 -SlaName 'Gold'                    │
│                                                              │
│  Uses encrypted credentials → Executes snapshot             │
└──────────────────────────────────────────────────────────────┘

                    OR (for automation)
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 5B: Automated Scheduling                              │
│  New-RscFileSnapshotScheduler.ps1 -SlaName 'Gold'          │
│                                                              │
│  Creates scheduled task → Runs New-RscFileSnapshot.ps1      │
│  automatically on schedule                                   │
└──────────────────────────────────────────────────────────────┘

                    Optional: Verification
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 6: Verify Status (troubleshooting)                    │
│  Check-RscServiceAccountStatus.ps1                          │
│                                                              │
│  Shows credential locations, execution contexts, etc.       │
└─────────────────────────────────────────────────────────────┘
```

---

## Script Interactions

### Credential Flow

```
Service Account JSON (from RSC)
        │
        │ First run of New-RscFileSnapshot.ps1
        ▼
Set-RscServiceAccountFile (RSC SDK)
        │
        │ Creates encrypted file
        ▼
rsc_service_account_default.xml
(in PowerShell profile directory)
        │
        │ Used by all subsequent runs
        ▼
New-RscFileSnapshot.ps1 (manual or scheduled)
```

### Scheduled Task Flow

```
New-RscFileSnapshotScheduler.ps1
        │
        │ Creates task definition
        ▼
Windows Task Scheduler
        │
        ├── Trigger 1: Boot + 15 min delay
        │   └─→ Runs New-RscFileSnapshot.ps1
        │
        └── Trigger 2: Daily at 2:00 AM
            └─→ Runs New-RscFileSnapshot.ps1
                    │
                    ▼
            Uses encrypted credentials
                    │
                    ▼
            Executes snapshot → Logs to file
```

### Verification Flow

```
Check-RscServiceAccountStatus.ps1
        │
        ├─→ Checks: Current User credentials
        │   Location: %USERPROFILE%\Documents\WindowsPowerShell\
        │             rubrik-powershell-sdk\rsc_service_account_default.xml
        │
        ├─→ Checks: SYSTEM credentials (standard)
        │   Location: C:\Windows\System32\config\systemprofile\
        │             Documents\WindowsPowerShell\rubrik-powershell-sdk\
        │             rsc_service_account_default.xml
        │
        └─→ Checks: SYSTEM credentials (PsExec)
            Location: C:\Windows\SysWOW64\config\systemprofile\
                      Documents\WindowsPowerShell\rubrik-powershell-sdk\
                      rsc_service_account_default.xml
```

---

## Prerequisites

### System Requirements

- **Operating System**: Windows 10/11 or Windows Server 2016+
- **PowerShell**: Version 5.1 or later
- **Administrator Rights**: **REQUIRED** for:
  - Module installation (AllUsers scope)
  - Scheduled task creation
  - First-time setup
- **Internet Connection**: Required for module installation and RSC connectivity

### Rubrik Requirements

- **Rubrik Security Cloud Account**: Active subscription
- **RSC Access**: Your organization's Rubrik Security Cloud URL
- **Permissions**: Ability to create Service Accounts and Roles

### PowerShell Module

- **RubrikSecurityCloud**: Must be installed for ALL USERS (to support scheduled tasks)

**Automatic installation** (recommended):
```cmd
REM Run Initialize-RubrikEnvironment.cmd as Administrator
Initialize-RubrikEnvironment.cmd
```

**Manual installation**:
```powershell
# Run PowerShell as Administrator - REQUIRED for scheduled tasks
Install-Module -Name RubrikSecurityCloud -Scope AllUsers -Force
```

**Important**: Do NOT use `-Scope CurrentUser` if you plan to use scheduled tasks, as SYSTEM account won't have access to the module.

---

## Installation

### Option 1: Clone Repository

```powershell
git clone https://github.com/mbriotto/rubrik-scripts.git
cd rubrik-scripts
```

### Option 2: Direct Download

```powershell
# Create directory
New-Item -Path "C:\Scripts\Rubrik" -ItemType Directory -Force
cd C:\Scripts\Rubrik

# Download scripts
$base = "https://raw.githubusercontent.com/mbriotto/rubrik-scripts/main"

Invoke-WebRequest -Uri "$base/Initialize-RubrikEnvironment.cmd" -OutFile "Initialize-RubrikEnvironment.cmd"
Invoke-WebRequest -Uri "$base/New-RscServiceAccount.ps1" -OutFile "New-RscServiceAccount.ps1"
Invoke-WebRequest -Uri "$base/New-RscFileSnapshot.ps1" -OutFile "New-RscFileSnapshot.ps1"
Invoke-WebRequest -Uri "$base/New-RscFileSnapshotScheduler.ps1" -OutFile "New-RscFileSnapshotScheduler.ps1"
Invoke-WebRequest -Uri "$base/Check-RscServiceAccountStatus.ps1" -OutFile "Check-RscServiceAccountStatus.ps1"
```

### Option 3: Automated Setup

```powershell
# 1. Create directory
New-Item -Path "C:\Scripts\Rubrik" -ItemType Directory -Force
cd C:\Scripts\Rubrik

# 2. Download initialization script
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/mbriotto/rubrik-scripts/main/Initialize-RubrikEnvironment.cmd" -OutFile "Initialize-RubrikEnvironment.cmd"

# 3. Run initialization (as Administrator)
.\Initialize-RubrikEnvironment.cmd

# 4. Follow the displayed next steps
```

---

## Usage Examples

### Example 1: Basic Setup (First Time)

```powershell
# Step 1: Initialize environment
.\Initialize-RubrikEnvironment.cmd

# Step 2: Create Service Account (follow interactive prompts)
.\New-RscServiceAccount.ps1 -ServiceAccountName 'FilesetBackup'

# Step 3: Download JSON from RSC, place in script directory

# Step 4: Run first snapshot (configures credentials automatically)
.\New-RscFileSnapshot.ps1 -SlaName 'Gold'

# Step 5: Set up automation
.\New-RscFileSnapshotScheduler.ps1 -SlaName 'Gold'
```

---

### Example 2: Specific Host and Fileset

```powershell
# Manual snapshot of specific configuration
.\New-RscFileSnapshot.ps1 `
    -HostName 'FILESRV01' `
    -OsType Windows `
    -SlaName 'Gold' `
    -FilesetName 'UserProfiles'

# Create scheduled task for same configuration
.\New-RscFileSnapshotScheduler.ps1 `
    -HostName 'FILESRV01' `
    -OsType Windows `
    -SlaName 'Gold' `
    -FilesetName 'UserProfiles' `
    -TaskName 'Rubrik - FILESRV01 UserProfiles'
```

---

### Example 3: Linux Host Backup

```powershell
# Snapshot Linux fileset
.\New-RscFileSnapshot.ps1 `
    -HostName 'ubuntu-web01' `
    -OsType Linux `
    -SlaName 'Silver' `
    -FilesetName '/var/www'

# Schedule Linux backups every 12 hours
.\New-RscFileSnapshotScheduler.ps1 `
    -HostName 'ubuntu-web01' `
    -OsType Linux `
    -SlaName 'Silver' `
    -FilesetName '/var/www' `
    -RecurringIntervalHours 12 `
    -RecurringTime '00:00'
```

---

### Example 4: Custom Schedule

```powershell
# Every 6 hours, no boot execution
.\New-RscFileSnapshotScheduler.ps1 `
    -SlaName 'Gold' `
    -EnableBootExecution No `
    -RecurringTime '00:00' `
    -RecurringIntervalHours 6
```

---

### Example 5: Troubleshooting Authentication

```powershell
# Check credential status
.\Check-RscServiceAccountStatus.ps1

# Example output analysis:
# [+] CURRENT USER: CONFIGURED     → Manual execution will work
# [-] SYSTEM (Standard): NOT CONFIGURED  → Scheduled tasks will fail
# [-] SYSTEM (PsExec): NOT CONFIGURED    → PsExec execution will fail

# Fix: Configure SYSTEM credentials
# 1. Use PsExec to run PowerShell as SYSTEM:
PsExec.exe -i -s powershell.exe

# 2. In the SYSTEM PowerShell window:
cd C:\Scripts\Rubrik
.\New-RscFileSnapshot.ps1 -SlaName 'Gold'  # Will configure SYSTEM credentials
```

---

### Example 6: Verify Scheduled Task

```powershell
# View task details
Get-ScheduledTask -TaskName 'Rubrik Fileset Backup - Auto' | Format-List *

# Check last/next run times
Get-ScheduledTask -TaskName 'Rubrik Fileset Backup - Auto' | Get-ScheduledTaskInfo

# Manually trigger task
Start-ScheduledTask -TaskName 'Rubrik Fileset Backup - Auto'

# View task history
Get-WinEvent -LogName 'Microsoft-Windows-TaskScheduler/Operational' | 
    Where-Object {$_.Message -like '*Rubrik*'} | 
    Select-Object TimeCreated, Message -First 10
```

---

## Troubleshooting

### Issue: "Module not found" error

**Solution:**
```powershell
# Install module manually
Install-Module -Name RubrikSecurityCloud -Scope AllUsers -Force

# Verify installation
Get-Module -ListAvailable RubrikSecurityCloud
```

---

### Issue: "Credentials not found" during scheduled task

**Problem:** Scheduled task runs as SYSTEM but credentials are configured for current user

**Solution:**
```powershell
# Check status
.\Check-RscServiceAccountStatus.ps1

# If SYSTEM credentials missing, configure them:
# 1. Download PsExec from Microsoft Sysinternals
# 2. Run PowerShell as SYSTEM:
PsExec.exe -i -s powershell.exe

# 3. In SYSTEM PowerShell:
cd C:\Scripts\Rubrik
.\New-RscFileSnapshot.ps1 -SlaName 'Gold'  # This configures SYSTEM credentials
```

---

### Issue: Execution policy blocks scripts

**Solution:**
```powershell
# Temporary (current session only)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Or unblock individual files
Unblock-File -Path .\*.ps1

# Or use Initialize-RubrikEnvironment.cmd (automatically unblocks all scripts)
```

---

### Issue: Task scheduler shows "Access Denied"

**Problem:** Insufficient permissions to create scheduled tasks

**Solution:**
```powershell
# Run PowerShell as Administrator
# Right-click PowerShell → "Run as Administrator"

# Then run the scheduler script
.\New-RscFileSnapshotScheduler.ps1 -SlaName 'Gold'
```

---

### Issue: JSON file not found

**Problem:** Service Account JSON file not in expected location

**Solution:**
```powershell
# Check current directory
Get-Location

# List JSON files
Get-ChildItem *.json

# Copy JSON to script directory
Copy-Item "C:\Downloads\service-account-rk12345.json" .

# Verify
Get-ChildItem *.json
```

---

## Support

### Documentation

- **Rubrik Security Cloud Docs**: https://docs.rubrik.com/
- **PowerShell SDK**: https://github.com/rubrikinc/rubrik-powershell-sdk
- **Individual Script READMEs**: See each script's detailed documentation

### Getting Help

- **GitHub Issues**: https://github.com/mbriotto/rubrik-scripts/issues
- **Rubrik Support**: https://support.rubrik.com/
- **Rubrik Community**: https://community.rubrik.com/

### Reporting Bugs

When reporting issues, please include:

```powershell
# System information
$PSVersionTable

# Module version
Get-Module -ListAvailable RubrikSecurityCloud | Select-Object Name, Version

# Credential status
.\Check-RscServiceAccountStatus.ps1

# Task status (if applicable)
Get-ScheduledTask | Where-Object {$_.TaskName -like '*Rubrik*'} | Get-ScheduledTaskInfo

# Error messages (sanitize any sensitive information)
```

---

## License

This program is free software: you can redistribute it and/or modify it under the terms of the **GNU General Public License v3.0** as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but **WITHOUT ANY WARRANTY**; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see https://www.gnu.org/licenses/.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

---

## Version History

### Version 1.0 (January 2026) - Initial Release

**All Scripts:**
- Initialize-RubrikEnvironment.cmd - Environment setup automation
- New-RscServiceAccount.ps1 - Service Account creation guide
- New-RscFileSnapshot.ps1 - On-demand snapshot execution
- New-RscFileSnapshotScheduler.ps1 - Task scheduler automation
- Check-RscServiceAccountStatus.ps1 - Credential verification tool

**Features:**
- Complete automation workflow for Rubrik Fileset snapshots
- Minimum privilege Service Account configuration
- Automatic credential management (JSON → encrypted XML)
- Windows Task Scheduler integration
- Comprehensive logging and error handling
- Multi-context credential support (user, SYSTEM, PsExec)

---

## Author

**GitHub**: [@mbriotto](https://github.com/mbriotto)  
**Repository**: https://github.com/mbriotto/rubrik-scripts

---

## Contributing

Contributions, issues, and feature requests are welcome!

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## Acknowledgments

- Rubrik for the Rubrik Security Cloud platform
- Rubrik PowerShell SDK development team
- Community contributors

---

**Last Updated**: January 2026  
**Project Version**: 1.0 - Initial Release
