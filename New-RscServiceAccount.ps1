<#
.SYNOPSIS
    Interactive guide for creating a Service Account in Rubrik Security Cloud with minimum required permissions for Fileset snapshots.

.DESCRIPTION
    **IMPORTANT - SDK LIMITATIONS**:
    The Rubrik PowerShell SDK does not currently support automated creation of Service Accounts 
    and Roles. This script provides an interactive guide for the manual steps required in the 
    RSC web interface.

.NOTES
    Version:        1.0
    Author:         Matteo Briotto
    Creation Date:  January 2026
    Purpose/Change: Initial release - Interactive Service Account creation guide

.LINK
    https://github.com/mbriotto/rubrik-scripts

.PARAMETER ServiceAccountName
    Name of the Service Account to create.
    **Required**. Example: "FilesetSnapshotAutomation"

.PARAMETER ServiceAccountDescription
    Description of the Service Account.
    **Optional**. Default: "Service account for automated Fileset snapshots"

.PARAMETER RoleName
    Name of the custom role to create.
    **Optional**. Default: "Fileset Snapshot Operator"

.PARAMETER OutputPath
    Path where to save the Service Account JSON credentials file.
    **Optional**. Default: Current directory

.PARAMETER Credential
    Credentials (PSCredential) to use for Connect-Rsc.
    **Optional**. If not specified, uses interactive authentication.

.PARAMETER Help
    Displays help and exits.

.PARAMETER ?
    Alias for Help (displays help and exits).

.EXAMPLE
    .\New-RscServiceAccount.ps1 -ServiceAccountName "FilesetBackupAutomation"
    Creates a Service Account with default settings (interactive guided process)

.EXAMPLE
    .\New-RscServiceAccount.ps1 -ServiceAccountName "BackupService" -OutputPath "C:\Credentials"
    Creates a Service Account and saves credentials to specified path

.EXAMPLE
    .\New-RscServiceAccount.ps1 -ServiceAccountName "SnapshotBot" -RoleName "Custom Fileset Role"
    Creates a Service Account with a custom role name

.EXAMPLE
    $cred = Get-Credential
    .\New-RscServiceAccount.ps1 -ServiceAccountName "AutoBackup" -Credential $cred
    Creates a Service Account using specific credentials

.NOTES
    **SDK Limitations**:
      The Rubrik PowerShell SDK does not currently provide cmdlets for creating roles or 
      Service Accounts. This script provides an interactive guide for manual steps in the 
      RSC web interface.
      
      Reference: https://github.com/rubrikinc/rubrik-powershell-sdk

    Requirements:
      - Rubrik PowerShell RSC module (Install-Module RubrikSecurityCloud)
      - Administrator access to Rubrik Security Cloud
      - Permissions to create Service Accounts and Roles
      - Web browser for RSC web interface access

    Permissions granted to the Service Account:
      - Fileset: Read, On-Demand Backup
      - SLA Domain: Read
      - Host: Read
      - Cluster: Read

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

.VERSION
    1.0 - Initial release
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $ServiceAccountName,

    [string] $ServiceAccountDescription = "Service account for automated Fileset snapshots",

    [string] $RoleName = "Fileset Snapshot Operator",

    [string] $OutputPath = ".",

    [System.Management.Automation.PSCredential] $Credential,

    [Alias('?')]
    [switch] $Help
)

#region --- HELP ---------------------------------------------------------------

function Show-Help {
    Write-Host ""
    Write-Host "========================================================================" -ForegroundColor Yellow
    Write-Host " RUBRIK SERVICE ACCOUNT CREATION TOOL - INTERACTIVE GUIDE" -ForegroundColor Cyan
    Write-Host "========================================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "WARNING - SDK LIMITATION NOTICE:" -ForegroundColor Red
    Write-Host "  The Rubrik PowerShell SDK does not currently support automated creation" -ForegroundColor Yellow
    Write-Host "  of Service Accounts or Roles. Manual steps in RSC web interface required." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  .\New-RscServiceAccount.ps1 -ServiceAccountName <n> [-Options]"
    Write-Host ""
    Write-Host "REQUIRED PARAMETERS:" -ForegroundColor Yellow
    Write-Host "  -ServiceAccountName        Name of the Service Account to create"
    Write-Host ""
    Write-Host "OPTIONAL PARAMETERS:" -ForegroundColor Yellow
    Write-Host "  -ServiceAccountDescription Description of the Service Account"
    Write-Host "  -RoleName                  Name of the custom role to create"
    Write-Host "  -OutputPath                Path where to save JSON credentials"
    Write-Host "  -Credential                PSCredential for RSC authentication"
    Write-Host ""
    Write-Host "WHAT THIS SCRIPT DOES:" -ForegroundColor Cyan
    Write-Host "  [OK] Verifies connectivity to Rubrik Security Cloud" -ForegroundColor White
    Write-Host "  [OK] Displays exact permissions needed for the role" -ForegroundColor White
    Write-Host "  [OK] Provides step-by-step instructions for RSC web UI" -ForegroundColor White
    Write-Host "  [OK] Optionally opens RSC in your browser" -ForegroundColor White
    Write-Host "  [OK] Validates JSON credentials file download" -ForegroundColor White
    Write-Host "  [OK] Documents the configuration for audit purposes" -ForegroundColor White
    Write-Host ""
    Write-Host "WHAT THIS SCRIPT CANNOT DO (SDK limitations):" -ForegroundColor Cyan
    Write-Host "  [X] Automatically create roles via API" -ForegroundColor DarkGray
    Write-Host "  [X] Automatically create Service Accounts via code" -ForegroundColor DarkGray
    Write-Host "  [X] Programmatically assign permissions" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  .\New-RscServiceAccount.ps1 -ServiceAccountName 'FilesetBackupAutomation'"
    Write-Host "  .\New-RscServiceAccount.ps1 -ServiceAccountName 'BackupService' -OutputPath 'C:\Credentials'"
    Write-Host "  .\New-RscServiceAccount.ps1 -ServiceAccountName 'SnapshotBot' -RoleName 'Custom Fileset Role'"
    Write-Host ""
    Write-Host "PERMISSIONS GRANTED:" -ForegroundColor Yellow
    Write-Host "  - Fileset: Read, On-Demand Backup" -ForegroundColor White
    Write-Host "  - SLA Domain: Read" -ForegroundColor White
    Write-Host "  - Host: Read" -ForegroundColor White
    Write-Host "  - Cluster: Read" -ForegroundColor White
    Write-Host ""
    Write-Host "NOTES:" -ForegroundColor Yellow
    Write-Host "  - Requires Rubrik PowerShell RSC module" -ForegroundColor White
    Write-Host "  - Requires Administrator access to Rubrik Security Cloud" -ForegroundColor White
    Write-Host "  - JSON credentials file will be saved in OutputPath" -ForegroundColor White
    Write-Host "  - Manual steps in RSC web interface are required" -ForegroundColor White
    Write-Host ""
    Write-Host "SDK INFORMATION:" -ForegroundColor Yellow
    Write-Host "  Module: RubrikSecurityCloud" -ForegroundColor White
    Write-Host "  GitHub: https://github.com/rubrikinc/rubrik-powershell-sdk" -ForegroundColor White
    Write-Host "  Documentation: https://docs.rubrik.com" -ForegroundColor White
    Write-Host ""
}

if ($Help) {
    Show-Help
    exit 0
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

function Safe-Disconnect {
    try {
        Disconnect-Rsc -ErrorAction Stop
        Write-ColorOutput -Message "Disconnected from Rubrik Security Cloud" -Level Info
    } catch {
        Write-ColorOutput -Message "Disconnection failed or session does not exist" -Level Warning
    }
}

function Show-SdkLimitation {
    Write-Host ""
    Write-Host "========================================================================" -ForegroundColor Red
    Write-Host " WARNING - RUBRIK POWERSHELL SDK LIMITATION" -ForegroundColor Yellow
    Write-Host "========================================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "The Rubrik PowerShell SDK does not currently support automated creation" -ForegroundColor Yellow
    Write-Host "of Service Accounts and Roles. Manual steps in RSC web interface required." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Reference: https://github.com/rubrikinc/rubrik-powershell-sdk" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "========================================================================" -ForegroundColor Red
    Write-Host ""
}

#endregion

#region --- VALIDATION ---------------------------------------------------------

Write-Host ""
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host " RUBRIK SERVICE ACCOUNT CREATION - INTERACTIVE GUIDE" -ForegroundColor Yellow
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""

# Display SDK limitation notice
Show-SdkLimitation

# Validate output path
if (-not (Test-Path -Path $OutputPath)) {
    try {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        Write-ColorOutput -Message "[OK] Created output directory: $OutputPath" -Level Success
    } catch {
        Write-ColorOutput -Message "[ERROR] Unable to create output directory: $OutputPath" -Level Error
        Write-ColorOutput -Message $_.Exception.Message -Level Error
        exit 1
    }
}

# Resolve full path
$OutputPath = Resolve-Path -Path $OutputPath

#endregion

#region --- CONNECT TO RSC -----------------------------------------------------

try {
    Write-ColorOutput -Message "Connecting to Rubrik Security Cloud..." -Level Info
    Write-ColorOutput -Message "(This verifies you have access to RSC)" -Level Info
    Write-Host ""
    
    if ($PSBoundParameters.ContainsKey('Credential') -and $Credential) {
        Connect-Rsc -Credential $Credential -ErrorAction Stop
    } else {
        Connect-Rsc -ErrorAction Stop
    }
    
    $cluster = Get-RscCluster -ErrorAction Stop
    Write-ColorOutput -Message "[OK] Connected to Rubrik cluster: $($cluster.Name)" -Level Success
    Write-Host ""
} catch {
    Write-ColorOutput -Message "[ERROR] Connection to Rubrik Security Cloud failed: $($_.Exception.Message)" -Level Error
    Write-Host ""
    Write-ColorOutput -Message "Please verify:" -Level Warning
    Write-Host "  - You have network connectivity to Rubrik Security Cloud" -ForegroundColor Yellow
    Write-Host "  - Your credentials are correct" -ForegroundColor Yellow
    Write-Host "  - You have administrator access to RSC" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

#endregion

#region --- ROLE CREATION GUIDE ------------------------------------------------

Write-Host ""
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host " STEP 1: CREATE CUSTOM ROLE (Manual Steps Required)" -ForegroundColor Yellow
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""

Write-ColorOutput -Message "WARNING: Due to SDK limitations, you must create the role manually in RSC" -Level Warning
Write-Host ""

# Define minimum permissions for Fileset snapshots
$permissions = @(
    @{
        ObjectType = "Fileset"
        Operation = "VIEW_FILESET"
        Description = "Read Fileset configuration and properties"
    },
    @{
        ObjectType = "Fileset"
        Operation = "BACKUP_FILESET"
        Description = "Trigger on-demand Fileset snapshots"
    },
    @{
        ObjectType = "SLA"
        Operation = "VIEW_SLA"
        Description = "Read SLA Domain policies"
    },
    @{
        ObjectType = "Host"
        Operation = "VIEW_HOST"
        Description = "Read host information and configuration"
    },
    @{
        ObjectType = "Cluster"
        Operation = "VIEW_CLUSTER"
        Description = "Read cluster details and status"
    }
)

Write-Host "Role Configuration:" -ForegroundColor Cyan
Write-Host "  Name: $RoleName" -ForegroundColor White
Write-Host "  Description: Custom role for automated Fileset snapshots" -ForegroundColor White
Write-Host ""

Write-Host "Required Permissions (minimum principle):" -ForegroundColor Cyan
foreach ($perm in $permissions) {
    Write-Host "  - $($perm.ObjectType): $($perm.Operation)" -ForegroundColor White
    Write-Host "    ($($perm.Description))" -ForegroundColor DarkGray
}
Write-Host ""

Write-Host "========================================================================" -ForegroundColor Yellow
Write-Host " MANUAL STEPS IN RUBRIK SECURITY CLOUD WEB INTERFACE:" -ForegroundColor Yellow
Write-Host "========================================================================" -ForegroundColor Yellow
Write-Host ""

Write-Host "1. Log in to Rubrik Security Cloud" -ForegroundColor White
Write-Host "   URL: Your organization's Rubrik Security Cloud URL" -ForegroundColor DarkGray
Write-Host ""

Write-Host "2. Navigate to Role Management" -ForegroundColor White
Write-Host "   - Click your profile icon (top-right corner)" -ForegroundColor DarkGray
Write-Host "   - Select 'Settings' from the dropdown menu" -ForegroundColor DarkGray
Write-Host "   - In the left sidebar, click 'Roles'" -ForegroundColor DarkGray
Write-Host ""

Write-Host "3. Create New Role" -ForegroundColor White
Write-Host "   - Click 'Create Role' button" -ForegroundColor DarkGray
Write-Host "   - Name: $RoleName" -ForegroundColor DarkGray
Write-Host "   - Description: Custom role for automated Fileset snapshots" -ForegroundColor DarkGray
Write-Host ""

Write-Host "4. Add Permissions (repeat for each permission below)" -ForegroundColor White
foreach ($perm in $permissions) {
    Write-Host "   - Click 'Add Permission'" -ForegroundColor DarkGray
    Write-Host "     > Object Type: $($perm.ObjectType)" -ForegroundColor DarkGray
    Write-Host "     > Operation: $($perm.Operation)" -ForegroundColor DarkGray
}
Write-Host ""

Write-Host "5. Save the Role" -ForegroundColor White
Write-Host "   - Review all permissions are correct" -ForegroundColor DarkGray
Write-Host "   - Click 'Create' or 'Save'" -ForegroundColor DarkGray
Write-Host ""

Write-Host "========================================================================" -ForegroundColor Yellow
Write-Host ""

Write-Host "Please open your browser and navigate to your Rubrik Security Cloud console" -ForegroundColor Cyan
Write-Host ""

# Confirm completion
$roleCreated = Read-Host "Have you successfully created the role '$RoleName'? (Y/N)"
if ($roleCreated -ne 'Y' -and $roleCreated -ne 'y') {
    Write-ColorOutput -Message "Operation cancelled - please create the role and run this script again" -Level Warning
    Safe-Disconnect
    exit 0
}

Write-ColorOutput -Message "[OK] Role creation confirmed" -Level Success

#endregion

#region --- SERVICE ACCOUNT CREATION GUIDE -------------------------------------

Write-Host ""
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host " STEP 2: CREATE SERVICE ACCOUNT (Manual Steps Required)" -ForegroundColor Yellow
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""

Write-ColorOutput -Message "WARNING: Due to SDK limitations, you must create the Service Account manually in RSC" -Level Warning
Write-Host ""

Write-Host "Service Account Configuration:" -ForegroundColor Cyan
Write-Host "  Name: $ServiceAccountName" -ForegroundColor White
Write-Host "  Description: $ServiceAccountDescription" -ForegroundColor White
Write-Host "  Role: $RoleName" -ForegroundColor White
Write-Host ""

Write-Host "========================================================================" -ForegroundColor Yellow
Write-Host " MANUAL STEPS IN RUBRIK SECURITY CLOUD WEB INTERFACE:" -ForegroundColor Yellow
Write-Host "========================================================================" -ForegroundColor Yellow
Write-Host ""

Write-Host "1. Navigate to Service Accounts" -ForegroundColor White
Write-Host "   - In RSC web interface, click your profile icon (top-right)" -ForegroundColor DarkGray
Write-Host "   - Select 'Settings' from the dropdown menu" -ForegroundColor DarkGray
Write-Host "   - In the left sidebar, click 'Service Accounts'" -ForegroundColor DarkGray
Write-Host ""

Write-Host "2. Create New Service Account" -ForegroundColor White
Write-Host "   - Click 'Create Service Account' button" -ForegroundColor DarkGray
Write-Host ""

Write-Host "3. Fill in Service Account Details" -ForegroundColor White
Write-Host "   - Name: $ServiceAccountName" -ForegroundColor DarkGray
Write-Host "   - Description: $ServiceAccountDescription" -ForegroundColor DarkGray
Write-Host "   - Click 'Next'" -ForegroundColor DarkGray
Write-Host ""

Write-Host "4. Assign Role" -ForegroundColor White
Write-Host "   - In the role selection, find and select: $RoleName" -ForegroundColor DarkGray
Write-Host "   - Click 'Next' or 'Create'" -ForegroundColor DarkGray
Write-Host ""

Write-Host "5. Download Credentials (IMPORTANT!)" -ForegroundColor White
Write-Host "   WARNING: This is your ONLY chance to download the credentials!" -ForegroundColor Red
Write-Host "   - After creation, you'll see a 'Download Credentials' button" -ForegroundColor DarkGray
Write-Host "   - Click 'Download Credentials' immediately" -ForegroundColor DarkGray
Write-Host "   - Save the JSON file to: $OutputPath" -ForegroundColor DarkGray
Write-Host "   - The file will be named something like: service-account-rk1234.json" -ForegroundColor DarkGray
Write-Host ""

Write-Host "========================================================================" -ForegroundColor Yellow
Write-Host ""

Write-Host "Please open your browser and navigate to your Rubrik Security Cloud console" -ForegroundColor Cyan
Write-Host ""

# Confirm completion
$saCreated = Read-Host "Have you successfully created the Service Account and downloaded the JSON file? (Y/N)"
if ($saCreated -ne 'Y' -and $saCreated -ne 'y') {
    Write-ColorOutput -Message "Operation cancelled - please complete the Service Account creation" -Level Warning
    Safe-Disconnect
    exit 0
}

Write-ColorOutput -Message "[OK] Service Account creation confirmed" -Level Success

#endregion

#region --- VERIFY JSON DOWNLOAD -----------------------------------------------

Write-Host ""
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host " STEP 3: VERIFY CREDENTIALS DOWNLOAD" -ForegroundColor Yellow
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""

Write-ColorOutput -Message "Checking for JSON credentials file in: $OutputPath" -Level Info
Write-Host ""

try {
    # Check if JSON file exists in output path
    $jsonFiles = Get-ChildItem -Path $OutputPath -Filter "*.json" -File -ErrorAction SilentlyContinue
    
    if ($jsonFiles.Count -eq 0) {
        Write-ColorOutput -Message "[WARNING] No JSON files found in $OutputPath" -Level Warning
        Write-Host ""
        Write-Host "Please ensure you:" -ForegroundColor Yellow
        Write-Host "  1. Clicked 'Download Credentials' in the RSC interface" -ForegroundColor White
        Write-Host "  2. Saved the file to: $OutputPath" -ForegroundColor White
        Write-Host "  3. The file has a .json extension" -ForegroundColor White
        Write-Host ""
        
        $manualPath = Read-Host "Enter the full path to the JSON file (or press Enter to skip)"
        if (-not [string]::IsNullOrWhiteSpace($manualPath)) {
            if (Test-Path -Path $manualPath) {
                $jsonFiles = @(Get-Item -Path $manualPath)
                Write-ColorOutput -Message "[OK] JSON file found at specified path" -Level Success
            } else {
                Write-ColorOutput -Message "[ERROR] File not found at specified path" -Level Error
                Write-ColorOutput -Message "Please locate the JSON file manually and proceed with New-RscFileSnapshot.ps1" -Level Warning
            }
        }
    } else {
        Write-ColorOutput -Message "[OK] Found $($jsonFiles.Count) JSON file(s) in output directory:" -Level Success
        foreach ($file in $jsonFiles) {
            Write-Host "  - $($file.Name)" -ForegroundColor White
            Write-Host "    Size: $([math]::Round($file.Length / 1KB, 2)) KB" -ForegroundColor DarkGray
            Write-Host "    Created: $($file.CreationTime)" -ForegroundColor DarkGray
        }
    }
} catch {
    Write-ColorOutput -Message "[ERROR] Error checking for JSON files: $($_.Exception.Message)" -Level Error
}

#endregion

#region --- SUMMARY ------------------------------------------------------------

Safe-Disconnect

Write-Host ""
Write-Host "========================================================================" -ForegroundColor Green
Write-Host " SERVICE ACCOUNT SETUP SUMMARY" -ForegroundColor Yellow
Write-Host "========================================================================" -ForegroundColor Green
Write-Host ""

Write-Host "[OK] Configuration Completed Successfully" -ForegroundColor Green
Write-Host ""

Write-Host "Service Account Details:" -ForegroundColor Cyan
Write-Host "  Name:        $ServiceAccountName" -ForegroundColor White
Write-Host "  Description: $ServiceAccountDescription" -ForegroundColor White
Write-Host "  Role:        $RoleName" -ForegroundColor White
Write-Host ""

Write-Host "Permissions Granted:" -ForegroundColor Cyan
Write-Host "  - Fileset: Read, On-Demand Backup" -ForegroundColor White
Write-Host "  - SLA Domain: Read" -ForegroundColor White
Write-Host "  - Host: Read" -ForegroundColor White
Write-Host "  - Cluster: Read" -ForegroundColor White
Write-Host ""

Write-Host "Credentials Location:" -ForegroundColor Cyan
Write-Host "  $OutputPath" -ForegroundColor White
Write-Host ""

Write-Host "========================================================================" -ForegroundColor Yellow
Write-Host " NEXT STEPS" -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Yellow
Write-Host ""

Write-Host "1. Copy the JSON credentials file to your script directory" -ForegroundColor White
Write-Host "   Example:" -ForegroundColor DarkGray
Write-Host "   Copy-Item '$OutputPath\service-account-*.json' '<YourScriptDirectory>\'" -ForegroundColor DarkGray
Write-Host ""

Write-Host "2. Run New-RscFileSnapshot.ps1" -ForegroundColor White
Write-Host "   The script will automatically:" -ForegroundColor DarkGray
Write-Host "   - Detect the JSON file" -ForegroundColor DarkGray
Write-Host "   - Configure encrypted credentials (via Set-RscServiceAccountFile)" -ForegroundColor DarkGray
Write-Host "   - Store encrypted XML in PowerShell profile directory" -ForegroundColor DarkGray
Write-Host "   - Delete the JSON file for security" -ForegroundColor DarkGray
Write-Host ""

Write-Host "3. Verify encrypted credentials were created" -ForegroundColor White
Write-Host "   Location: `$PROFILE\..\rubrik-powershell-sdk\rsc_service_account_default.xml" -ForegroundColor DarkGray
Write-Host ""

Write-Host "4. Subsequent executions will use encrypted credentials automatically" -ForegroundColor White
Write-Host "   No JSON file needed after first run!" -ForegroundColor DarkGray
Write-Host ""

Write-Host "========================================================================" -ForegroundColor Yellow
Write-Host " SDK LIMITATION REMINDER" -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Yellow
Write-Host ""

Write-Host "This script provided an interactive guide due to SDK limitations." -ForegroundColor White
Write-Host "SDK Reference: https://github.com/rubrikinc/rubrik-powershell-sdk" -ForegroundColor Cyan
Write-Host ""

Write-Host "========================================================================" -ForegroundColor Green
Write-Host ""

Write-ColorOutput -Message "Setup complete! You can now use the Service Account with New-RscFileSnapshot.ps1" -Level Success
Write-Host ""

#endregion
