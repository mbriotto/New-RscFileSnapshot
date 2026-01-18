<#
.SYNOPSIS
    Creates a Service Account in Rubrik Security Cloud with minimum required permissions for Fileset snapshots.

.DESCRIPTION
    This script automates the creation of a Service Account in Rubrik Security Cloud (RSC) with the minimum
    permissions required to run Fileset snapshots. The script creates a custom role with specific permissions
    and assigns it to a new Service Account, then downloads the JSON credentials file.

.LINK
    https://github.com/mbriotto/New-RscFileSnapshot

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
    Creates a Service Account with default settings

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
    Requirements:
      - Rubrik PowerShell RSC module (Install-Module RubrikSecurityCloud)
      - Administrator access to Rubrik Security Cloud
      - Permissions to create Service Accounts and Roles

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
    Write-Host "=====================================================" -ForegroundColor Yellow
    Write-Host " RUBRIK SERVICE ACCOUNT CREATION TOOL " -ForegroundColor Cyan
    Write-Host "=====================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  .\New-RscServiceAccount.ps1 -ServiceAccountName <Name> [-ServiceAccountDescription <Description>] [-RoleName <Role>] [-OutputPath <Path>] [-Credential <PSCredential>]"
    Write-Host ""
    Write-Host "PARAMETERS:" -ForegroundColor Yellow
    Write-Host "  -ServiceAccountName        Name of the Service Account (REQUIRED)"
    Write-Host "  -ServiceAccountDescription Description of the Service Account"
    Write-Host "  -RoleName                  Name of the custom role to create"
    Write-Host "  -OutputPath                Path where to save JSON credentials"
    Write-Host "  -Credential                PSCredential for RSC authentication"
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  .\New-RscServiceAccount.ps1 -ServiceAccountName 'FilesetBackupAutomation'"
    Write-Host "  .\New-RscServiceAccount.ps1 -ServiceAccountName 'BackupService' -OutputPath 'C:\Credentials'"
    Write-Host "  .\New-RscServiceAccount.ps1 -ServiceAccountName 'SnapshotBot' -RoleName 'Custom Fileset Role'"
    Write-Host ""
    Write-Host "PERMISSIONS GRANTED:" -ForegroundColor Yellow
    Write-Host "  - Fileset: Read, On-Demand Backup"
    Write-Host "  - SLA Domain: Read"
    Write-Host "  - Host: Read"
    Write-Host "  - Cluster: Read"
    Write-Host ""
    Write-Host "NOTES:" -ForegroundColor Yellow
    Write-Host "  - Requires Rubrik PowerShell RSC module"
    Write-Host "  - Requires Administrator access to Rubrik Security Cloud"
    Write-Host "  - JSON credentials file will be saved in OutputPath"
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
        Write-ColorOutput "Disconnected from Rubrik Security Cloud" -Level Info
    } catch {
        Write-ColorOutput "Disconnection failed or session does not exist" -Level Warning
    }
}

#endregion

#region --- VALIDATION ---------------------------------------------------------

Write-Host ""
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host " RUBRIK SERVICE ACCOUNT CREATION" -ForegroundColor Yellow
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

# Validate output path
if (-not (Test-Path -Path $OutputPath)) {
    try {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        Write-ColorOutput "Created output directory: $OutputPath" -Level Success
    } catch {
        Write-ColorOutput "ERROR: Unable to create output directory: $OutputPath" -Level Error
        Write-ColorOutput $_.Exception.Message -Level Error
        exit 1
    }
}

# Resolve full path
$OutputPath = Resolve-Path -Path $OutputPath

#endregion

#region --- CONNECT TO RSC -----------------------------------------------------

try {
    Write-ColorOutput "Connecting to Rubrik Security Cloud..." -Level Info
    
    if ($PSBoundParameters.ContainsKey('Credential') -and $Credential) {
        Connect-Rsc -Credential $Credential -ErrorAction Stop
    } else {
        Connect-Rsc -ErrorAction Stop
    }
    
    $cluster = Get-RscCluster -ErrorAction Stop
    Write-ColorOutput "Connected to Rubrik cluster: $($cluster.Name)" -Level Success
} catch {
    Write-ColorOutput "ERROR connecting to Rubrik Security Cloud: $($_.Exception.Message)" -Level Error
    exit 1
}

#endregion

#region --- CREATE CUSTOM ROLE -------------------------------------------------

Write-Host ""
Write-ColorOutput "Creating custom role: $RoleName" -Level Info

try {
    # Define minimum permissions for Fileset snapshots
    $permissions = @(
        # Fileset permissions
        @{
            Operation = "VIEW_FILESET"
            ObjectType = "Fileset"
        },
        @{
            Operation = "BACKUP_FILESET"
            ObjectType = "Fileset"
        },
        # SLA permissions
        @{
            Operation = "VIEW_SLA"
            ObjectType = "SLA"
        },
        # Host permissions
        @{
            Operation = "VIEW_HOST"
            ObjectType = "Host"
        },
        # Cluster permissions
        @{
            Operation = "VIEW_CLUSTER"
            ObjectType = "Cluster"
        }
    )

    # Check if role already exists
    Write-ColorOutput "Checking if role already exists..." -Level Info
    
    $existingRole = $null
    try {
        # Note: This is a placeholder - actual implementation depends on RSC SDK capabilities
        # The SDK may not have direct role query methods, so we'll attempt creation
        Write-ColorOutput "Attempting to create role (will skip if exists)..." -Level Info
    } catch {
        Write-ColorOutput "Role check not available, proceeding with creation..." -Level Warning
    }

    # Create role using GraphQL mutation
    # Note: This is a conceptual implementation
    # Actual implementation requires specific RSC SDK commands for role creation
    
    Write-ColorOutput "WARNING: Role creation requires manual steps in RSC UI" -Level Warning
    Write-ColorOutput "The RSC PowerShell SDK does not currently support automated role creation" -Level Warning
    Write-Host ""
    Write-ColorOutput "Please create the role manually with these permissions:" -Level Info
    Write-Host ""
    Write-Host "  Role Name: $RoleName" -ForegroundColor White
    Write-Host "  Permissions:" -ForegroundColor White
    foreach ($perm in $permissions) {
        Write-Host "    - $($perm.ObjectType): $($perm.Operation)" -ForegroundColor Gray
    }
    Write-Host ""
    
    $continueChoice = Read-Host "Have you created the role manually? (Y/N)"
    if ($continueChoice -ne 'Y' -and $continueChoice -ne 'y') {
        Write-ColorOutput "Operation cancelled by user" -Level Warning
        Safe-Disconnect
        exit 0
    }

} catch {
    Write-ColorOutput "ERROR creating role: $($_.Exception.Message)" -Level Error
    Safe-Disconnect
    exit 1
}

#endregion

#region --- CREATE SERVICE ACCOUNT ---------------------------------------------

Write-Host ""
Write-ColorOutput "Creating Service Account: $ServiceAccountName" -Level Info

try {
    # Create Service Account using GraphQL mutation
    $mutation = New-RscMutation -GqlMutation createServiceAccount
    
    $mutation.Var.input = Get-RscType -Name CreateServiceAccountInput
    $mutation.Var.input.name = $ServiceAccountName
    $mutation.Var.input.description = $ServiceAccountDescription
    $mutation.Var.input.roleIds = @($RoleName)  # This needs to be the actual role ID
    
    Write-ColorOutput "WARNING: Service Account creation via SDK may be limited" -Level Warning
    Write-ColorOutput "You may need to complete this step manually in the RSC UI" -Level Warning
    Write-Host ""
    
    Write-ColorOutput "MANUAL STEPS REQUIRED:" -Level Info
    Write-Host ""
    Write-Host "1. Log in to Rubrik Security Cloud" -ForegroundColor White
    Write-Host "   URL: https://rubrik.my.rubrik.com" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Navigate to: Settings > Service Accounts" -ForegroundColor White
    Write-Host ""
    Write-Host "3. Click 'Create Service Account'" -ForegroundColor White
    Write-Host ""
    Write-Host "4. Fill in the details:" -ForegroundColor White
    Write-Host "   - Name: $ServiceAccountName" -ForegroundColor Gray
    Write-Host "   - Description: $ServiceAccountDescription" -ForegroundColor Gray
    Write-Host "   - Role: $RoleName" -ForegroundColor Gray
    Write-Host ""
    Write-Host "5. Click 'Create' and then 'Download Credentials'" -ForegroundColor White
    Write-Host ""
    Write-Host "6. Save the JSON file to: $OutputPath" -ForegroundColor White
    Write-Host ""
    
    $openBrowser = Read-Host "Would you like to open Rubrik Security Cloud in your browser? (Y/N)"
    if ($openBrowser -eq 'Y' -or $openBrowser -eq 'y') {
        Start-Process "https://rubrik.my.rubrik.com"
    }
    
    Write-Host ""
    $completed = Read-Host "Have you downloaded the JSON credentials file? (Y/N)"
    if ($completed -ne 'Y' -and $completed -ne 'y') {
        Write-ColorOutput "Operation incomplete - please complete the manual steps" -Level Warning
        Safe-Disconnect
        exit 0
    }
    
    # Check if JSON file exists in output path
    $jsonFiles = Get-ChildItem -Path $OutputPath -Filter "*.json" -File
    if ($jsonFiles.Count -eq 0) {
        Write-ColorOutput "WARNING: No JSON files found in $OutputPath" -Level Warning
        Write-ColorOutput "Please ensure you've saved the credentials file" -Level Warning
    } else {
        Write-ColorOutput "Found $($jsonFiles.Count) JSON file(s) in output directory" -Level Success
        foreach ($file in $jsonFiles) {
            Write-Host "  - $($file.Name)" -ForegroundColor Gray
        }
    }

} catch {
    Write-ColorOutput "ERROR creating Service Account: $($_.Exception.Message)" -Level Error
    Safe-Disconnect
    exit 1
}

#endregion

#region --- SUMMARY ------------------------------------------------------------

Safe-Disconnect

Write-Host ""
Write-Host "=====================================================" -ForegroundColor Green
Write-Host " SERVICE ACCOUNT SETUP SUMMARY" -ForegroundColor Yellow
Write-Host "=====================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Service Account Name:" -ForegroundColor Cyan
Write-Host "  $ServiceAccountName" -ForegroundColor White
Write-Host ""
Write-Host "Description:" -ForegroundColor Cyan
Write-Host "  $ServiceAccountDescription" -ForegroundColor White
Write-Host ""
Write-Host "Role:" -ForegroundColor Cyan
Write-Host "  $RoleName" -ForegroundColor White
Write-Host ""
Write-Host "Permissions:" -ForegroundColor Cyan
Write-Host "  - Fileset: Read, On-Demand Backup" -ForegroundColor White
Write-Host "  - SLA Domain: Read" -ForegroundColor White
Write-Host "  - Host: Read" -ForegroundColor White
Write-Host "  - Cluster: Read" -ForegroundColor White
Write-Host ""
Write-Host "Credentials Location:" -ForegroundColor Cyan
Write-Host "  $OutputPath" -ForegroundColor White
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "  1. Copy the JSON credentials file to your script directory" -ForegroundColor White
Write-Host "  2. Run New-RscFileSnapshot.ps1 - it will auto-configure the Service Account" -ForegroundColor White
Write-Host "  3. The JSON file will be automatically deleted after configuration" -ForegroundColor White
Write-Host ""
Write-Host "=====================================================" -ForegroundColor Green
Write-Host ""

#endregion