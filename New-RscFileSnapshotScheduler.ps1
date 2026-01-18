<#
.SYNOPSIS
    Creates a Windows Scheduled Task to automate Rubrik Fileset snapshots.

.DESCRIPTION
    This script creates a scheduled task that executes New-RscFileSnapshot.ps1 with configurable parameters.
    The task can be configured to run at PC startup (with delay) and/or at recurring intervals,
    with built-in duplicate prevention to avoid multiple executions within the same interval.

.LINK
    https://github.com/mbriotto/New-RscFileSnapshot

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
    .\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold" -ScriptPath "C:\Scripts\New-RscFileSnapshot.ps1" -TaskName "Custom Backup Task"
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

Write-ColorOutput "âœ" Running with Administrator privileges" -Level Success

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

Write-ColorOutput "âœ" Found New-RscFileSnapshot.ps1 at: $ScriptPath" -Level Success

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

$argumentString = $arguments -join " "
Write-ColorOutput "Command: PowerShell.exe $argumentString" -Level Info

#endregion

#region --- CREATE SCHEDULED TASK ----------------------------------------------

Write-Host ""
Write-ColorOutput "Creating scheduled task: $TaskName" -Level Info

try {
    # Check if task already exists
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-ColorOutput "Task '$TaskName' already exists. Removing old task..." -Level Warning
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-ColorOutput "Old task removed successfully." -Level Success
    }

    # Create action
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
        -Argument $argumentString `
        -WorkingDirectory (Split-Path $ScriptPath -Parent)

    Write-ColorOutput "âœ" Task action created" -Level Success

    # Create triggers
    $triggers = @()

    # Boot trigger
    if ($EnableBootExecution -eq 'Yes') {
        $triggerBoot = New-ScheduledTaskTrigger -AtStartup
        $triggers += $triggerBoot
        Write-ColorOutput "âœ" Boot trigger added (delay: $BootDelayMinutes minutes)" -Level Success
    }

    # Recurring trigger
    if ($EnableRecurringSchedule -eq 'Yes') {
        $triggerRecurring = New-ScheduledTaskTrigger -Daily -At $RecurringTime
        $triggers += $triggerRecurring
        Write-ColorOutput "âœ" Recurring trigger added (time: $RecurringTime, interval: $RecurringIntervalHours hours)" -Level Success
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

    Write-ColorOutput "âœ" Task settings configured" -Level Success

    # Create principal
    if ($RunAsUser -eq 'SYSTEM') {
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        Write-ColorOutput "âœ" Task will run as: SYSTEM" -Level Success
    } else {
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $principal = New-ScheduledTaskPrincipal -UserId $currentUser -LogonType Interactive -RunLevel Highest
        Write-ColorOutput "âœ" Task will run as: $currentUser" -Level Success
    }

    # Register task
    $task = Register-ScheduledTask `
        -TaskName $TaskName `
        -Action $action `
        -Trigger $triggers `
        -Settings $settings `
        -Principal $principal `
        -Description "Automated Rubrik Fileset snapshot using New-RscFileSnapshot.ps1"

    Write-ColorOutput "âœ" Scheduled task registered successfully" -Level Success

    # Configure boot trigger with delay and repetition using COM (if boot execution enabled)
    if ($EnableBootExecution -eq 'Yes') {
        Write-Host ""
        Write-ColorOutput "Configuring advanced trigger settings..." -Level Info
        
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
        Write-ColorOutput "âœ" Boot delay set to $BootDelayMinutes minutes" -Level Success
        
        # Set repetition interval if duplicate prevention is disabled
        if ($PreventDuplicateExecution -eq 'No') {
            $bootTrigger.Repetition.Interval = "PT$($RecurringIntervalHours)H"
            $bootTrigger.Repetition.Duration = ""
            $bootTrigger.Repetition.StopAtDurationEnd = $false
            Write-ColorOutput "âœ" Boot trigger will repeat every $RecurringIntervalHours hours" -Level Success
        } else {
            # If duplicate prevention is enabled, don't set repetition on boot trigger
            # The recurring trigger will handle regular executions
            Write-ColorOutput "âœ" Duplicate prevention enabled (boot won't repeat)" -Level Success
        }

        # Configure recurring trigger repetition if enabled
        if ($EnableRecurringSchedule -eq 'Yes') {
            $recurringTriggerIndex = if ($EnableBootExecution -eq 'Yes') { 2 } else { 1 }
            $recurringTrigger = $taskDefinition.Triggers.Item($recurringTriggerIndex)
            
            if ($RecurringIntervalHours -lt 24) {
                $recurringTrigger.Repetition.Interval = "PT$($RecurringIntervalHours)H"
                $recurringTrigger.Repetition.Duration = "P1D"  # Repeat for 1 day
                $recurringTrigger.Repetition.StopAtDurationEnd = $false
                Write-ColorOutput "âœ" Recurring trigger will repeat every $RecurringIntervalHours hours" -Level Success
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

        Write-ColorOutput "âœ" Advanced trigger configuration completed" -Level Success
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
    Write-Host "  âœ" Boot execution: Enabled ($BootDelayMinutes minutes after startup)" -ForegroundColor White
    if ($PreventDuplicateExecution -eq 'Yes') {
        Write-Host "     â€¢ Duplicate prevention: Active" -ForegroundColor Gray
    } else {
        Write-Host "     â€¢ Will repeat every $RecurringIntervalHours hours from boot" -ForegroundColor Gray
    }
} else {
    Write-Host "  âœ— Boot execution: Disabled" -ForegroundColor DarkGray
}

if ($EnableRecurringSchedule -eq 'Yes') {
    Write-Host "  âœ" Recurring: Daily at $RecurringTime" -ForegroundColor White
    if ($RecurringIntervalHours -lt 24) {
        Write-Host "     â€¢ Repeats every $RecurringIntervalHours hours" -ForegroundColor Gray
    }
} else {
    Write-Host "  âœ— Recurring schedule: Disabled" -ForegroundColor DarkGray
}
Write-Host ""

Write-Host "Run As:" -ForegroundColor Cyan
if ($RunAsUser -eq 'SYSTEM') {
    Write-Host "  SYSTEM account" -ForegroundColor White
} else {
    Write-Host "  $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)" -ForegroundColor White
}
Write-Host ""

Write-Host "Execution Settings:" -ForegroundColor Cyan
Write-Host "  â€¢ Multiple instances: Ignored (only one runs at a time)" -ForegroundColor White
Write-Host "  â€¢ Network required: Yes" -ForegroundColor White
Write-Host "  â€¢ Run on batteries: Yes" -ForegroundColor White
Write-Host "  â€¢ Execution time limit: 2 hours" -ForegroundColor White
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

exit 0
