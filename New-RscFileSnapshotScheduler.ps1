<#
.SYNOPSIS
    Creates a Windows Scheduled Task to automate Rubrik Fileset snapshots.

.DESCRIPTION
    This script creates a scheduled task that executes New-RscFileSnapshot.ps1 with configurable parameters.
    The task can be configured to run at PC startup (with delay) and/or at recurring intervals,
    with built-in duplicate prevention to avoid multiple executions within the same interval.
    
    When running as SYSTEM account, the script automatically checks and configures RSC authentication
    if not already present for the SYSTEM user profile.

.NOTES
    Version:        1.4
    Author:         Matteo Briotto
    Creation Date:  January 2026
    Purpose/Change: Enhanced error diagnostics with detailed network connectivity troubleshooting

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

.PARAMETER ServiceAccountJsonPath
    Path to the Rubrik Service Account JSON file for SYSTEM account authentication.
    **Optional**. Only required if running as SYSTEM and credentials are not yet configured.
    The script will automatically configure authentication for SYSTEM account during task creation.

.PARAMETER Help
    Displays help and exits.

.PARAMETER ?
    Alias for Help (displays help and exits).

.EXAMPLE
    .\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold"
    Creates task with default settings: boot execution after 15 min, daily at 2 AM

.EXAMPLE
    .\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold" -ServiceAccountJsonPath "C:\Creds\rubrik.json"
    Creates task and configures SYSTEM account authentication using the provided JSON file

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
      - RubrikSecurityCloud module installed with -Scope AllUsers
      - Service Account JSON file (for initial SYSTEM authentication setup)

    Default configuration:
      - Task runs at PC startup with 15-minute delay
      - Task runs daily at 2:00 AM
      - Duplicate prevention enabled (won't run at boot if already executed recently)
      - Runs with SYSTEM account privileges
      - Multiple instances are ignored if one is already running
      - SYSTEM account authentication is automatically configured if needed

    Exit codes:
      - Exit 0: successful task creation or help requested
      - Exit 1: error occurred

.VERSION
    1.4 - Enhanced error diagnostics with network connectivity troubleshooting
    1.3 - Fixed SYSTEM profile directory creation for authentication
    1.2 - Improved JSON file detection (accepts any .json file)
    1.1 - Added SYSTEM account authentication verification and auto-configuration

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

    [string] $ServiceAccountJsonPath,

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
    Write-Host "  -SYSTEM account authentication is configured automatically if needed."
    Write-Host ""
    Write-Host "REQUIRED PARAMETERS:" -ForegroundColor Yellow
    Write-Host "  -SlaName <String>" -ForegroundColor White
    Write-Host "    Name of the SLA policy to apply" -ForegroundColor Gray
    Write-Host ""
    Write-Host "OPTIONAL PARAMETERS:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Script Configuration:" -ForegroundColor Cyan
    Write-Host "  -ScriptPath <String>" -ForegroundColor White
    Write-Host "    Path to New-RscFileSnapshot.ps1" -ForegroundColor Gray
    Write-Host "    Default: Same directory as this script" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  -TaskName <String>" -ForegroundColor White
    Write-Host "    Name of the scheduled task" -ForegroundColor Gray
    Write-Host "    Default: 'Rubrik Fileset Backup - Auto'" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  -ServiceAccountJsonPath <String>" -ForegroundColor White
    Write-Host "    Path to Service Account JSON file for SYSTEM authentication" -ForegroundColor Gray
    Write-Host "    Required only if running as SYSTEM without existing credentials" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "Snapshot Configuration:" -ForegroundColor Cyan
    Write-Host "  -HostName <String>" -ForegroundColor White
    Write-Host "    Target host name (default: local FQDN)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  -OsType <Windows|Linux>" -ForegroundColor White
    Write-Host "    Operating system type (default: Windows)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  -FilesetName <String>" -ForegroundColor White
    Write-Host "    Fileset name, supports wildcards (default: first available)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  -SkipConnectivityCheck <Yes|No>" -ForegroundColor White
    Write-Host "    Skip ping test to Rubrik cluster (default: No)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Boot Execution:" -ForegroundColor Cyan
    Write-Host "  -EnableBootExecution <Yes|No>" -ForegroundColor White
    Write-Host "    Run at PC startup (default: Yes)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  -BootDelayMinutes <1-1440>" -ForegroundColor White
    Write-Host "    Delay after boot in minutes (default: 15)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Recurring Schedule:" -ForegroundColor Cyan
    Write-Host "  -EnableRecurringSchedule <Yes|No>" -ForegroundColor White
    Write-Host "    Enable recurring execution (default: Yes)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  -RecurringTime <HH:MM>" -ForegroundColor White
    Write-Host "    Time for recurring execution in 24h format (default: 02:00)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  -RecurringIntervalHours <1-168>" -ForegroundColor White
    Write-Host "    Interval in hours (default: 24)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Execution Control:" -ForegroundColor Cyan
    Write-Host "  -PreventDuplicateExecution <Yes|No>" -ForegroundColor White
    Write-Host "    Prevent boot execution if already run recently (default: Yes)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  -RunAsUser <SYSTEM|CurrentUser>" -ForegroundColor White
    Write-Host "    Account to run the task as (default: SYSTEM)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Logging:" -ForegroundColor Cyan
    Write-Host "  -EnableFileLog <Yes|No>" -ForegroundColor White
    Write-Host "    Enable file logging (default: Yes)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  -LogFilePath <String>" -ForegroundColor White
    Write-Host "    Directory for log files (default: .\Logs)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  -LogRetentionDays <1-365>" -ForegroundColor White
    Write-Host "    Days to retain logs (default: 30)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  # Basic usage with defaults (first time - requires JSON)" -ForegroundColor Cyan
    Write-Host "  .\New-RscFileSnapshotScheduler.ps1 -SlaName 'Gold' -ServiceAccountJsonPath 'C:\Creds\rubrik.json'" -ForegroundColor White
    Write-Host ""
    Write-Host "  # After initial setup (JSON no longer needed)" -ForegroundColor Cyan
    Write-Host "  .\New-RscFileSnapshotScheduler.ps1 -SlaName 'Gold'" -ForegroundColor White
    Write-Host ""
    Write-Host "  # Custom recurring schedule" -ForegroundColor Cyan
    Write-Host "  .\New-RscFileSnapshotScheduler.ps1 -SlaName 'Gold' -RecurringTime '14:00' -RecurringIntervalHours 12" -ForegroundColor White
    Write-Host ""
    Write-Host "  # Disable boot execution" -ForegroundColor Cyan
    Write-Host "  .\New-RscFileSnapshotScheduler.ps1 -SlaName 'Gold' -EnableBootExecution No" -ForegroundColor White
    Write-Host ""
    Write-Host "  # With specific host and fileset" -ForegroundColor Cyan
    Write-Host "  .\New-RscFileSnapshotScheduler.ps1 -SlaName 'Silver' -HostName 'FILESRV01' -FilesetName 'UserData'" -ForegroundColor White
    Write-Host ""
    Write-Host "  # Run as current user instead of SYSTEM" -ForegroundColor Cyan
    Write-Host "  .\New-RscFileSnapshotScheduler.ps1 -SlaName 'Gold' -RunAsUser CurrentUser" -ForegroundColor White
    Write-Host ""
    Write-Host "MORE INFORMATION:" -ForegroundColor Yellow
    Write-Host "  Documentation: https://github.com/mbriotto/New-RscFileSnapshot/blob/main/New-RscFileSnapshotScheduler_ps1-README.md"
    Write-Host "  Issues: https://github.com/mbriotto/New-RscFileSnapshot/issues"
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host ""
}

if ($Help) {
    Show-Help
    exit 0
}

#endregion

#region --- PARAMETER VALIDATION -----------------------------------------------

if ([string]::IsNullOrWhiteSpace($SlaName)) {
    Write-Host ""
    Write-Host "[ERROR] -SlaName parameter is required!" -ForegroundColor Red
    Write-Host ""
    Show-Help
    exit 1
}

if ($EnableBootExecution -eq 'No' -and $EnableRecurringSchedule -eq 'No') {
    Write-Host ""
    Write-Host "[ERROR] At least one execution method must be enabled!" -ForegroundColor Red
    Write-Host "Enable -EnableBootExecution or -EnableRecurringSchedule" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

#endregion

#region --- LOGGING ------------------------------------------------------------

$script:UseFileLog = ($EnableFileLog -eq 'Yes')
$script:LogFile = $null

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info','Success','Warning','Error')]
        [string]$Level = 'Info'
    )
    
    if (-not $script:UseFileLog -or -not $script:LogFile) { return }
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] [$Level] $Message"
    
    try {
        Add-Content -Path $script:LogFile -Value $logEntry -Encoding UTF8 -ErrorAction Stop
    } catch {
        Write-Warning "Unable to write to log file: $($_.Exception.Message)"
    }
}

function Write-ColorOutput {
    param(
        [string]$Message,
        [ValidateSet('Info','Success','Warning','Error')]
        [string]$Level = 'Info'
    )
    
    $colors = @{
        'Info' = 'Cyan'
        'Success' = 'Green'
        'Warning' = 'Yellow'
        'Error' = 'Red'
    }
    
    $prefix = switch ($Level) {
        'Info' { '[i]' }
        'Success' { '[+]' }
        'Warning' { '[!]' }
        'Error' { '[x]' }
    }
    
    Write-Host "$prefix $Message" -ForegroundColor $colors[$Level]
    Write-Log -Message $Message -Level $Level
}

if ($script:UseFileLog) {
    try {
        if (-not (Test-Path $LogFilePath)) {
            New-Item -Path $LogFilePath -ItemType Directory -Force | Out-Null
        }
        
        $logFileName = "New-RscFileSnapshotScheduler_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        $script:LogFile = Join-Path $LogFilePath $logFileName
        
        $header = @"
================================================================================
Rubrik Fileset Snapshot Task Scheduler Log
Script: New-RscFileSnapshotScheduler.ps1
Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
User: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
================================================================================

"@
        Set-Content -Path $script:LogFile -Value $header -Encoding UTF8
        
        if ($LogRetentionDays -gt 0) {
            $cutoffDate = (Get-Date).AddDays(-$LogRetentionDays)
            Get-ChildItem -Path $LogFilePath -Filter "New-RscFileSnapshotScheduler_*.log" | 
                Where-Object { $_.LastWriteTime -lt $cutoffDate } | 
                Remove-Item -Force -ErrorAction SilentlyContinue
        }
        
    } catch {
        Write-Warning "Unable to initialize log file: $($_.Exception.Message)"
        $script:UseFileLog = $false
        $script:LogFile = $null
    }
}

#endregion

#region --- BANNER -------------------------------------------------------------

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " RUBRIK FILESET SNAPSHOT - TASK SCHEDULER " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Version: 1.4" -ForegroundColor Gray
Write-Host "Author: Matteo Briotto" -ForegroundColor Gray
Write-Host "License: GPL-3.0" -ForegroundColor Gray
Write-Host ""
Write-Host "This script creates a Windows Scheduled Task to automate" -ForegroundColor White
Write-Host "Rubrik Fileset snapshots with customizable scheduling." -ForegroundColor White
Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

Write-Log -Message "Script execution started" -Level Info
Write-Log -Message "SLA Name: $SlaName" -Level Info

#endregion

#region --- ADMINISTRATOR CHECK ------------------------------------------------

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-ColorOutput "Administrator privileges required to create scheduled tasks!" -Level Error
    Write-Host ""
    Write-Host "Please run this script as Administrator:" -ForegroundColor Yellow
    Write-Host "  1. Right-click PowerShell" -ForegroundColor Gray
    Write-Host "  2. Select 'Run as Administrator'" -ForegroundColor Gray
    Write-Host ""
    Write-Log -Message "Script requires administrator privileges" -Level Error
    exit 1
}

Write-ColorOutput "Running with Administrator privileges" -Level Success
Write-Log -Message "Administrator check passed" -Level Success

#endregion

#region --- SCRIPT PATH VALIDATION ---------------------------------------------

Write-Host ""
Write-ColorOutput "Validating script configuration..." -Level Info
Write-Host ""

if ([string]::IsNullOrWhiteSpace($ScriptPath)) {
    $ScriptPath = Join-Path $PSScriptRoot "New-RscFileSnapshot.ps1"
    Write-ColorOutput "Using default script path: $ScriptPath" -Level Info
    Write-Log -Message "Using default script path: $ScriptPath" -Level Info
} else {
    $ScriptPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ScriptPath)
    Write-ColorOutput "Using specified script path: $ScriptPath" -Level Info
    Write-Log -Message "Using custom script path: $ScriptPath" -Level Info
}

if (-not (Test-Path $ScriptPath)) {
    Write-ColorOutput "Script not found: $ScriptPath" -Level Error
    Write-Host ""
    Write-Host "Please ensure New-RscFileSnapshot.ps1 exists at the specified location" -ForegroundColor Yellow
    Write-Host ""
    Write-Log -Message "Script not found at: $ScriptPath" -Level Error
    exit 1
}

Write-ColorOutput "Script found and validated" -Level Success
Write-Log -Message "Script validated: $ScriptPath" -Level Success

#endregion

#region --- SYSTEM AUTHENTICATION CHECK ----------------------------------------

Write-Host ""
Write-ColorOutput "Checking authentication configuration..." -Level Info
Write-Host ""

# Function to check if RSC is authenticated for a specific user context
function Test-RscAuthentication {
    param([string]$UserContext = "Current")
    
    try {
        $testScript = {
            try {
                Import-Module RubrikSecurityCloud -ErrorAction Stop
                Connect-Rsc -ErrorAction Stop
                $cluster = Get-RscCluster -ErrorAction Stop
                Disconnect-Rsc -ErrorAction SilentlyContinue
                return $true
            } catch {
                return $false
            }
        }
        
        if ($UserContext -eq "SYSTEM") {
            # Test as SYSTEM using a scheduled task
            $testTaskName = "RSC-Auth-Test-$(Get-Random)"
            $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -Command `"$($testScript.ToString())`""
            $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(5)
            $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
            
            Register-ScheduledTask -TaskName $testTaskName -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null
            Start-ScheduledTask -TaskName $testTaskName
            Start-Sleep -Seconds 10
            
            $taskInfo = Get-ScheduledTaskInfo -TaskName $testTaskName
            $result = ($taskInfo.LastTaskResult -eq 0)
            
            Unregister-ScheduledTask -TaskName $testTaskName -Confirm:$false
            return $result
        } else {
            return & $testScript
        }
    } catch {
        return $false
    }
}

# Function to configure RSC authentication for SYSTEM account
function Set-SystemAuthentication {
    param([string]$JsonPath)
    
    Write-ColorOutput "Configuring authentication for SYSTEM account..." -Level Info
    Write-Log -Message "Configuring SYSTEM authentication from: $JsonPath" -Level Info
    
    try {
        # Create a temporary script to run as SYSTEM
        $tempScript = Join-Path $env:TEMP "setup-rsc-system-$( Get-Random).ps1"
        $setupScript = @"
# Result tracking
`$result = @{
    Success = `$false
    Error = `$null
    ErrorType = `$null
    Step = `$null
}

try {
    # Step 1: Ensure SYSTEM profile directories exist
    `$result.Step = 'Creating directories'
    `$systemProfilePath = 'C:\Windows\System32\config\systemprofile\Documents\WindowsPowerShell'
    if (-not (Test-Path `$systemProfilePath)) {
        New-Item -Path `$systemProfilePath -ItemType Directory -Force | Out-Null
    }

    `$rscPath = Join-Path `$systemProfilePath 'rubrik-powershell-sdk'
    if (-not (Test-Path `$rscPath)) {
        New-Item -Path `$rscPath -ItemType Directory -Force | Out-Null
    }

    # Step 2: Enable TLS 1.2/1.3 for secure connections
    `$result.Step = 'Configuring TLS'
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13

    # Step 3: Import module
    `$result.Step = 'Loading module'
    Import-Module RubrikSecurityCloud -Force -ErrorAction Stop

    # Step 4: Configure authentication
    `$result.Step = 'Configuring credentials'
    Set-RscServiceAccountFile -InputFilePath '$JsonPath' -ErrorAction Stop

    # Step 5: Test connection
    `$result.Step = 'Testing connection'
    Connect-Rsc -ErrorAction Stop
    Disconnect-Rsc -ErrorAction SilentlyContinue
    
    `$result.Success = `$true

} catch {
    `$result.Error = `$_.Exception.Message
    `$result.ErrorType = `$_.Exception.GetType().Name
    
    # Capture inner exception if present
    if (`$_.Exception.InnerException) {
        `$result.InnerError = `$_.Exception.InnerException.Message
    }
}

# Save result to file for parent script to read
`$result | ConvertTo-Json -Depth 3 | Out-File 'C:\Windows\Temp\rsc-system-setup-result.json' -Force
"@
        Set-Content -Path $tempScript -Value $setupScript -Force
        
        # Create and run a temporary scheduled task as SYSTEM
        $setupTaskName = "RSC-Setup-SYSTEM-$(Get-Random)"
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$tempScript`""
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(5)
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        
        Register-ScheduledTask -TaskName $setupTaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
        Start-ScheduledTask -TaskName $setupTaskName
        
        # Wait for task completion
        $timeout = 60
        $elapsed = 0
        do {
            Start-Sleep -Seconds 2
            $elapsed += 2
            $taskState = (Get-ScheduledTask -TaskName $setupTaskName).State
        } while ($taskState -eq 'Running' -and $elapsed -lt $timeout)
        
        $taskInfo = Get-ScheduledTaskInfo -TaskName $setupTaskName
        $taskExitCode = $taskInfo.LastTaskResult
        
        # Read detailed result from the task
        $resultFile = "C:\Windows\Temp\rsc-system-setup-result.json"
        $detailedResult = $null
        
        if (Test-Path $resultFile) {
            try {
                $detailedResult = Get-Content $resultFile -Raw | ConvertFrom-Json
                Remove-Item -Path $resultFile -Force -ErrorAction SilentlyContinue
            } catch {
                Write-Log -Message "Could not read detailed result file" -Level Warning
            }
        }
        
        # Cleanup
        Unregister-ScheduledTask -TaskName $setupTaskName -Confirm:$false -ErrorAction SilentlyContinue
        Remove-Item -Path $tempScript -Force -ErrorAction SilentlyContinue
        
        if ($taskExitCode -eq 0 -and $detailedResult -and $detailedResult.Success) {
            Write-ColorOutput "SYSTEM account authentication configured successfully" -Level Success
            Write-Log -Message "SYSTEM authentication configured successfully" -Level Success
            return $true
        } else {
            Write-ColorOutput "Failed to configure SYSTEM account authentication" -Level Error
            Write-Host ""
            
            if ($detailedResult) {
                Write-Host "Error Details:" -ForegroundColor Yellow
                Write-Host "  Step: $($detailedResult.Step)" -ForegroundColor White
                Write-Host "  Error: $($detailedResult.Error)" -ForegroundColor Red
                Write-Host "  Type: $($detailedResult.ErrorType)" -ForegroundColor Gray
                
                if ($detailedResult.InnerError) {
                    Write-Host "  Inner Error: $($detailedResult.InnerError)" -ForegroundColor Red
                }
                
                Write-Log -Message "SYSTEM auth failed at step: $($detailedResult.Step) - $($detailedResult.Error)" -Level Error
                
                # Provide specific guidance based on error type
                Write-Host ""
                if ($detailedResult.Error -match "invio della richiesta|sending the request|network|timeout|timed out") {
                    Write-Host "NETWORK CONNECTIVITY ISSUE DETECTED" -ForegroundColor Yellow
                    Write-Host ""
                    Write-Host "This appears to be a network connectivity problem." -ForegroundColor White
                    Write-Host "Common causes and solutions:" -ForegroundColor Cyan
                    Write-Host ""
                    Write-Host "1. Corporate Firewall/Proxy:" -ForegroundColor Yellow
                    Write-Host "   - Contact your IT department to allow access to *.rubrik.com" -ForegroundColor Gray
                    Write-Host "   - Ensure HTTPS (port 443) is allowed for PowerShell" -ForegroundColor Gray
                    Write-Host ""
                    Write-Host "2. TLS/SSL Configuration:" -ForegroundColor Yellow
                    Write-Host "   - The script now enables TLS 1.2/1.3 automatically" -ForegroundColor Gray
                    Write-Host "   - Ensure your system supports TLS 1.2 or higher" -ForegroundColor Gray
                    Write-Host ""
                    Write-Host "3. Proxy Configuration:" -ForegroundColor Yellow
                    Write-Host "   - If behind a corporate proxy, configure it:" -ForegroundColor Gray
                    Write-Host "     netsh winhttp set proxy proxy-server=`"http://proxy:port`"" -ForegroundColor White
                    Write-Host ""
                    Write-Host "4. DNS Resolution:" -ForegroundColor Yellow
                    Write-Host "   - Verify DNS can resolve: gabrielli.my.rubrik.com" -ForegroundColor Gray
                    Write-Host "     nslookup gabrielli.my.rubrik.com" -ForegroundColor White
                    Write-Host ""
                    Write-Host "5. Test Connectivity:" -ForegroundColor Yellow
                    Write-Host "   - Use the diagnostic script provided:" -ForegroundColor Gray
                    Write-Host "     .\Test-NetworkConnectivity.ps1" -ForegroundColor White
                    Write-Host ""
                } elseif ($detailedResult.Error -match "credentials|authentication|unauthorized|forbidden") {
                    Write-Host "AUTHENTICATION ISSUE DETECTED" -ForegroundColor Yellow
                    Write-Host ""
                    Write-Host "Possible causes:" -ForegroundColor Cyan
                    Write-Host "  - Service Account credentials may be invalid or expired" -ForegroundColor Gray
                    Write-Host "  - JSON file may be corrupted" -ForegroundColor Gray
                    Write-Host "  - Service Account may have been deleted in RSC" -ForegroundColor Gray
                    Write-Host ""
                    Write-Host "Solution:" -ForegroundColor Yellow
                    Write-Host "  1. Verify the Service Account exists in Rubrik Security Cloud" -ForegroundColor Gray
                    Write-Host "  2. Download a fresh JSON file" -ForegroundColor Gray
                    Write-Host "  3. Re-run this script with the new JSON file" -ForegroundColor Gray
                    Write-Host ""
                } else {
                    Write-Host "For assistance, please check:" -ForegroundColor Yellow
                    Write-Host "  - Rubrik Security Cloud status" -ForegroundColor Gray
                    Write-Host "  - Network connectivity to Rubrik cloud" -ForegroundColor Gray
                    Write-Host "  - Windows Event Viewer for detailed errors" -ForegroundColor Gray
                    Write-Host ""
                }
            } else {
                Write-Host "Task Exit Code: $taskExitCode" -ForegroundColor Red
                Write-Host ""
                Write-Log -Message "SYSTEM authentication configuration failed: Exit Code $taskExitCode" -Level Error
            }
            
            return $false
        }
        
    } catch {
        Write-ColorOutput "Error configuring SYSTEM authentication: $($_.Exception.Message)" -Level Error
        Write-Log -Message "SYSTEM authentication error: $($_.Exception.Message)" -Level Error
        return $false
    }
}

# Check authentication based on RunAsUser parameter
if ($RunAsUser -eq 'SYSTEM') {
    Write-ColorOutput "Task will run as SYSTEM account - verifying authentication..." -Level Info
    Write-Log -Message "Checking SYSTEM account authentication" -Level Info
    
    $systemAuthOk = Test-RscAuthentication -UserContext "SYSTEM"
    
    if ($systemAuthOk) {
        Write-ColorOutput "SYSTEM account is already authenticated" -Level Success
        Write-Log -Message "SYSTEM account authentication verified" -Level Success
    } else {
        Write-ColorOutput "SYSTEM account is not authenticated - configuration required" -Level Warning
        Write-Log -Message "SYSTEM account requires authentication" -Level Warning
        
        # Look for JSON file
        $jsonFile = $null
        
        if (-not [string]::IsNullOrWhiteSpace($ServiceAccountJsonPath) -and (Test-Path $ServiceAccountJsonPath)) {
            $jsonFile = $ServiceAccountJsonPath
        } else {
            # Search for JSON file in script directory
            # Accept any .json file (common names: service account, credentials, rubrik, etc.)
            $jsonFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.json" -ErrorAction SilentlyContinue
            if ($jsonFiles.Count -gt 0) {
                if ($jsonFiles.Count -eq 1) {
                    # Single JSON file found - use it
                    $jsonFile = $jsonFiles[0].FullName
                    Write-ColorOutput "Found JSON file: $($jsonFiles[0].Name)" -Level Info
                } else {
                    # Multiple JSON files - try to prioritize by common naming patterns
                    $priorityFile = $jsonFiles | Where-Object { 
                        $_.Name -match "(service|account|rubrik|rsc|credential|auth)" 
                    } | Select-Object -First 1
                    
                    if ($priorityFile) {
                        $jsonFile = $priorityFile.FullName
                        Write-ColorOutput "Found JSON file: $($priorityFile.Name) (selected from $($jsonFiles.Count) files)" -Level Info
                    } else {
                        # No priority match - use first file
                        $jsonFile = $jsonFiles[0].FullName
                        Write-ColorOutput "Found JSON file: $($jsonFiles[0].Name) (first of $($jsonFiles.Count) files)" -Level Info
                    }
                }
            }
        }
        
        if ($jsonFile) {
            Write-Host ""
            Write-ColorOutput "Attempting to configure SYSTEM account authentication..." -Level Info
            Write-Host "  JSON File: $jsonFile" -ForegroundColor Gray
            Write-Host ""
            
            $configured = Set-SystemAuthentication -JsonPath $jsonFile
            
            if (-not $configured) {
                Write-Host ""
                Write-ColorOutput "Failed to configure SYSTEM account authentication" -Level Error
                Write-Host ""
                Write-Host "Please configure authentication manually:" -ForegroundColor Yellow
                Write-Host "  1. Run PowerShell as SYSTEM using PsExec:" -ForegroundColor Gray
                Write-Host "     PsExec.exe -i -s powershell.exe" -ForegroundColor White
                Write-Host "  2. In the SYSTEM PowerShell session, run:" -ForegroundColor Gray
                Write-Host "     Import-Module RubrikSecurityCloud" -ForegroundColor White
                Write-Host "     Set-RscServiceAccountFile -InputFilePath '$jsonFile'" -ForegroundColor White
                Write-Host "  3. Re-run this scheduler script" -ForegroundColor Gray
                Write-Host ""
                Write-Log -Message "SYSTEM authentication configuration failed - manual intervention required" -Level Error
                exit 1
            }
            
            # Verify authentication after configuration
            Write-ColorOutput "Verifying SYSTEM authentication configuration..." -Level Info
            Start-Sleep -Seconds 3
            
            $systemAuthOk = Test-RscAuthentication -UserContext "SYSTEM"
            if (-not $systemAuthOk) {
                Write-ColorOutput "SYSTEM authentication verification failed" -Level Error
                Write-Log -Message "SYSTEM authentication verification failed after configuration" -Level Error
                exit 1
            }
            
            Write-ColorOutput "SYSTEM authentication verified successfully" -Level Success
            Write-Log -Message "SYSTEM authentication verified after configuration" -Level Success
            
        } else {
            Write-Host ""
            Write-ColorOutput "Service Account JSON file not found" -Level Error
            Write-Host ""
            Write-Host "To configure SYSTEM account authentication, you need:" -ForegroundColor Yellow
            Write-Host "  1. Download Service Account JSON from Rubrik Security Cloud" -ForegroundColor Gray
            Write-Host "  2. Provide the JSON file path using -ServiceAccountJsonPath parameter" -ForegroundColor Gray
            Write-Host "     OR place the JSON file in the script directory" -ForegroundColor Gray
            Write-Host ""
            Write-Host "Example:" -ForegroundColor Cyan
            Write-Host "  .\New-RscFileSnapshotScheduler.ps1 -SlaName 'Gold' -ServiceAccountJsonPath 'C:\Creds\rubrik.json'" -ForegroundColor White
            Write-Host ""
            Write-Log -Message "Service Account JSON file not found - cannot configure SYSTEM authentication" -Level Error
            exit 1
        }
    }
} else {
    Write-ColorOutput "Task will run as current user - checking authentication..." -Level Info
    Write-Log -Message "Checking current user authentication" -Level Info
    
    $currentAuthOk = Test-RscAuthentication -UserContext "Current"
    
    if (-not $currentAuthOk) {
        Write-ColorOutput "Current user is not authenticated" -Level Error
        Write-Host ""
        Write-Host "Please configure authentication first:" -ForegroundColor Yellow
        Write-Host "  .\New-RscFileSnapshot.ps1 -SlaName '$SlaName'" -ForegroundColor White
        Write-Host ""
        Write-Log -Message "Current user authentication check failed" -Level Error
        exit 1
    }
    
    Write-ColorOutput "Current user authentication verified" -Level Success
    Write-Log -Message "Current user authentication verified" -Level Success
}

#endregion

#region --- BUILD COMMAND ------------------------------------------------------

Write-Host ""
Write-ColorOutput "Building scheduled task command..." -Level Info
Write-Host ""

$arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" -SlaName `"$SlaName`""

if ($PSBoundParameters.ContainsKey('HostName') -and -not [string]::IsNullOrWhiteSpace($HostName)) {
    $arguments += " -HostName `"$HostName`""
    Write-Log -Message "Parameter: HostName = $HostName" -Level Info
}

if ($PSBoundParameters.ContainsKey('OsType')) {
    $arguments += " -OsType $OsType"
    Write-Log -Message "Parameter: OsType = $OsType" -Level Info
}

if ($PSBoundParameters.ContainsKey('FilesetName') -and -not [string]::IsNullOrWhiteSpace($FilesetName)) {
    $arguments += " -FilesetName `"$FilesetName`""
    Write-Log -Message "Parameter: FilesetName = $FilesetName" -Level Info
}

if ($PSBoundParameters.ContainsKey('SkipConnectivityCheck')) {
    $arguments += " -SkipConnectivityCheck $SkipConnectivityCheck"
    Write-Log -Message "Parameter: SkipConnectivityCheck = $SkipConnectivityCheck" -Level Info
}

Write-ColorOutput "Command configured successfully" -Level Success
Write-Log -Message "Task command: powershell.exe $arguments" -Level Info

#endregion

#region --- CREATE SCHEDULED TASK ----------------------------------------------

Write-Host ""
Write-ColorOutput "Creating scheduled task..." -Level Info
Write-Host ""
Write-Log -Message "Creating task: $TaskName" -Level Info

try {
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $arguments
    
    $triggers = @()
    
    if ($EnableBootExecution -eq 'Yes') {
        $bootTrigger = New-ScheduledTaskTrigger -AtStartup
        
        if ($PreventDuplicateExecution -eq 'Yes') {
            $bootTrigger.Repetition = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours $RecurringIntervalHours) | Select-Object -ExpandProperty Repetition
            $bootTrigger.Delay = "PT$($BootDelayMinutes)M"
        } else {
            $bootTrigger.Delay = "PT$($BootDelayMinutes)M"
            $bootTrigger.Repetition = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours $RecurringIntervalHours) -RepetitionDuration ([TimeSpan]::MaxValue) | Select-Object -ExpandProperty Repetition
        }
        
        $triggers += $bootTrigger
        Write-ColorOutput "Boot trigger configured: $BootDelayMinutes minutes delay" -Level Success
        Write-Log -Message "Boot trigger: Delay=$BootDelayMinutes min, PreventDuplicate=$PreventDuplicateExecution" -Level Info
    }
    
    if ($EnableRecurringSchedule -eq 'Yes') {
        $timeParts = $RecurringTime -split ':'
        $scheduleTime = Get-Date -Hour $timeParts[0] -Minute $timeParts[1] -Second 0
        
        $recurringTrigger = New-ScheduledTaskTrigger -Daily -At $scheduleTime
        
        if ($RecurringIntervalHours -lt 24) {
            $recurringTrigger.Repetition = New-ScheduledTaskTrigger -Once -At $scheduleTime -RepetitionInterval (New-TimeSpan -Hours $RecurringIntervalHours) -RepetitionDuration ([TimeSpan]::MaxValue) | Select-Object -ExpandProperty Repetition
        }
        
        $triggers += $recurringTrigger
        Write-ColorOutput "Recurring trigger configured: Daily at $RecurringTime" -Level Success
        Write-Log -Message "Recurring trigger: Time=$RecurringTime, Interval=$RecurringIntervalHours hours" -Level Info
    }
    
    if ($RunAsUser -eq 'SYSTEM') {
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        Write-Log -Message "Principal: SYSTEM account" -Level Info
    } else {
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $principal = New-ScheduledTaskPrincipal -UserId $currentUser -LogonType Interactive -RunLevel Highest
        Write-Log -Message "Principal: $currentUser" -Level Info
    }
    
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RunOnlyIfNetworkAvailable `
        -MultipleInstances IgnoreNew `
        -ExecutionTimeLimit (New-TimeSpan -Hours 2)
    
    Write-ColorOutput "Task settings configured" -Level Success
    Write-Log -Message "Task settings: AllowBattery, NetworkRequired, IgnoreNew, Timeout=2h" -Level Info
    
    Register-ScheduledTask `
        -TaskName $TaskName `
        -Action $action `
        -Trigger $triggers `
        -Principal $principal `
        -Settings $settings `
        -Description "Automated Rubrik Fileset snapshot for $SlaName SLA" `
        -Force | Out-Null
    
    Write-ColorOutput "Scheduled task created successfully" -Level Success
    Write-Log -Message "Task registered: $TaskName" -Level Success
    
    if ($EnableBootExecution -eq 'Yes' -and $BootDelayMinutes -gt 0) {
        Write-Host ""
        Write-ColorOutput "Applying boot delay configuration..." -Level Info
        
        try {
            $service = New-Object -ComObject Schedule.Service
            $service.Connect()
            
            $taskFolder = $service.GetFolder("\")
            $taskDefinition = $taskFolder.GetTask($TaskName).Definition
            
            for ($i = 0; $i -lt $taskDefinition.Triggers.Count; $i++) {
                $trigger = $taskDefinition.Triggers.Item($i + 1)
                if ($trigger.Type -eq 8) {
                    $trigger.Delay = "PT$($BootDelayMinutes)M"
                    
                    if ($PreventDuplicateExecution -eq 'Yes') {
                        $trigger.Repetition.Interval = "PT$($RecurringIntervalHours)H"
                        $trigger.Repetition.Duration = ""
                        $trigger.Repetition.StopAtDurationEnd = $false
                    }
                }
            }
            
            $taskFolder.RegisterTaskDefinition(
                $TaskName,
                $taskDefinition,
                6,
                $principal.UserId,
                $null,
                $principal.LogonType
            ) | Out-Null
            
            Write-ColorOutput "Advanced trigger configuration completed" -Level Success
            Write-Log -Message "Boot delay applied: $BootDelayMinutes minutes" -Level Success
            
        } catch {
            Write-ColorOutput "Warning: Could not configure advanced trigger settings: $($_.Exception.Message)" -Level Warning
            Write-ColorOutput "Task created but boot delay may need manual configuration in Task Scheduler" -Level Warning
            Write-Log -Message "Warning: Advanced trigger configuration failed: $($_.Exception.Message)" -Level Warning
        }
    }
    
} catch {
    Write-ColorOutput "ERROR creating scheduled task: $($_.Exception.Message)" -Level Error
    Write-Log -Message "Task creation failed: $($_.Exception.Message)" -Level Error
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
    Write-Host "  SYSTEM account (authenticated)" -ForegroundColor White
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

Write-Log -Message "Task configuration completed successfully" -Level Success

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
