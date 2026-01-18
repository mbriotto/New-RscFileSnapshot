<#
.SYNOPSIS
    Initiates an on-demand snapshot of a Rubrik Fileset associated with a specified host.

.DESCRIPTION
    Connects to the Rubrik cluster (RSC), identifies the host (default: local hostname),
    selects the Fileset (optional, with fallback to the first Fileset if not provided), retrieves the SLA (REQUIRED)
    and invokes the GraphQL mutation to create an on-demand snapshot.
    The cluster IP address is automatically extracted from the host's CdmLink.
    
.LINK
    https://github.com/mbriotto/New-RscFileSnapshot

.PARAMETER HostName
    Name of the host (e.g., FILESRV01) as visible in Rubrik.
    **OPTIONAL**: If omitted, uses the FQDN of the local computer.

.PARAMETER OsType
    Host operating system. Valid values: Windows, Linux.
    **Optional**. If omitted, the default is **Windows**.

.PARAMETER SlaName
    Name of the SLA to apply to the snapshot. **Required**.

.PARAMETER FilesetName
    Name of the Fileset to use. Supports wildcards (e.g., "FS*").
    **If omitted, falls back to the first Fileset associated with the host.**

.PARAMETER Credential
    Credentials (PSCredential) to use for Connect-Rsc. If not specified, uses the default flow.

.PARAMETER SkipConnectivityCheck
    Skips the connectivity test (ping) to the Rubrik cluster.
    Values: Yes | No. **Default: No** (performs ping).

.PARAMETER EnableFileLog
    Enables file logging.
    Values: Yes | No. **Default: Yes** (logging active).

.PARAMETER LogFilePath
    Path to the folder where log files are saved.
    **Default**: $PSScriptRoot\Logs (Logs folder in the same directory as the script).

.PARAMETER LogRetentionDays
    Number of days to retain log files. Older files are automatically deleted.
    **Default**: 30 days. **Range**: 1-365.

.PARAMETER Help
    Displays help and exits.

.PARAMETER ?
    Alias for Help (displays help and exits).

.EXAMPLE
    .\New-RscFileSnapshot.ps1 -SlaName Gold
    # Uses local hostname and automatically detects cluster IP from CdmLink

.EXAMPLE
    .\New-RscFileSnapshot.ps1 -HostName FILESRV01 -SlaName Gold

.EXAMPLE
    .\New-RscFileSnapshot.ps1 -HostName FS01 -OsType Linux -SlaName Silver -FilesetName "User*"

.EXAMPLE
    $cred = Get-Credential
    .\New-RscFileSnapshot.ps1 -SlaName Gold -FilesetName "UserProfiles" -Credential $cred -SkipConnectivityCheck Yes

.NOTES
    Requirements:
      - Rubrik PowerShell RSC module (Connect-Rsc, Get-RscCluster, Get-RscHost, Get-RscFileset, Get-RscSla, New-RscMutation).

    Default settings:
      - If **-HostName** is not specified, the **FQDN** of the local computer is used.
      - The cluster IP is automatically extracted from the host's **CdmLink**.
      - If **-OsType** is not specified, **Windows** is used.
      - **-SkipConnectivityCheck** default **No** (performs ping to cluster).
      - **-EnableFileLog** default **Yes** (file logging active).
      - **-LogFilePath** default **$PSScriptRoot\Logs** (Logs folder in the script directory).
      - **-LogRetentionDays** default **30 days** (automatic cleanup of old logs).

    Credentials:
      - If the **-Credential** parameter is NOT provided, Connect-Rsc will use the default
        authentication method available in the environment.
      - If a JSON file is found in the script directory, it is automatically configured
        as a Service Account and the JSON file is deleted for security.

    Exit codes:
      - Exit 0: successful execution or help requested.
      - Exit 1: error/insufficient parameters or conditions not met.

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
    [string] $HostName,

    [ValidateSet('Linux','Windows')]
    [string] $OsType = 'Windows',

    [ValidateNotNullOrEmpty()]
    [string] $SlaName,

    [string] $FilesetName,

    [System.Management.Automation.PSCredential] $Credential,

    [ValidateSet('Yes','No')]
    [string] $SkipConnectivityCheck = 'No',

    [ValidateSet('Yes','No')]
    [string] $EnableFileLog = 'Yes',

    [string] $LogFilePath = "$PSScriptRoot\Logs",

    [ValidateRange(1,365)]
    [int] $LogRetentionDays = 30,

    [Alias('?')]
    [switch] $Help
)

#region --- HELP & PRE-CHECKS --------------------------------------------------

function Show-Help {
    Write-Host ""
    Write-Host "===========================================" -ForegroundColor Yellow
    Write-Host " RUBRIK FILESET SNAPSHOT TOOL " -ForegroundColor Cyan
    Write-Host "===========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  .\New-RscFileSnapshot.ps1 -SlaName <SLA> [-HostName <Host>] [-OsType Windows|Linux] [-FilesetName <Name|Wildcard>] [-Credential <PSCredential>] [-SkipConnectivityCheck Yes|No] [-EnableFileLog Yes|No] [-LogFilePath <Path>] [-LogRetentionDays <Days>]"
    Write-Host ""
    Write-Host "NOTES:" -ForegroundColor Yellow
    Write-Host "  -SlaName is REQUIRED."
    Write-Host "  -If -HostName is not specified, uses the FQDN of the local computer."
    Write-Host "  -Cluster IP is automatically extracted from the host's CdmLink."
    Write-Host "  -If -OsType is not specified, the default is Windows."
    Write-Host "  -If -FilesetName is not specified, the FIRST Fileset associated with the host will be used (fallback)."
    Write-Host "  -If -SkipConnectivityCheck is Yes, skips ping to cluster (default: No, performs ping)."
    Write-Host "  -File logging is ACTIVE by default (can be disabled with -EnableFileLog No)."
    Write-Host "  -Default log retention: 30 days (configurable with -LogRetentionDays)."
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  .\New-RscFileSnapshot.ps1 -SlaName Gold"
    Write-Host "  .\New-RscFileSnapshot.ps1 -HostName FILESRV01 -SlaName Gold"
    Write-Host "  .\New-RscFileSnapshot.ps1 -HostName FS01 -OsType Linux -SlaName Silver -FilesetName 'User*' -SkipConnectivityCheck Yes"
    Write-Host "  .\New-RscFileSnapshot.ps1 -SlaName Gold -EnableFileLog No"
    Write-Host "  .\New-RscFileSnapshot.ps1 -SlaName Gold -LogRetentionDays 7 -LogFilePath C:\Logs\Rubrik"
    Write-Host ""
    Write-Host "    Tips:" -ForegroundColor Yellow
    Write-Host "  - Make sure you have the Rubrik RSC module installed and imported."
    Write-Host "  - The cluster IP is automatically detected from the host's CdmLink in Rubrik."
    Write-Host "  - To configure a Service Account, copy the JSON file to the script directory."
    Write-Host "  - The JSON file is automatically processed and deleted after configuration."
    Write-Host ""
}

if ($Help) {
    Show-Help
    exit 0
}

# Verify SlaName is required
if (-not $PSBoundParameters.ContainsKey('SlaName') -or [string]::IsNullOrWhiteSpace($SlaName)) {
    Write-Host "Parameter -SlaName is required." -ForegroundColor Red
    Show-Help
    exit 1
}

# If -HostName is not specified, use FQDN of local computer
if ([string]::IsNullOrWhiteSpace($HostName)) {
    try {
        $HostName = [System.Net.Dns]::GetHostByName($env:COMPUTERNAME).HostName
        Write-Host "Parameter -HostName not specified: using local FQDN '$HostName'" -ForegroundColor Yellow
    } catch {
        $HostName = $env:COMPUTERNAME
        Write-Host "Unable to get FQDN, using local hostname '$HostName'" -ForegroundColor Yellow
    }
}

#endregion

#region --- LOG ----------------------------------------------------------------

# Global variables for logging
$script:LogFile = $null
$script:UseFileLog = ($EnableFileLog -eq 'Yes')

# Initialize logging system
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
        $logFileName = "New-RscFileSnapshot_${timestamp}.log"
        $script:LogFile = Join-Path -Path $LogFilePath -ChildPath $logFileName

        # Write log header
        $header = @"
================================================================================
RUBRIK FILESET SNAPSHOT TOOL - LOG
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
        Write-Host "Error initializing file logging: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "Continuing with console logging only..." -ForegroundColor Yellow
        $script:UseFileLog = $false
    }
}

# Cleanup old logs based on retention
function Cleanup-OldLogs {
    if (-not $script:UseFileLog) {
        return
    }

    try {
        $cutoffDate = (Get-Date).AddDays(-$LogRetentionDays)
        $logFiles = Get-ChildItem -Path $LogFilePath -Filter "New-RscFileSnapshot_*.log" -File

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
        Write-Host "Error during old logs cleanup: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string] $Message,
        [ValidateSet('Info','Warn','Error')]
        [string] $Level = 'Info'
    )
    
    # Timestamp for log
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Console output (colored)
    switch ($Level) {
        'Info'  { Write-Host $Message -ForegroundColor Cyan }
        'Warn'  { Write-Host $Message -ForegroundColor Yellow }
        'Error' { Write-Host $Message -ForegroundColor Red }
    }
    
    # File output (if enabled)
    if ($script:UseFileLog -and $script:LogFile) {
        try {
            Add-Content -Path $script:LogFile -Value $logMessage -Encoding UTF8
        } catch {
            # Silent fallback: if file logging fails, continue anyway
        }
    }
}

# Initialize logging system
Initialize-Logging

#endregion

#region --- SERVICE ACCOUNT SETUP ---------------------------------------------

# Search and automatically configure Service Account if a JSON file is present
$scriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptDir)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

Write-Log -Message "Script directory: $scriptDir" -Level Info

# Search for JSON files in the script directory
$jsonFiles = @(Get-ChildItem -Path $scriptDir -Filter "*.json" -File -ErrorAction SilentlyContinue)

Write-Log -Message "Number of JSON files found: $($jsonFiles.Count)" -Level Info

if ($jsonFiles.Count -gt 0) {
    foreach ($file in $jsonFiles) {
        Write-Log -Message "JSON file found: $($file.Name)" -Level Info
    }
    
    # Select the first JSON file found
    $selectedFile = $jsonFiles[0]
    
    Write-Log -Message "Automatic Service Account configuration with: $($selectedFile.FullName)" -Level Info
    
    try {
        # Configure Service Account in non-interactive mode
        # -DisablePrompts: avoids confirmation prompts
        # -KeepOriginalClearTextFile NOT specified: JSON file is automatically deleted
        Set-RscServiceAccountFile $selectedFile.FullName -DisablePrompts -ErrorAction Stop
        Write-Log -Message "Service Account configured successfully" -Level Info
        Write-Log -Message "JSON file automatically deleted by Set-RscServiceAccountFile command" -Level Info
        
    } catch {
        Write-Log -Message "Error during Service Account configuration: $($_.Exception.Message)" -Level Error
        Write-Log -Message "Continuing with manual authentication..." -Level Warn
    }
} else {
    Write-Log -Message "No JSON files found in script directory" -Level Info
}

#endregion

#region --- RUBRIK SESSION UTILS ----------------------------------------------

function Safe-Disconnect {
    try {
        Disconnect-Rsc -ErrorAction Stop
        Write-Log -Message "Disconnection from Rubrik completed." -Level Info
    } catch {
        Write-Log -Message "Disconnection failed or session does not exist." -Level Warn
    }
}

#endregion

#region --- RUBRIK: CONNECT & DISCOVER ----------------------------------------

# Initial connection
try {
    Write-Log -Message "Connecting to Rubrik RSC..." -Level Info
    
    if ($PSBoundParameters.ContainsKey('Credential') -and $Credential) {
        Connect-Rsc -Credential $Credential
    } else {
        Connect-Rsc
    }
    $cluster = Get-RscCluster
    Write-Log -Message "Connected to Rubrik cluster: $($cluster.Name)" -Level Info
} catch {
    Write-Log -Message "Error Connect-Rsc: $($_.Exception.Message)" -Level Error
    Safe-Disconnect
    exit 1
}

# Retrieve host
try {
    Write-Log -Message "Searching for host '$HostName' (OsType: $OsType)..." -Level Info
    $hostObj = Get-RscHost -OsType $OsType -Name $HostName
} catch {
    Write-Log -Message "Error Get-RscHost: $($_.Exception.Message)" -Level Error
    Safe-Disconnect
    exit 1
}

if (-not $hostObj) {
    Write-Log -Message "Host '$HostName' not found." -Level Error
    Safe-Disconnect
    exit 1
}
Write-Log -Message "Host found: $($hostObj.Name)" -Level Info

# Extract cluster IP from CdmLink
Write-Log -Message "Extracting cluster IP from host's CdmLink..." -Level Info

$clusterIp = $null

if ($hostObj.PSObject.Properties.Name -contains 'CdmLink' -and -not [string]::IsNullOrWhiteSpace($hostObj.CdmLink)) {
    try {
        $uri = [System.Uri]::new($hostObj.CdmLink)
        $clusterIp = $uri.Host
        Write-Log -Message "Cluster IP extracted from CdmLink: $clusterIp" -Level Info
    } catch {
        Write-Log -Message "Error extracting IP from CdmLink: $($_.Exception.Message)" -Level Error
        Write-Log -Message "CdmLink value: $($hostObj.CdmLink)" -Level Error
        Safe-Disconnect
        exit 1
    }
} else {
    Write-Log -Message "CdmLink attribute not found or empty in host object." -Level Error
    Safe-Disconnect
    exit 1
}

if ([string]::IsNullOrWhiteSpace($clusterIp)) {
    Write-Log -Message "Unable to extract cluster IP from CdmLink." -Level Error
    Safe-Disconnect
    exit 1
}

# Test connectivity to cluster (if not skipped)
if ($SkipConnectivityCheck -eq 'No') {
    Write-Log -Message "Testing connectivity to $clusterIp..." -Level Info
    if (-not (Test-Connection -ComputerName $clusterIp -Count 2 -Quiet)) {
        Write-Log -Message "Rubrik cluster NOT reachable." -Level Error
        exit 1
    }
    Write-Log -Message "Rubrik cluster reachable." -Level Info
} else {
    Write-Log -Message "Skipping connectivity check (parameter SkipConnectivityCheck=Yes)" -Level Warn
}

# Filesets
try {
    $filesets = $hostObj | Get-RscFileset
} catch {
    Write-Log -Message "Error Get-RscFileset: $($_.Exception.Message)" -Level Error
    Safe-Disconnect
    exit 1
}

if (-not $filesets) {
    Write-Log -Message "No Filesets associated with the host." -Level Error
    Safe-Disconnect
    exit 1
}

$fileset = $null
if ($PSBoundParameters.ContainsKey('FilesetName') -and $FilesetName) {
    $exact = $filesets | Where-Object { $_.Name -eq $FilesetName }
    if ($exact -and $exact.Count -eq 1) {
        $fileset = $exact
    } else {
        $wild = $filesets | Where-Object { $_.Name -like $FilesetName }
        if (-not $wild) {
            Write-Log -Message "Fileset '$FilesetName' not found for host '$($hostObj.Name)'." -Level Error
            Safe-Disconnect
            exit 1
        }
        if ($wild.Count -gt 1) {
            $names = ($wild | Select-Object -ExpandProperty Name) -join ', '
            Write-Log -Message "Multiple Filesets match '$FilesetName': $names. Specify a more precise name." -Level Warn
            Safe-Disconnect
            exit 1
        } else {
            $fileset = $wild
        }
    }
} else {
    $fileset = $filesets | Select-Object -First 1
    Write-Log -Message "FilesetName not specified: falling back to first Fileset '$($fileset.Name)'." -Level Warn
}

Write-Log -Message "Fileset selected: $($fileset.Name)" -Level Info

# SLA
try {
    $sla = Get-RscSla -Name $SlaName
} catch {
    Write-Log -Message "Error Get-RscSla: $($_.Exception.Message)" -Level Error
    Safe-Disconnect
    exit 1
}

if (-not $sla) {
    Write-Log -Message "SLA '$SlaName' not found." -Level Error
    Safe-Disconnect
    exit 1
}
Write-Log -Message "SLA selected: $($sla.Name)" -Level Info

#endregion

#region --- CREATE SNAPSHOT ----------------------------------------------------

try {
    Write-Log -Message "Starting snapshot creation..." -Level Info
    
    $query = New-RscMutation -GqlMutation createFilesetSnapshot
    
    $query.Var.input = Get-RscType -Name CreateFilesetSnapshotInput
    $query.Var.input.Id = $fileset.Id
    
    $query.Var.input.Config = Get-RscType -Name BaseOnDemandSnapshotConfigInput
    $query.Var.input.Config.SlaId = $sla.Id
    
    $query.Field = Get-RscType -Name AsyncRequestStatus -InitialProperties id

    Write-Log -Message "Initiating snapshot for Fileset '$($fileset.Name)'..." -Level Info
    
    $result = $query.Invoke()
    Write-Log -Message "Snapshot initiated successfully. AsyncRequest ID: $($result.Id)" -Level Info
    
} catch {
    Write-Log -Message "ERROR during snapshot: $($_.Exception.Message)" -Level Error
    Safe-Disconnect
    exit 1
}

#endregion

#region --- CLEANUP & SUMMARY --------------------------------------------------

Safe-Disconnect

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "EXECUTION SUMMARY:" -ForegroundColor Yellow
Write-Host "  Host:             $($hostObj.Name)" -ForegroundColor Cyan
Write-Host "  Fileset:          $($fileset.Name)" -ForegroundColor Cyan
Write-Host "  SLA:              $($sla.Name)" -ForegroundColor Cyan
Write-Host "  Cluster IP:       $clusterIp" -ForegroundColor Cyan
Write-Host "  AsyncRequest ID:  $($result.Id)" -ForegroundColor Cyan
if ($script:UseFileLog -and $script:LogFile) {
    Write-Host "  Log file:         $script:LogFile" -ForegroundColor Cyan
}
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Write footer to log
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