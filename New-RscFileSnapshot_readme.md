# New-RscFileSnapshot

PowerShell script for creating on-demand snapshots of Rubrik Filesets via Rubrik Security Cloud (RSC).

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)

## Overview

`New-RscFileSnapshot.ps1` automates the creation of on-demand backups for Rubrik Filesets. The script connects to Rubrik Security Cloud, identifies the target host and Fileset, and triggers a snapshot using a specified SLA policy.

### Key Features

- **Automatic host detection**: Uses local FQDN if no hostname is specified
- **Automatic cluster discovery**: Extracts cluster IP from host's CdmLink
- **Service Account support**: Automatically configures authentication from JSON file
- **Flexible Fileset selection**: Supports exact names, wildcards, or automatic fallback
- **Comprehensive logging**: File-based logging with automatic rotation
- **Connectivity verification**: Optional ping test to cluster
- **Security**: Automatically deletes Service Account JSON after configuration

---

## Prerequisites

### 1. Install Rubrik PowerShell SDK

```powershell
Install-Module -Name RubrikSecurityCloud -Scope CurrentUser
```

Verify installation:
```powershell
Get-Module -ListAvailable RubrikSecurityCloud
```

### 2. Create Service Account in Rubrik Security Cloud

Follow these steps to create a Service Account and export the credentials:

#### Step-by-Step Guide

1. **Log in to Rubrik Security Cloud**
   - Navigate to https://rubrik.my.rubrik.com (or your organization's RSC URL)
   - Log in with your administrator credentials

2. **Access Service Accounts**
   - Click on your profile icon (top-right corner)
   - Select **Settings** from the dropdown menu
   - In the left sidebar, click **Service Accounts**

3. **Create New Service Account**
   - Click **Create Service Account** button
   - Fill in the required information:
     - **Name**: e.g., `FilesetSnapshotAutomation`
     - **Description**: e.g., `Service account for automated Fileset snapshots`
   - Click **Next**

4. **Assign Permissions**
   
   Assign the following minimum permissions:
   - **Fileset**: Read, On-Demand Backup
   - **SLA Domain**: Read
   - **Host**: Read
   - **Cluster**: Read
   
   Recommended role: **End User** or create a custom role with the above permissions.

5. **Download Credentials**
   - After creating the Service Account, click **Download Credentials**
   - A JSON file will be downloaded (e.g., `service-account-123456.json`)
   - **IMPORTANT**: Save this file securely - you won't be able to download it again

6. **Save JSON File**
   - Copy the downloaded JSON file to the same directory as `Rsc-FileSetSnapshotTool.ps1`
   - The script will automatically detect and configure it on first run
   - The JSON file will be automatically deleted after successful configuration for security

#### Alternative: Manual Authentication

If you prefer not to use a Service Account, you can authenticate manually:

```powershell
Connect-Rsc
```

This will open a browser window for interactive authentication.

---

## Installation

1. **Clone the repository**
```powershell
git clone https://github.com/mbriotto/New-RscFileSnapshot.git
cd New-RscFileSnapshot
```

2. **Download the script** (alternative to cloning)
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/mbriotto/New-RscFileSnapshot/main/New-RscFileSnapshot.ps1" -OutFile "New-RscFileSnapshot.ps1"
```

3. **(Optional) Place the Service Account JSON file** in the same directory

4. **Ensure the Rubrik PowerShell SDK is installed** (see Prerequisites)

---

## Usage

### Basic Syntax

```powershell
.\New-RscFileSnapshot.ps1 -SlaName <SLA> [OPTIONS]
```

### Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `-SlaName` | **Yes** | - | Name of the SLA policy to apply |
| `-HostName` | No | Local FQDN | Target host name in Rubrik |
| `-OsType` | No | `Windows` | Operating system (`Windows` or `Linux`) |
| `-FilesetName` | No | First available | Fileset name (supports wildcards) |
| `-Credential` | No | - | PSCredential for authentication |
| `-SkipConnectivityCheck` | No | `No` | Skip ping test (`Yes` or `No`) |
| `-EnableFileLog` | No | `Yes` | Enable file logging (`Yes` or `No`) |
| `-LogFilePath` | No | `.\Logs` | Log file directory |
| `-LogRetentionDays` | No | `30` | Days to keep log files (1-365) |

### Examples

#### Example 1: Snapshot Local Host
```powershell
.\New-RscFileSnapshot.ps1 -SlaName "Gold"
```
Uses local hostname and first available Fileset.

#### Example 2: Specify Host and Fileset
```powershell
.\New-RscFileSnapshot.ps1 -HostName "FILESRV01" -SlaName "Gold" -FilesetName "UserProfiles"
```

#### Example 3: Linux Host with Wildcard
```powershell
.\New-RscFileSnapshot.ps1 -HostName "ubuntu-server" -OsType Linux -SlaName "Silver" -FilesetName "home-*"
```

#### Example 4: Skip Connectivity Check
```powershell
.\New-RscFileSnapshot.ps1 -SlaName "Bronze" -SkipConnectivityCheck Yes
```

#### Example 5: Custom Credentials
```powershell
$cred = Get-Credential
.\New-RscFileSnapshot.ps1 -SlaName "Gold" -Credential $cred
```

#### Example 6: Custom Log Location
```powershell
.\New-RscFileSnapshot.ps1 -SlaName "Gold" -LogFilePath "C:\Logs\Rubrik" -LogRetentionDays 7
```

#### Example 7: Disable Logging
```powershell
.\New-RscFileSnapshot.ps1 -SlaName "Gold" -EnableFileLog No
```

---

## Logging

### Log File Format

Log files are created with the following naming convention:
```
New-RscFileSnapshot_YYYYMMDD_HHmmss.log
```

Example: `New-RscFileSnapshot_20260117_143022.log`

### Log Location

Default: `.\Logs` (in the script directory)

### Log Content

Each log file includes:
- Script start/end timestamps
- Host and user information
- All operations performed
- Errors and warnings
- Snapshot result (AsyncRequest ID)

### Automatic Cleanup

Logs older than the retention period (default 30 days) are automatically deleted each time the script runs.

---

## Scheduled Tasks (Windows)

To automate snapshots, create a scheduled task:

### Using PowerShell
```powershell
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\Scripts\New-RscFileSnapshot.ps1 -SlaName Gold"

$trigger = New-ScheduledTaskTrigger -Daily -At "2:00AM"

$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName "Rubrik Fileset Backup" `
    -Action $action -Trigger $trigger -Principal $principal `
    -Description "Daily on-demand Fileset snapshot"
```

### Using PowerShell - Advanced Boot Configuration (Recommended)

This configuration executes the snapshot:
- **15 minutes after PC startup** (first run)
- **Every 24 hours** thereafter
- **Skips execution if already run in the last 24 hours**

```powershell
# Define the action
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"C:\Scripts\New-RscFileSnapshot.ps1`" -SlaName `"Gold`"" `
    -WorkingDirectory "C:\Scripts"

# Create boot trigger with 15-minute delay
$triggerBoot = New-ScheduledTaskTrigger -AtStartup

# Create daily backup trigger at 2:00 AM
$triggerDaily = New-ScheduledTaskTrigger -Daily -At "2:00AM"

# Settings to prevent multiple runs within 24 hours
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable `
    -DontStopOnIdleEnd `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 10) `
    -ExecutionTimeLimit (New-TimeSpan -Hours 1) `
    -MultipleInstances IgnoreNew

# Principal (run with highest privileges)
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Register the task with both triggers
Register-ScheduledTask `
    -TaskName "Rubrik Fileset Backup - Auto" `
    -Action $action `
    -Trigger @($triggerBoot, $triggerDaily) `
    -Settings $settings `
    -Principal $principal `
    -Description "Runs Rubrik snapshot 15 min after boot and daily at 2 AM (prevents duplicate runs within 24h)"

# Configure boot trigger with 15-minute delay and 24-hour repetition using COM
$taskService = New-Object -ComObject Schedule.Service
$taskService.Connect()
$taskFolder = $taskService.GetFolder("\")
$task = $taskFolder.GetTask("Rubrik Fileset Backup - Auto")
$taskDefinition = $task.Definition

# Modify the boot trigger (first trigger)
$bootTrigger = $taskDefinition.Triggers.Item(1)
$bootTrigger.Delay = "PT15M"  # 15-minute delay after boot
$bootTrigger.Repetition.Interval = "PT24H"  # Repeat every 24 hours
$bootTrigger.Repetition.Duration = ""  # Run indefinitely
$bootTrigger.Repetition.StopAtDurationEnd = $false

# Save the modified task
$taskFolder.RegisterTaskDefinition(
    "Rubrik Fileset Backup - Auto",
    $taskDefinition,
    6,  # TASK_CREATE_OR_UPDATE
    "SYSTEM",
    $null,
    5   # TASK_LOGON_SERVICE_ACCOUNT
) | Out-Null

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Task Scheduler Configuration Complete" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Task Name:" -ForegroundColor Cyan
Write-Host "  Rubrik Fileset Backup - Auto" -ForegroundColor White
Write-Host ""
Write-Host "Execution Schedule:" -ForegroundColor Cyan
Write-Host "  • First run: 15 minutes after PC startup" -ForegroundColor White
Write-Host "  • Recurring: Every 24 hours from first run" -ForegroundColor White
Write-Host "  • Backup trigger: Daily at 2:00 AM" -ForegroundColor White
Write-Host ""
Write-Host "Duplicate Prevention:" -ForegroundColor Cyan
Write-Host "  • MultipleInstances = IgnoreNew" -ForegroundColor White
Write-Host "  • 24-hour repetition interval prevents overlapping" -ForegroundColor White
Write-Host ""
Write-Host "To verify configuration:" -ForegroundColor Yellow
Write-Host "  Get-ScheduledTask -TaskName 'Rubrik Fileset Backup - Auto' | Get-ScheduledTaskInfo" -ForegroundColor Gray
Write-Host ""
```

**How this works:**
- ✅ **PC boots**: Task waits 15 minutes, then executes snapshot
- ✅ **Next execution**: Exactly 24 hours after first run
- ✅ **Backup trigger**: If PC was off, daily trigger at 2 AM ensures execution
- ✅ **Duplicate prevention**: 
  - `MultipleInstances IgnoreNew` prevents new instances if one is running
  - 24-hour repetition interval ensures only one run per day
  - Both triggers won't conflict due to timing and interval settings

**To manually test the task:**
```powershell
Start-ScheduledTask -TaskName "Rubrik Fileset Backup - Auto"
```

**To check last run time:**
```powershell
Get-ScheduledTask -TaskName "Rubrik Fileset Backup - Auto" | Get-ScheduledTaskInfo | Select-Object LastRunTime, NextRunTime, LastTaskResult
```

### Using Task Scheduler GUI

1. Open Task Scheduler
2. Create Basic Task
3. Set trigger (e.g., daily at 2:00 AM)
4. Action: Start a program
   - Program: `PowerShell.exe`
   - Arguments: `-NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\New-RscFileSnapshot.ps1" -SlaName "Gold"`
5. Run with highest privileges

---

## Troubleshooting

### Common Issues

#### 1. Module Not Found
```
Error: Module RubrikSecurityCloud not found
```
**Solution**: Install the module
```powershell
Install-Module -Name RubrikSecurityCloud -Scope CurrentUser
```

#### 2. Service Account JSON Not Configured
```
Error: No JSON files found in script directory
```
**Solution**: Download Service Account credentials from RSC and place the JSON file in the script directory.

#### 3. Host Not Found
```
Error: Host 'HOSTNAME' not found
```
**Solution**: 
- Verify the hostname matches exactly as shown in Rubrik
- Check the `-OsType` parameter (Windows vs Linux)
- Ensure the host is registered in Rubrik

#### 4. SLA Not Found
```
Error: SLA 'NAME' not found
```
**Solution**: Verify the SLA name matches exactly (case-sensitive) as configured in Rubrik.

#### 5. Cluster Not Reachable
```
Error: Rubrik cluster NOT reachable
```
**Solution**: 
- Check network connectivity
- Verify firewall rules
- Use `-SkipConnectivityCheck Yes` to bypass (not recommended)

#### 6. Multiple Filesets Match
```
Error: Multiple Filesets match 'FS*'
```
**Solution**: Use a more specific name or exact match without wildcards.

---

## Security Considerations

1. **Service Account JSON**: The script automatically deletes the JSON file after configuration for security
2. **Encrypted Credentials**: After running `Set-RscServiceAccountFile`, credentials are stored in an encrypted XML file:
   - **Location**: `$PROFILE\..\rubrik-powershell-sdk\rsc_service_account_default.xml`
   - **Windows**: `C:\Users\YourUser\Documents\WindowsPowerShell\rubrik-powershell-sdk\rsc_service_account_default.xml`
   - **Linux/Mac**: `~/.config/powershell/rubrik-powershell-sdk/rsc_service_account_default.xml`
   - **Encryption**: Uses Windows DPAPI (Windows) or platform-specific encryption (Linux/Mac)
   - **Access**: Only the user who created the file can decrypt and use it
3. **File Verification**: To check if the encrypted file exists:
   ```powershell
   $encryptedPath = Join-Path (Split-Path $PROFILE) "rubrik-powershell-sdk\rsc_service_account_default.xml"
   Test-Path $encryptedPath
   ```
4. **Credentials**: Never store credentials in scripts - use `-Credential` parameter or interactive authentication
5. **Permissions**: Grant minimum required permissions to Service Account
6. **Logs**: Log files may contain sensitive information - secure the log directory
7. **Scheduled Tasks**: Use service accounts with minimum privileges

---

## Exit Codes

- **0**: Success or help requested
- **1**: Error occurred (check logs for details)

---

## Support

For issues and questions:
- **GitHub Issues**: https://github.com/mbriotto/New-RscFileSnapshot/issues
- **Rubrik PowerShell SDK**: https://github.com/rubrikinc/rubrik-powershell-sdk
- **Rubrik Security Cloud**: Contact Rubrik Support

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

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