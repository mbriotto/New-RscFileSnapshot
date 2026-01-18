# Rubrik Fileset Snapshot Automation

PowerShell automation suite for creating and scheduling on-demand snapshots of Rubrik Filesets via Rubrik Security Cloud (RSC).

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Scripts Overview](#scripts-overview)
- [Installation](#installation)
- [Usage Examples](#usage-examples)
- [Scheduling Automated Backups](#scheduling-automated-backups)
- [Execution Policy Setup](#execution-policy-setup)
- [Troubleshooting](#troubleshooting)
- [Documentation](#documentation)
- [Support](#support)
- [License](#license)

---

## 🎯 Overview

This project provides a complete automation solution for Rubrik Fileset snapshots, including:

- **Manual snapshot execution** via PowerShell
- **Automated scheduling** using Windows Task Scheduler
- **Service Account management** for authentication
- **Comprehensive logging** and error handling
- **Security best practices** including credential encryption

Perfect for:
- Automating backup operations
- Integrating Rubrik into CI/CD pipelines
- Scheduling recurring snapshots
- Disaster recovery procedures
- Compliance and retention management

---

## ✨ Features

### New-RscFileSnapshot.ps1
- ✅ Automatic host detection (uses local FQDN)
- ✅ Automatic cluster discovery (extracts from CdmLink)
- ✅ Service Account auto-configuration
- ✅ Flexible Fileset selection (exact, wildcard, or auto-fallback)
- ✅ Comprehensive file logging with rotation
- ✅ Optional connectivity verification
- ✅ Secure credential handling

### New-RscFileSnapshotScheduler.ps1
- ✅ Boot execution with configurable delay
- ✅ Recurring schedules (hourly to weekly)
- ✅ Intelligent duplicate prevention
- ✅ Multiple execution methods
- ✅ Administrator validation
- ✅ Multiple instances protection
- ✅ Comprehensive task configuration

### New-RscServiceAccount.ps1
- ✅ Guided Service Account creation
- ✅ Minimum required permissions
- ✅ Browser integration
- ✅ Credential validation
- ✅ Comprehensive documentation

---

## 📦 Prerequisites

### 1. Rubrik PowerShell SDK

```powershell
Install-Module -Name RubrikSecurityCloud -Scope CurrentUser
```

### 2. PowerShell Execution Policy

The scripts require proper execution policy configuration. See [Execution Policy Guide](#execution-policy-setup) below.

### 3. Rubrik Security Cloud Access

- Access to Rubrik Security Cloud (RSC)
- Service Account with appropriate permissions
- Network connectivity to Rubrik cluster

### 4. Windows Requirements

- Windows 10/11 or Windows Server 2016+
- PowerShell 5.1 or higher
- Administrator privileges (for scheduled tasks)

---

## 🚀 Quick Start

### Step 1: Clone the Repository

```powershell
git clone https://github.com/mbriotto/New-RscFileSnapshot.git
cd New-RscFileSnapshot
```

### Step 2: Set Execution Policy

```powershell
# Recommended: Set RemoteSigned for current user
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force

# Unblock downloaded scripts
Unblock-File -Path "*.ps1"
```

### Step 3: Create Service Account

Follow the guided process to create a Service Account in Rubrik Security Cloud:

```powershell
.\New-RscServiceAccount.ps1 -ServiceAccountName "FilesetBackupAutomation"
```

**Manual Steps Required:**
1. Log in to Rubrik Security Cloud
2. Create custom role "Fileset Snapshot Operator" with required permissions
3. Create Service Account and assign the role
4. Download JSON credentials file

### Step 4: Configure Credentials

Copy the downloaded JSON file to the script directory:

```powershell
Copy-Item "service-account-*.json" "C:\Path\To\Scripts\"
```

### Step 5: Test Manual Snapshot

```powershell
.\New-RscFileSnapshot.ps1 -SlaName "Gold"
```

The script will:
- Auto-detect JSON file and configure encrypted credentials
- Use local hostname automatically
- Execute snapshot with specified SLA
- Delete JSON file after successful configuration

### Step 6: Schedule Automated Backups

```powershell
# Run PowerShell as Administrator
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold"
```

This creates a task that runs:
- 15 minutes after PC startup
- Daily at 2:00 AM
- With duplicate prevention enabled

---

## 📁 Scripts Overview

### 1. New-RscFileSnapshot.ps1

**Purpose**: Execute on-demand Fileset snapshots

**Key Parameters**:
- `-SlaName` (Required): SLA policy name
- `-HostName` (Optional): Target host (defaults to local FQDN)
- `-FilesetName` (Optional): Fileset to backup (supports wildcards)
- `-OsType` (Optional): Windows or Linux (default: Windows)
- `-EnableFileLog` (Optional): Enable logging (default: Yes)

**Example**:
```powershell
.\New-RscFileSnapshot.ps1 -SlaName "Gold" -HostName "FILESRV01" -FilesetName "UserProfiles"
```

[📖 Full Documentation](New-RscFileSnapshot_readme.md)

---

### 2. New-RscFileSnapshotScheduler.ps1

**Purpose**: Create Windows Scheduled Tasks for automated snapshots

**Key Parameters**:
- `-SlaName` (Required): SLA policy name
- `-EnableBootExecution` (Optional): Run at startup (default: Yes)
- `-BootDelayMinutes` (Optional): Delay after boot (default: 15)
- `-EnableRecurringSchedule` (Optional): Time-based execution (default: Yes)
- `-RecurringTime` (Optional): Execution time (default: "02:00")
- `-RecurringIntervalHours` (Optional): Repeat interval (default: 24)

**Example**:
```powershell
# Every 12 hours
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Silver" -RecurringIntervalHours 12

# Boot only (for laptops)
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold" -EnableRecurringSchedule No
```

[📖 Full Documentation](New-RscFileSnapshotScheduler_readme.md)

---

### 3. New-RscServiceAccount.ps1

**Purpose**: Guided Service Account creation in RSC

**Key Parameters**:
- `-ServiceAccountName` (Required): Service Account name
- `-ServiceAccountDescription` (Optional): Description
- `-RoleName` (Optional): Custom role name (default: "Fileset Snapshot Operator")
- `-OutputPath` (Optional): Credentials save location

**Example**:
```powershell
.\New-RscServiceAccount.ps1 -ServiceAccountName "FilesetBackup" -OutputPath "C:\Credentials"
```

[📖 Full Documentation](New-RscServiceAccount_readme.md)

---

## 💾 Installation

### Option 1: Git Clone (Recommended)

```powershell
git clone https://github.com/mbriotto/New-RscFileSnapshot.git
cd New-RscFileSnapshot
```

### Option 2: Direct Download

Download individual scripts:

```powershell
# Main snapshot script
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/mbriotto/New-RscFileSnapshot/main/New-RscFileSnapshot.ps1" -OutFile "New-RscFileSnapshot.ps1"

# Scheduler script
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/mbriotto/New-RscFileSnapshot/main/New-RscFileSnapshotScheduler.ps1" -OutFile "New-RscFileSnapshotScheduler.ps1"

# Service Account helper
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/mbriotto/New-RscFileSnapshot/main/New-RscServiceAccount.ps1" -OutFile "New-RscServiceAccount.ps1"
```

### Option 3: ZIP Download

Download the entire repository as ZIP from GitHub and extract to your preferred location.

---

## 📚 Usage Examples

### Example 1: Simple Daily Backup

```powershell
# Create scheduled task for daily backups
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold"

# Result:
# - Runs 15 minutes after PC startup
# - Runs daily at 2:00 AM
# - Prevents duplicate at boot if already run
```

### Example 2: High-Frequency Backups

```powershell
# Backup every 6 hours
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Platinum" -RecurringIntervalHours 6
```

### Example 3: Specific Host and Fileset

```powershell
# Target specific server and fileset
.\New-RscFileSnapshot.ps1 `
    -SlaName "Gold" `
    -HostName "FILESRV01" `
    -FilesetName "Production*" `
    -EnableFileLog Yes `
    -LogFilePath "C:\Logs\Rubrik"
```

### Example 4: Linux Server Backup

```powershell
# Linux host with wildcard fileset
.\New-RscFileSnapshot.ps1 `
    -SlaName "Silver" `
    -HostName "ubuntu-server" `
    -OsType Linux `
    -FilesetName "home-*"
```

### Example 5: Laptop/Workstation (Boot Only)

```powershell
# Run only at boot (no time-based schedule)
.\New-RscFileSnapshotScheduler.ps1 `
    -SlaName "Gold" `
    -EnableRecurringSchedule No `
    -BootDelayMinutes 20
```

### Example 6: Multiple Filesets, Different Schedules

```powershell
# Production data - every 4 hours
.\New-RscFileSnapshotScheduler.ps1 `
    -SlaName "Platinum" `
    -FilesetName "Production*" `
    -RecurringIntervalHours 4 `
    -TaskName "Rubrik - Production Backup"

# User data - daily
.\New-RscFileSnapshotScheduler.ps1 `
    -SlaName "Gold" `
    -FilesetName "Users*" `
    -RecurringTime "03:00" `
    -TaskName "Rubrik - User Backup"
```

---

## ⏰ Scheduling Automated Backups

### Understanding the Scheduling Options

The `New-RscFileSnapshotScheduler.ps1` script supports multiple execution patterns:

#### 1. Boot Execution
Runs snapshot after PC startup with configurable delay:

```powershell
-EnableBootExecution Yes      # Enable boot execution
-BootDelayMinutes 15          # Wait 15 minutes after boot
```

**Use cases**:
- Laptops that aren't always on
- Workstations with variable uptime
- Ensuring backup after system restart

#### 2. Recurring Schedule
Runs at specific times with optional repetition:

```powershell
-EnableRecurringSchedule Yes  # Enable time-based execution
-RecurringTime "02:00"        # Run at 2:00 AM
-RecurringIntervalHours 24    # Repeat every 24 hours
```

**Use cases**:
- Servers with predictable uptime
- Maintenance windows
- Regular daily/hourly backups

#### 3. Duplicate Prevention
Prevents boot execution if already run recently:

```powershell
-PreventDuplicateExecution Yes  # Skip boot run if recently executed
```

**How it works**:
- If PC boots at 1:00 PM and recurring is at 2:00 AM
- Boot execution runs at 1:15 PM
- Next execution at 2:00 AM (not at 1:15 PM the next day)

### Common Scheduling Patterns

#### Pattern 1: Standard Daily Backup (Default)
```powershell
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold"
```
- Runs 15 min after boot
- Runs daily at 2:00 AM
- Duplicate prevention enabled

#### Pattern 2: High-Frequency (Every 6 Hours)
```powershell
.\New-RscFileSnapshotScheduler.ps1 `
    -SlaName "Platinum" `
    -RecurringTime "00:00" `
    -RecurringIntervalHours 6
```
- Runs at: 12:00 AM, 6:00 AM, 12:00 PM, 6:00 PM

#### Pattern 3: Boot Only (Laptops)
```powershell
.\New-RscFileSnapshotScheduler.ps1 `
    -SlaName "Gold" `
    -EnableRecurringSchedule No
```
- Runs only at boot (15 min delay)
- No time-based schedule

#### Pattern 4: Recurring Only (Servers)
```powershell
.\New-RscFileSnapshotScheduler.ps1 `
    -SlaName "Gold" `
    -EnableBootExecution No `
    -RecurringTime "03:00"
```
- Runs only at 3:00 AM daily
- No boot execution

#### Pattern 5: Custom Times with Repetition
```powershell
.\New-RscFileSnapshotScheduler.ps1 `
    -SlaName "Silver" `
    -RecurringTime "08:00" `
    -RecurringIntervalHours 8
```
- Runs at: 8:00 AM, 4:00 PM, 12:00 AM

### Task Management Commands

```powershell
# View task details
Get-ScheduledTask -TaskName "Rubrik Fileset Backup - Auto" | Get-ScheduledTaskInfo

# Manually trigger task
Start-ScheduledTask -TaskName "Rubrik Fileset Backup - Auto"

# Disable task
Disable-ScheduledTask -TaskName "Rubrik Fileset Backup - Auto"

# Enable task
Enable-ScheduledTask -TaskName "Rubrik Fileset Backup - Auto"

# Remove task
Unregister-ScheduledTask -TaskName "Rubrik Fileset Backup - Auto" -Confirm:$false

# View task history
Get-WinEvent -LogName 'Microsoft-Windows-TaskScheduler/Operational' | 
    Where-Object {$_.Message -like '*Rubrik Fileset Backup - Auto*'} | 
    Select-Object TimeCreated, Id, Message -First 10
```

---

## 🔐 Execution Policy Setup

PowerShell execution policies control which scripts can run on your system. This project requires proper execution policy configuration.

### Quick Fix (Recommended)

```powershell
# Set execution policy for current user
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force

# Unblock downloaded scripts
Set-Location "C:\Path\To\Scripts"
Unblock-File -Path "*.ps1"
```

### Understanding Execution Policies

| Policy | Local Scripts | Remote Scripts | Security | Use Case |
|--------|--------------|----------------|----------|----------|
| **Restricted** | ❌ Blocked | ❌ Blocked | 🔒 Maximum | Default (Windows client) |
| **RemoteSigned** | ✅ Allowed | ⚠️ Signed/Unblocked | 🔓 Balanced | **RECOMMENDED** |
| **Unrestricted** | ✅ Allowed | ⚠️ Confirmation | 🔓 Medium | Development |
| **Bypass** | ✅ Allowed | ✅ Allowed | ⚠️ Low | Testing/Automation |

### Common Solutions

#### Solution 1: Unblock Files (RECOMMENDED)
```powershell
# Unblock all scripts in folder
Unblock-File -Path "C:\Scripts\*.ps1"

# Verify unblocked
Get-Item "C:\Scripts\New-RscFileSnapshot.ps1" -Stream Zone.Identifier -ErrorAction SilentlyContinue
# If no output, file is unblocked
```

#### Solution 2: Set RemoteSigned Policy
```powershell
# Current user (no admin required)
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force

# System-wide (requires admin)
Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy RemoteSigned -Force
```

#### Solution 3: Temporary Bypass
```powershell
# One-time execution
PowerShell.exe -ExecutionPolicy Bypass -File "C:\Scripts\New-RscFileSnapshot.ps1" -SlaName "Gold"

# Current session only
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

### Scheduled Tasks (Automatic Bypass)

Scheduled tasks created by `New-RscFileSnapshotScheduler.ps1` automatically use execution policy bypass:

```powershell
# Task action includes: -ExecutionPolicy Bypass
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\New-RscFileSnapshot.ps1" -SlaName "Gold"
```

**No manual configuration required** for scheduled executions!

### Troubleshooting Execution Policy

```powershell
# Check current policy
Get-ExecutionPolicy -List

# Test if file is blocked
Get-Item "script.ps1" -Stream Zone.Identifier -ErrorAction SilentlyContinue

# Remove block manually
Remove-Item -Path "script.ps1" -Stream Zone.Identifier -ErrorAction SilentlyContinue
```

[📖 Complete Execution Policy Guide](ExecutionPolicy_Guide.md)

---

## 🔧 Troubleshooting

### Common Issues and Solutions

#### 1. "Cannot be loaded. The file is not digitally signed"

**Cause**: Execution policy blocking scripts

**Solution**:
```powershell
# Unblock the scripts
Unblock-File -Path "*.ps1"

# Or set execution policy
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

#### 2. "Module RubrikSecurityCloud not found"

**Cause**: Rubrik PowerShell SDK not installed

**Solution**:
```powershell
Install-Module -Name RubrikSecurityCloud -Scope CurrentUser -Force
```

#### 3. "Service Account not configured"

**Cause**: JSON credentials file not processed

**Solution**:
```powershell
# Place JSON file in script directory
Copy-Item "service-account-*.json" "C:\Scripts\"

# Run snapshot script (auto-configures)
.\New-RscFileSnapshot.ps1 -SlaName "Gold"
```

#### 4. "Host not found"

**Cause**: Hostname doesn't match Rubrik configuration

**Solution**:
```powershell
# Check hostname in Rubrik
# Then specify explicitly:
.\New-RscFileSnapshot.ps1 -SlaName "Gold" -HostName "EXACT-NAME-IN-RUBRIK"
```

#### 5. "Cluster not reachable"

**Cause**: Network connectivity issues

**Solution**:
```powershell
# Test connectivity
Test-Connection -ComputerName <cluster-ip> -Count 2

# Skip connectivity check (not recommended)
.\New-RscFileSnapshot.ps1 -SlaName "Gold" -SkipConnectivityCheck Yes
```

#### 6. "Administrator privileges required"

**Cause**: Scheduler needs admin rights for task creation

**Solution**:
```powershell
# Right-click PowerShell → "Run as Administrator"
# Or from command line:
Start-Process powershell -Verb RunAs
```

#### 7. Task runs but fails

**Diagnosis**:
```powershell
# Check task result
Get-ScheduledTask -TaskName "Rubrik Fileset Backup - Auto" | Get-ScheduledTaskInfo

# View logs
cd C:\Path\To\Logs
Get-ChildItem -Filter "New-RscFileSnapshot_*.log" | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 1 | 
    Get-Content -Tail 50
```

### Getting Help

```powershell
# Script help
.\New-RscFileSnapshot.ps1 -Help
.\New-RscFileSnapshotScheduler.ps1 -?
.\New-RscServiceAccount.ps1 -Help

# Detailed help
Get-Help .\New-RscFileSnapshot.ps1 -Full
```

---

## 📖 Documentation

### Core Documentation
- [New-RscFileSnapshot.ps1 README](New-RscFileSnapshot_readme.md) - Main snapshot script documentation
- [New-RscFileSnapshotScheduler.ps1 README](New-RscFileSnapshotScheduler_readme.md) - Scheduler documentation
- [New-RscServiceAccount.ps1 README](New-RscServiceAccount_readme.md) - Service Account creation guide
- [Execution Policy Guide](ExecutionPolicy_Guide.md) - Complete PowerShell execution policy reference

### External Resources
- [Rubrik PowerShell SDK](https://github.com/rubrikinc/rubrik-powershell-sdk) - Official Rubrik module
- [Rubrik Security Cloud Documentation](https://docs.rubrik.com) - RSC product documentation
- [Microsoft PowerShell Documentation](https://docs.microsoft.com/powershell/) - PowerShell reference

---

## 🔒 Security Considerations

### Credential Management

1. **Service Account JSON Files**:
   - Downloaded from Rubrik Security Cloud
   - Contains sensitive authentication tokens
   - Automatically deleted after encryption

2. **Encrypted Credentials**:
   - Created by `Set-RscServiceAccountFile`
   - Location: `$PROFILE\..\rubrik-powershell-sdk\rsc_service_account_default.xml`
   - Uses Windows DPAPI (user-specific encryption)
   - Cannot be shared between users

3. **Best Practices**:
   - ✅ Use Service Accounts for automation
   - ✅ Apply principle of least privilege
   - ✅ Rotate credentials regularly
   - ✅ Secure log directories
   - ❌ Never commit JSON files to Git
   - ❌ Never share encrypted XML files
   - ❌ Never disable execution policy globally

### Permissions Required

**Service Account Permissions** (minimum):
- Fileset: Read, On-Demand Backup
- SLA Domain: Read
- Host: Read
- Cluster: Read

**Windows Permissions**:
- Administrator: Required for scheduled task creation
- User: Sufficient for manual snapshot execution

### Network Security

- HTTPS connections to Rubrik Security Cloud
- Optional connectivity verification (ping to cluster)
- Configurable with `-SkipConnectivityCheck`

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### How to Contribute

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Development Guidelines

- Follow PowerShell best practices
- Add comprehensive help documentation
- Include usage examples
- Test on PowerShell 5.1 and 7+
- Update README.md for new features

---

## 📞 Support

### Getting Help

- **GitHub Issues**: https://github.com/mbriotto/New-RscFileSnapshot/issues
- **Rubrik Community**: https://community.rubrik.com
- **Rubrik Support**: Contact your Rubrik representative

### Reporting Issues

When reporting issues, please include:
- PowerShell version (`$PSVersionTable`)
- Script version
- Error messages (full output)
- Steps to reproduce
- Log files (if applicable)

### Feature Requests

Feature requests are welcome! Please open an issue with:
- Clear description of the feature
- Use case / business value
- Example usage (if applicable)

---

## 📜 License

This program is free software: you can redistribute it and/or modify it under the terms of the **GNU General Public License v3.0** as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but **WITHOUT ANY WARRANTY**; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see https://www.gnu.org/licenses/.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

---

## 👤 Author

**GitHub**: [@mbriotto](https://github.com/mbriotto)  
**Repository**: https://github.com/mbriotto/New-RscFileSnapshot

---

## 🎯 Project Roadmap

### Current Version: 1.0
- ✅ Core snapshot functionality
- ✅ Scheduled task automation
- ✅ Service Account management
- ✅ Comprehensive logging
- ✅ Execution policy guidance

### Future Enhancements
- 🔄 Enhanced error recovery
- 🔄 Multi-cluster support
- 🔄 Email notifications
- 🔄 Slack/Teams integration
- 🔄 Advanced scheduling (weekly patterns)
- 🔄 Backup validation
- 🔄 Dashboard/reporting

---

## 📊 Version History

### Version 1.0 (January 2026)
- Initial release
- Core snapshot functionality
- Automated scheduling
- Service Account creation guide
- Comprehensive documentation

---

## 🙏 Acknowledgments

- **Rubrik** for the Rubrik Security Cloud platform
- **Rubrik PowerShell SDK Team** for the excellent tooling
- **Community Contributors** for feedback and suggestions
- **Open Source Community** for PowerShell best practices

---

## 📋 FAQ

### Q: Do I need to configure credentials every time?

**A**: No. After the first run, credentials are stored encrypted and reused automatically.

### Q: Can I run this on Linux/Mac?

**A**: The scheduler is Windows-only (uses Task Scheduler). The snapshot script works on any platform with PowerShell and the Rubrik SDK.

### Q: How do I backup multiple hosts?

**A**: Create separate scheduled tasks for each host:
```powershell
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold" -HostName "SERVER01" -TaskName "Rubrik - Server01"
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold" -HostName "SERVER02" -TaskName "Rubrik - Server02"
```

### Q: What happens if my PC is off at the scheduled time?

**A**: The task is configured with `StartWhenAvailable`, so it runs as soon as the PC is turned on.

### Q: How do I see what was backed up?

**A**: Check the log files:
```powershell
cd C:\Path\To\Logs
Get-ChildItem -Filter "New-RscFileSnapshot_*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | Get-Content
```

### Q: Can I use this with Rubrik CDM (on-premises)?

**A**: This is designed for Rubrik Security Cloud (SaaS). For on-premises CDM, use the Rubrik CDM PowerShell module.

### Q: How long are logs kept?

**A**: Default is 30 days. Configurable with `-LogRetentionDays` parameter:
```powershell
.\New-RscFileSnapshot.ps1 -SlaName "Gold" -LogRetentionDays 7
```

---

## 🚦 Status

![Status: Active](https://img.shields.io/badge/status-active-success.svg)
![Maintenance: Yes](https://img.shields.io/badge/maintained-yes-brightgreen.svg)

This project is actively maintained. Issues and pull requests are welcome!

---

**⭐ If you find this project useful, please consider giving it a star on GitHub!**
