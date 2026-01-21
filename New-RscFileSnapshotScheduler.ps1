<#
.SYNOPSIS
    Creates a Windows Scheduled Task to automate Rubrik Fileset snapshots.

.DESCRIPTION
    This script creates a scheduled task that executes New-RscFileSnapshot.ps1 with configurable parameters.
    The task can be configured to run at PC startup (with delay) and/or at recurring intervals,
    with built-in duplicate prevention to avoid multiple executions within the same interval.

.NOTES
    Version:        1.0
    Author:         Matteo Briotto
    Creation Date:  January 2026
    Purpose/Change: Initial release - Automated task scheduling for Rubrik snapshots

.LINK
    https://github.com/mbriotto/rubrik-scripts

.PARAMETER ScriptPath
    Full path to the New-RscFileSnapshot.ps1 script.
    **Optional**. Default: Same directory as this scheduler script.

.PARAMETER TaskName
    Name of the scheduled task to create.
    **Optional**. Default: "Rubrik Fileset Backup - Auto"

.PARAMETER SlaName
    Name of the SLA to apply to the snapshot. **Required** (passed to New-RscFileSnapshot.ps1).

.PARAMETER HostName
    Name of the host for the snapshot. **Optional** (passed to New-RscFileSnapshot.ps1).

.PARAMETER OsType
    Host operating system. Valid values: Windows, Linux.
    **Optional**. Default: Windows (passed to New-RscFileSnapshot.ps1).

.PARAMETER FilesetName
    Name of the Fileset to use. Supports wildcards.
    **Optional** (passed to New-RscFileSnapshot.ps1).

.PARAMETER SkipConnectivityCheck
    Skip ping test to Rubrik cluster. Valid values: Yes, No.
    **Optional**. Default: No (passed to New-RscFileSnapshot.ps1).

.PARAMETER EnableBootExecution
    Enable execution at PC startup.
    Valid values: Yes, No. **Default: Yes**.

.PARAMETER BootDelayMinutes
    Delay in minutes after PC startup before first execution.
    **Optional**. Default: 15 minutes.

.PARAMETER EnableRecurringSchedule
    Enable recurring execution at specific time.
    Valid values: Yes, No. **Default: Yes**.

.PARAMETER RecurringTime
    Time for recurring execution (24-hour format, e.g., "02:00").
    **Optional**. Default: "02:00" (2:00 AM).

.PARAMETER RecurringIntervalHours
    Interval in hours for recurring execution.
    **Optional**. Default: 24 hours. Range: 1-168 (1 week).

.PARAMETER PreventDuplicateExecution
    Prevent execution at boot if already run within the recurring interval.
    Valid values: Yes, No. **Default: Yes**.

.PARAMETER RunAsUser
    User account to run the task as.
    **Optional**. Default: SYSTEM.
    Valid values: SYSTEM, CurrentUser, or specific user account.

.PARAMETER Help
    Displays help and exits.

.PARAMETER ?
    Alias for Help (displays help and exits).

.EXAMPLE
    .\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold"
    Creates task with default settings: boot execution after 15 min, daily at 2 AM

.EXAMPLE
    .\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold" -RecurringTime "14:00" -RecurringIntervalHours 12
    Creates task: boot execution after 15 min, recurring every 12 hours starting at 2 PM

.EXAMPLE
    .\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold" -EnableBootExecution No
    Creates task: only recurring daily at 2 AM (no boot execution)

.EXAMPLE
    .\New-RscFileSnapshotScheduler.ps1 -SlaName "Silver" -BootDelayMinutes 30 -PreventDuplicateExecution No
    Creates task: boot execution after 30 min (allows duplicates), daily at 2 AM

.EXAMPLE
    .\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold" -ScriptPath ".\New-RscFileSnapshot.ps1" -TaskName "Custom Backup Task"
    Creates task with custom script path and task name

.EXAMPLE
    .\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold" -HostName "FILESRV01" -FilesetName "UserProfiles" -RunAsUser "CurrentUser"
    Creates task with specific host, fileset, and running as current user

.NOTES
    Requirements:
      - Windows operating system
      - Administrator privileges (for creating scheduled tasks)
      - New-RscFileSnapshot.ps1 script accessible at specified path

    Default configuration:
      - Task runs at PC startup with 15-minute delay
      - Task runs daily at 2:00 AM
      - Duplicate prevention enabled (won't run at boot if already executed recently)
      - Runs with SYSTEM account privileges
      - Multiple instances are ignored if one is already running

    Exit codes:
      - Exit 0: successful task creation or help requested
      - Exit 1: error occurred

.VERSION
    1.0 - Initial release

.AUTHOR
    GitHub: https://github.com/mbriotto
    Repository: https://github.com/mbriotto/New-RscFileSnapshot

.LICENSE
    GPL-3.0 License
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.
    
    You should have received a copy of the GNU General Public License
    along with this program. If not, see <https://www.gnu.org/licenses/>.
#>

[CmdletBinding()]
param(
    [string] $ScriptPath,

    [string] $TaskName = "Rubrik Fileset Backup - Auto",

    [ValidateNotNullOrEmpty()]
    [string] $SlaName,

    [string] $HostName,

    [ValidateSet('Linux','Windows')]
    [string] $OsType = 'Windows',

    [string] $FilesetName,

    [ValidateSet('Yes','No')]
    [string] $SkipConnectivityCheck = 'No',

    [ValidateSet('Yes','No')]
    [string] $EnableBootExecution = 'Yes',

    [ValidateRange(1,1440)]
    [int] $BootDelayMinutes = 15,

    [ValidateSet('Yes','No')]
    [string] $EnableRecurringSchedule = 'Yes',

    [ValidatePattern('^([01]?[0-9]|2[0-3]):[0-5][0-9]$')]
    [string] $RecurringTime = "02:00",

    [ValidateRange(1,168)]
    [int] $RecurringIntervalHours = 24,

    [ValidateSet('Yes','No')]
    [string] $PreventDuplicateExecution = 'Yes',

    [ValidateSet('SYSTEM','CurrentUser')]
    [string] $RunAsUser = 'SYSTEM',

    [ValidateSet('Yes','No')]
    [string] $EnableFileLog = 'Yes',

    [string] $LogFilePath = "$PSScriptRoot\Logs",

    [ValidateRange(1,365)]
    [int] $LogRetentionDays = 30,

    [Alias('?')]
    [switch] $Help
)

#region --- HELP ---------------------------------------------------------------

function Show-Help {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host " RUBRIK FILESET SNAPSHOT TASK SCHEDULER " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  .\New-RscFileSnapshotScheduler.ps1 -SlaName <SLA> [-ScriptPath <Path>] [OPTIONS]"
    Write-Host ""
    Write-Host "NOTES:" -ForegroundColor Yellow
    Write-Host "  -SlaName is REQUIRED."
    Write-Host "  -ScriptPath defaults to the same directory as this script."
    Write-Host "  -Boot execution is ENABLED by default (15 min delay after startup)."
    Write-Host "  -Recurring schedule is ENABLED by default (daily at 02:00)."
    Write-Host "  -Duplicate prevention is ENABLED by default."
    Write-Host "  -Task runs with SYSTEM account by default."
    Write-Host ""
    Write-Host "SCHEDULE OPTIONS:" -ForegroundColor Yellow
    Write-Host "  -EnableBootExecution Yes|No        Run at PC startup (default: Yes)"
    Write-Host "  -BootDelayMinutes <1-1440>         Delay after boot (default: 15)"
    Write-Host "  -EnableRecurringSchedule Yes|No    Recurring execution (default: Yes)"
    Write-Host "  -RecurringTime <HH:MM>             Execution time (default: 02:00)"
    Write-Host "  -RecurringIntervalHours <1-168>    Interval in hours (default: 24)"
    Write-Host ""
    Write-Host "SNAPSHOT PARAMETERS (passed to New-RscFileSnapshot.ps1):" -ForegroundColor Yellow
    Write-Host "  -HostName, -OsType, -FilesetName, -SkipConnectivityCheck"
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  .\New-RscFileSnapshotScheduler.ps1 -SlaName Gold"
    Write-Host "  .\New-RscFileSnapshotScheduler.ps1 -SlaName Gold -RecurringIntervalHours 12"
    Write-Host "  .\New-RscFileSnapshotScheduler.ps1 -SlaName Gold -EnableBootExecution No"
    Write-Host "  .\New-RscFileSnapshotScheduler.ps1 -SlaName Silver -HostName FILESRV01"
    Write-Host ""
    Write-Host "TIPS:" -ForegroundColor Yellow
    Write-Host "  - Run PowerShell as Administrator to create scheduled tasks."
    Write-Host "  - Task uses execution policy bypass automatically."
    Write-Host "  - Duplicate prevention avoids boot run if recently executed."
    Write-Host ""
}

if ($Help) {
    Show-Help
    exit 0
}

# Verify SlaName is required
if (-not $PSBoundParameters.ContainsKey('SlaName') -or [string]::IsNullOrWhiteSpace($SlaName)) {
    Write-Host "ERROR: Parameter -SlaName is required." -ForegroundColor Red
    Write-Host ""
    Show-Help
    exit 1
}

#endregion

#region --- LOGGING SETUP ------------------------------------------------------

$script:LogFile = $null
$script:UseFileLog = ($EnableFileLog -eq 'Yes')

function Initialize-Logging {
    if (-not $script:UseFileLog) {
        return
    }

    try {
        # Create log folder if it doesn't exist
        if (-not (Test-Path -Path $LogFilePath)) {
            New-Item -Path $LogFilePath -ItemType Directory -Force | Out-Null
        }

        # Log file name with timestamp
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $logFileName = "New-RscFileSnapshotScheduler_${timestamp}.log"
        $script:LogFile = Join-Path -Path $LogFilePath -ChildPath $logFileName

        # Write log header
        $header = @"
================================================================================
RUBRIK FILESET SNAPSHOT TASK SCHEDULER - LOG
================================================================================
Script started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Host: $env:COMPUTERNAME
User: $env:USERNAME
================================================================================

"@
        Add-Content -Path $script:LogFile -Value $header -Encoding UTF8

        # Perform cleanup of old logs
        Cleanup-OldLogs

    } catch {
        Write-Host "Warning: Could not initialize file logging: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "Continuing with console logging only..." -ForegroundColor Yellow
        $script:UseFileLog = $false
    }
}

function Cleanup-OldLogs {
    if (-not $script:UseFileLog) {
        return
    }

    try {
        $cutoffDate = (Get-Date).AddDays(-$LogRetentionDays)
        $logFiles = Get-ChildItem -Path $LogFilePath -Filter "New-RscFileSnapshotScheduler_*.log" -File -ErrorAction SilentlyContinue

        $deletedCount = 0
        foreach ($file in $logFiles) {
            if ($file.LastWriteTime -lt $cutoffDate) {
                Remove-Item -Path $file.FullName -Force
                $deletedCount++
            }
        }

        if ($deletedCount -gt 0) {
            Write-Log -Message "Log cleanup: deleted $deletedCount files older than $LogRetentionDays days" -Level Info
        }
    } catch {
        # Silent error
    }
}

function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string] $Message,
        [ValidateSet('Info','Warning','Error','Success')]
        [string] $Level = 'Info'
    )
    
    # Timestamp for log
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # File output (if enabled)
    if ($script:UseFileLog -and $script:LogFile) {
        try {
            Add-Content -Path $script:LogFile -Value $logMessage -Encoding UTF8
        } catch {
            # Silent error
        }
    }
}

# Initialize logging system
Initialize-Logging

#endregion

#region --- FUNCTIONS ----------------------------------------------------------

function Write-ColorOutput {
    param(
        [Parameter(Mandatory)]
        [string] $Message,
        [ValidateSet('Info','Success','Warning','Error')]
        [string] $Level = 'Info'
    )
    
    switch ($Level) {
        'Info'    { Write-Host $Message -ForegroundColor Cyan }
        'Success' { Write-Host $Message -ForegroundColor Green }
        'Warning' { Write-Host $Message -ForegroundColor Yellow }
        'Error'   { Write-Host $Message -ForegroundColor Red }
    }
    
    # Also write to log file
    Write-Log -Message $Message -Level $Level
}

#endregion

#region --- VALIDATION ---------------------------------------------------------

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " RUBRIK FILESET SNAPSHOT TASK SCHEDULER" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-ColorOutput "ERROR: This script requires Administrator privileges to create scheduled tasks." -Level Error
    Write-ColorOutput "Please run PowerShell as Administrator and try again." -Level Warning
    exit 1
}

Write-ColorOutput "[+] Running with Administrator privileges" -Level Success

# Determine script path
if ([string]::IsNullOrWhiteSpace($ScriptPath)) {
    $scriptDir = $PSScriptRoot
    if ([string]::IsNullOrWhiteSpace($scriptDir)) {
        $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    $ScriptPath = Join-Path $scriptDir "New-RscFileSnapshot.ps1"
    Write-ColorOutput "ScriptPath not specified, using default: $ScriptPath" -Level Info
}

# Validate script exists
if (-not (Test-Path -Path $ScriptPath)) {
    Write-ColorOutput "ERROR: New-RscFileSnapshot.ps1 not found at: $ScriptPath" -Level Error
    Write-ColorOutput "Please specify the correct path using -ScriptPath parameter." -Level Warning
    exit 1
}

Write-ColorOutput "[+] Found New-RscFileSnapshot.ps1 at: $ScriptPath" -Level Success

# Validate at least one execution method is enabled
if ($EnableBootExecution -eq 'No' -and $EnableRecurringSchedule -eq 'No') {
    Write-ColorOutput "ERROR: At least one execution method must be enabled." -Level Error
    Write-ColorOutput "Set either -EnableBootExecution Yes or -EnableRecurringSchedule Yes" -Level Warning
    exit 1
}

#endregion

#region --- BUILD COMMAND ARGUMENTS --------------------------------------------

Write-Host ""
Write-ColorOutput "Building command arguments..." -Level Info

# Build arguments for New-RscFileSnapshot.ps1
$arguments = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$ScriptPath`"", "-SlaName", "`"$SlaName`"")

if ($PSBoundParameters.ContainsKey('HostName') -and -not [string]::IsNullOrWhiteSpace($HostName)) {
    $arguments += "-HostName"
    $arguments += "`"$HostName`""
}

if ($PSBoundParameters.ContainsKey('OsType')) {
    $arguments += "-OsType"
    $arguments += $OsType
}

if ($PSBoundParameters.ContainsKey('FilesetName') -and -not [string]::IsNullOrWhiteSpace($FilesetName)) {
    $arguments += "-FilesetName"
    $arguments += "`"$FilesetName`""
}

if ($PSBoundParameters.ContainsKey('SkipConnectivityCheck')) {
    $arguments += "-SkipConnectivityCheck"
    $arguments += $SkipConnectivityCheck
}

# ALWAYS enable file logging for scheduled tasks
$arguments += "-EnableFileLog"
$arguments += "Yes"

# Use the same log path for both scheduler and snapshot script
$arguments += "-LogFilePath"
$arguments += "`"$LogFilePath`""

# Use the same retention for both
$arguments += "-LogRetentionDays"
$arguments += $LogRetentionDays

$argumentString = $arguments -join " "
Write-ColorOutput "Command: PowerShell.exe $argumentString" -Level Info

#endregion

#region --- SERVICE ACCOUNT CHECK ----------------------------------------------

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Yellow
Write-Host " IMPORTANT: SERVICE ACCOUNT CONFIGURATION" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "The scheduled task will run under SYSTEM account context." -ForegroundColor White
Write-Host ""
Write-Host "FOR FIRST-TIME EXECUTION:" -ForegroundColor Yellow
Write-Host "  1. Place the Service Account JSON file in:" -ForegroundColor White
$scriptDir = Split-Path $ScriptPath -Parent
Write-Host "     $scriptDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "  2. When the scheduled task runs for the FIRST time:" -ForegroundColor White
Write-Host "     - New-RscFileSnapshot.ps1 detects the JSON file" -ForegroundColor Gray
Write-Host "     - Configures credentials under SYSTEM account profile" -ForegroundColor Gray
Write-Host "     - Deletes the JSON file automatically (security)" -ForegroundColor Gray
Write-Host ""
Write-Host "FOR SUBSEQUENT EXECUTIONS:" -ForegroundColor Yellow
Write-Host "  - No JSON file needed" -ForegroundColor White
Write-Host "  - Task uses existing SYSTEM account credentials" -ForegroundColor White
Write-Host ""

# Check for JSON file
$jsonFiles = @(Get-ChildItem -Path $scriptDir -Filter "*.json" -File -ErrorAction SilentlyContinue)

if ($jsonFiles.Count -gt 0) {
    Write-Host "STATUS: Service Account JSON file(s) found:" -ForegroundColor Green
    foreach ($file in $jsonFiles) {
        Write-Host "  [+] $($file.Name)" -ForegroundColor Green
    }
    Write-Host ""
    Write-Host "Ready for FIRST-TIME execution." -ForegroundColor Green
    Write-Log -Message "JSON files found: $($jsonFiles.Count)" -Level Info
} else {
    Write-Host "STATUS: No Service Account JSON file found." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Assuming SYSTEM account credentials are already configured." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "If the task fails on first run, you need to:" -ForegroundColor Yellow
    Write-Host "  1. Place Service Account JSON in: $scriptDir" -ForegroundColor White
    Write-Host "  2. Run the task again (it will auto-configure)" -ForegroundColor White
    Write-Host ""
    Write-Log -Message "No JSON files found - assuming credentials configured" -Level Warning
}

Write-Host "==========================================================" -ForegroundColor Yellow
Write-Host ""

Write-Host "Press any key to continue with task creation..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Write-Host ""

#endregion

#region --- CREATE SCHEDULED TASK ----------------------------------------------

Write-Host ""
Write-ColorOutput "Creating scheduled task: $TaskName" -Level Info

try {
    # Check if task already exists and remove it completely
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-ColorOutput "Task '$TaskName' already exists. Removing old task..." -Level Warning
        try {
            # Stop the task if running
            Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            # Unregister the task
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
            Start-Sleep -Seconds 1
            Write-ColorOutput "Old task removed successfully." -Level Success
        } catch {
            Write-ColorOutput "Warning: Could not remove old task cleanly: $($_.Exception.Message)" -Level Warning
            Write-ColorOutput "Attempting to continue anyway..." -Level Info
        }
    }

    # Create action
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
        -Argument $argumentString `
        -WorkingDirectory (Split-Path $ScriptPath -Parent)

    Write-ColorOutput "[+] Task action created" -Level Success

    # Create triggers
    $triggers = @()

    # Boot trigger (simple, without delay - will be configured later via COM)
    if ($EnableBootExecution -eq 'Yes') {
        $triggerBoot = New-ScheduledTaskTrigger -AtStartup
        $triggers += $triggerBoot
        Write-ColorOutput "[+] Boot trigger added (delay will be configured)" -Level Success
    }

    # Recurring trigger
    if ($EnableRecurringSchedule -eq 'Yes') {
        $triggerRecurring = New-ScheduledTaskTrigger -Daily -At $RecurringTime
        $triggers += $triggerRecurring
        Write-ColorOutput "[+] Recurring trigger added (time: $RecurringTime)" -Level Success
    }

    # Create settings
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RunOnlyIfNetworkAvailable `
        -DontStopOnIdleEnd `
        -RestartCount 3 `
        -RestartInterval (New-TimeSpan -Minutes 10) `
        -ExecutionTimeLimit (New-TimeSpan -Hours 2) `
        -MultipleInstances IgnoreNew

    Write-ColorOutput "[+] Task settings configured" -Level Success

    # Create principal
    if ($RunAsUser -eq 'SYSTEM') {
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        Write-ColorOutput "[+] Task will run as: SYSTEM" -Level Success
    } else {
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $principal = New-ScheduledTaskPrincipal -UserId $currentUser -LogonType Interactive -RunLevel Highest
        Write-ColorOutput "[+] Task will run as: $currentUser" -Level Success
    }

    # Register task
    $task = Register-ScheduledTask `
        -TaskName $TaskName `
        -Action $action `
        -Trigger $triggers `
        -Settings $settings `
        -Principal $principal `
        -Description "Automated Rubrik Fileset snapshot using New-RscFileSnapshot.ps1"

    Write-ColorOutput "[+] Scheduled task registered successfully" -Level Success

    # Configure boot trigger with delay and repetition using COM (if boot execution enabled)
    if ($EnableBootExecution -eq 'Yes') {
        Write-Host ""
        Write-ColorOutput "Configuring advanced trigger settings..." -Level Info
        
        try {
            $taskService = New-Object -ComObject Schedule.Service
            $taskService.Connect()
            $taskFolder = $taskService.GetFolder("\")
            $task = $taskFolder.GetTask($TaskName)
            $taskDefinition = $task.Definition

            # Find boot trigger (it's the first one if enabled)
            $bootTriggerIndex = 1
            $bootTrigger = $taskDefinition.Triggers.Item($bootTriggerIndex)
            
            # Set delay
            $bootTrigger.Delay = "PT$($BootDelayMinutes)M"
            Write-ColorOutput "[+] Boot delay set to $BootDelayMinutes minutes" -Level Success
            
            # Set repetition interval if duplicate prevention is disabled
            if ($PreventDuplicateExecution -eq 'No') {
                $bootTrigger.Repetition.Interval = "PT$($RecurringIntervalHours)H"
                $bootTrigger.Repetition.Duration = ""
                $bootTrigger.Repetition.StopAtDurationEnd = $false
                Write-ColorOutput "[+] Boot trigger will repeat every $RecurringIntervalHours hours" -Level Success
            } else {
                # If duplicate prevention is enabled, don't set repetition on boot trigger
                # The recurring trigger will handle regular executions
                Write-ColorOutput "[+] Duplicate prevention enabled (boot won't repeat)" -Level Success
            }

            # Configure recurring trigger repetition if enabled
            if ($EnableRecurringSchedule -eq 'Yes') {
                $recurringTriggerIndex = if ($EnableBootExecution -eq 'Yes') { 2 } else { 1 }
                $recurringTrigger = $taskDefinition.Triggers.Item($recurringTriggerIndex)
                
                if ($RecurringIntervalHours -lt 24) {
                    $recurringTrigger.Repetition.Interval = "PT$($RecurringIntervalHours)H"
                    $recurringTrigger.Repetition.Duration = "P1D"  # Repeat for 1 day
                    $recurringTrigger.Repetition.StopAtDurationEnd = $false
                    Write-ColorOutput "[+] Recurring trigger will repeat every $RecurringIntervalHours hours" -Level Success
                }
            }

            # Save the modified task
            $taskFolder.RegisterTaskDefinition(
                $TaskName,
                $taskDefinition,
                6,  # TASK_CREATE_OR_UPDATE
                $principal.UserId,
                $null,
                $principal.LogonType
            ) | Out-Null

            Write-ColorOutput "[+] Advanced trigger configuration completed" -Level Success
            
        } catch {
            Write-ColorOutput "Warning: Could not configure advanced trigger settings: $($_.Exception.Message)" -Level Warning
            Write-ColorOutput "Task created but boot delay may need manual configuration in Task Scheduler" -Level Warning
        }
    }

} catch {
    Write-ColorOutput "ERROR creating scheduled task: $($_.Exception.Message)" -Level Error
    exit 1
}

#endregion

#region --- SUMMARY ------------------------------------------------------------

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host " TASK SCHEDULER CONFIGURATION COMPLETE" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Green
Write-Host ""

Write-Host "Task Name:" -ForegroundColor Cyan
Write-Host "  $TaskName" -ForegroundColor White
Write-Host ""

Write-Host "Script Location:" -ForegroundColor Cyan
Write-Host "  $ScriptPath" -ForegroundColor White
Write-Host ""

Write-Host "SLA Policy:" -ForegroundColor Cyan
Write-Host "  $SlaName" -ForegroundColor White
Write-Host ""

if ($PSBoundParameters.ContainsKey('HostName') -and -not [string]::IsNullOrWhiteSpace($HostName)) {
    Write-Host "Target Host:" -ForegroundColor Cyan
    Write-Host "  $HostName ($OsType)" -ForegroundColor White
    Write-Host ""
}

if ($PSBoundParameters.ContainsKey('FilesetName') -and -not [string]::IsNullOrWhiteSpace($FilesetName)) {
    Write-Host "Fileset:" -ForegroundColor Cyan
    Write-Host "  $FilesetName" -ForegroundColor White
    Write-Host ""
}

Write-Host "Execution Schedule:" -ForegroundColor Cyan
if ($EnableBootExecution -eq 'Yes') {
    Write-Host "  [+] Boot execution: Enabled ($BootDelayMinutes minutes after startup)" -ForegroundColor White
    if ($PreventDuplicateExecution -eq 'Yes') {
        Write-Host "       - Duplicate prevention: Active" -ForegroundColor Gray
    } else {
        Write-Host "       - Will repeat every $RecurringIntervalHours hours from boot" -ForegroundColor Gray
    }
} else {
    Write-Host "  [-] Boot execution: Disabled" -ForegroundColor DarkGray
}

if ($EnableRecurringSchedule -eq 'Yes') {
    Write-Host "  [+] Recurring: Daily at $RecurringTime" -ForegroundColor White
    if ($RecurringIntervalHours -lt 24) {
        Write-Host "       - Repeats every $RecurringIntervalHours hours" -ForegroundColor Gray
    }
} else {
    Write-Host "  [-] Recurring schedule: Disabled" -ForegroundColor DarkGray
}
Write-Host ""

Write-Host "Run As:" -ForegroundColor Cyan
if ($RunAsUser -eq 'SYSTEM') {
    Write-Host "  SYSTEM account" -ForegroundColor White
} else {
    Write-Host "  $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)" -ForegroundColor White
}
Write-Host ""

Write-Host "Logging:" -ForegroundColor Cyan
Write-Host "  - Task execution logs: $LogFilePath" -ForegroundColor White
Write-Host "  - Log retention: $LogRetentionDays days" -ForegroundColor White
Write-Host "  - Log file pattern: New-RscFileSnapshot_*.log" -ForegroundColor Gray
Write-Host ""

Write-Host "Execution Settings:" -ForegroundColor Cyan
Write-Host "  - Multiple instances: Ignored (only one runs at a time)" -ForegroundColor White
Write-Host "  - Network required: Yes" -ForegroundColor White
Write-Host "  - Run on batteries: Yes" -ForegroundColor White
Write-Host "  - Execution time limit: 2 hours" -ForegroundColor White
Write-Host ""

Write-Host "Verification Commands:" -ForegroundColor Yellow
Write-Host "  # View task details" -ForegroundColor Gray
Write-Host "  Get-ScheduledTask -TaskName '$TaskName' | Format-List *" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  # Check last/next run time" -ForegroundColor Gray
Write-Host "  Get-ScheduledTask -TaskName '$TaskName' | Get-ScheduledTaskInfo" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  # Test task execution" -ForegroundColor Gray
Write-Host "  Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  # View task history" -ForegroundColor Gray
Write-Host "  Get-WinEvent -LogName 'Microsoft-Windows-TaskScheduler/Operational' | Where-Object {`$_.Message -like '*$TaskName*'} | Select-Object -First 10" -ForegroundColor DarkGray
Write-Host ""

Write-Host "==========================================================" -ForegroundColor Green
Write-Host ""

Write-ColorOutput "Task created successfully! The backup will run according to the configured schedule." -Level Success
Write-Host ""

#endregion

#region --- TASK EXECUTION PROMPT ----------------------------------------------

if ($script:UseFileLog -and $script:LogFile) {
    Write-Host "Log File:" -ForegroundColor Cyan
    Write-Host "  $script:LogFile" -ForegroundColor White
    Write-Host "  Retention: $LogRetentionDays days" -ForegroundColor Gray
    Write-Host ""
}

Write-Host ""
Write-Host "Would you like to run the task now to verify it works? (Y/N): " -ForegroundColor Yellow -NoNewline
$response = Read-Host

if ($response -eq 'Y' -or $response -eq 'y') {
    Write-Host ""
    Write-ColorOutput "Starting task execution..." -Level Info
    Write-Host ""
    
    try {
        Start-ScheduledTask -TaskName $TaskName -ErrorAction Stop
        Write-Host "[+] Task started successfully!" -ForegroundColor Green
        Write-Log -Message "Task started successfully" -Level Success
        
        Write-Host ""
        Write-Host "Waiting 15 seconds to check task status..." -ForegroundColor Gray
        Start-Sleep -Seconds 15
        
        $taskInfo = Get-ScheduledTaskInfo -TaskName $TaskName -ErrorAction Stop
        $taskState = (Get-ScheduledTask -TaskName $TaskName).State
        
        Write-Host ""
        Write-Host "Task Status:" -ForegroundColor Cyan
        Write-Host "  State: $taskState" -ForegroundColor White
        Write-Host "  Last Run: $($taskInfo.LastRunTime)" -ForegroundColor White
        Write-Host "  Result Code: $($taskInfo.LastTaskResult)" -ForegroundColor White
        Write-Host ""
        
        if ($taskInfo.LastTaskResult -eq 0) {
            Write-Host "[SUCCESS] Task completed without errors!" -ForegroundColor Green
            Write-Log -Message "Task execution successful (exit code 0)" -Level Success
        } elseif ($taskInfo.LastTaskResult -eq 267009) {
            Write-Host "[RUNNING] Task is still running..." -ForegroundColor Cyan
            Write-Host "Check Task Scheduler or logs for progress" -ForegroundColor Gray
            Write-Log -Message "Task execution in progress" -Level Info
        } else {
            Write-Host "[WARNING] Task returned code: $($taskInfo.LastTaskResult)" -ForegroundColor Yellow
            Write-Host "Check Event Viewer or task history for details" -ForegroundColor Yellow
            Write-Log -Message "Task execution completed with code: $($taskInfo.LastTaskResult)" -Level Warning
        }
        
    } catch {
        Write-Host "[ERROR] Failed to start task: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log -Message "Failed to start task: $($_.Exception.Message)" -Level Error
    }
    
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "Task execution skipped." -ForegroundColor Gray
    Write-Host ""
    Write-Host "You can run the task manually later with:" -ForegroundColor Cyan
    Write-Host "  Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor White
    Write-Host ""
    Write-Log -Message "User skipped task execution" -Level Info
}

#endregion

#region --- FINAL MESSAGE ------------------------------------------------------

Write-Host "==========================================================" -ForegroundColor Green
Write-Host ""

if ($script:UseFileLog -and $script:LogFile) {
    $footer = @"

================================================================================
Script completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Result: SUCCESS
================================================================================
"@
    Add-Content -Path $script:LogFile -Value $footer -Encoding UTF8
}

#endregion

exit 0
