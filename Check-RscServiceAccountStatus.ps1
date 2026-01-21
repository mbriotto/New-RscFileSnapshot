<#
.SYNOPSIS
    Checks the status of Rubrik Service Account configuration.

.DESCRIPTION
    This diagnostic script checks if Rubrik Service Account encrypted credentials exist
    for current user, SYSTEM account (via standard location), and SYSTEM via PsExec.
    At the end of execution, prompts user to delete any found credential files.

.PARAMETER Help
    Displays help and exits.

.PARAMETER ?
    Alias for Help (displays help and exits).

.EXAMPLE
    .\Check-RscServiceAccountStatus.ps1
    Checks credential status and prompts for deletion at the end

.NOTES
    Version: 1.0
    Author: Matteo Briotto
    Creation Date: January 2026
    Purpose/Change: Initial release - Service Account credential verification tool
    
    Features:
    - Check RubrikSecurityCloud module installation status
    - Check encrypted credentials for CURRENT USER
    - Check encrypted credentials for SYSTEM account (standard location)
    - Check encrypted credentials for SYSTEM via PsExec (if PsExec detected)
    - Interactive deletion menu for credential management
    - Detailed credential file information (size, dates, location)
    - Contextual recommendations based on configuration status
    
.LINK
    https://github.com/mbriotto/rubrik-scripts
#>

[CmdletBinding()]
param(
    [Alias('?')]
    [switch] $Help
)

#region --- HELP ---------------------------------------------------------------

function Show-Help {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host " RUBRIK SERVICE ACCOUNT STATUS CHECK - HELP" -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  .\Check-RscServiceAccountStatus.ps1"
    Write-Host ""
    Write-Host "PARAMETERS:" -ForegroundColor Yellow
    Write-Host "  -Help / -?            Display this help message"
    Write-Host ""
    Write-Host "WHAT THIS SCRIPT DOES:" -ForegroundColor Yellow
    Write-Host "  1. Checks if RubrikSecurityCloud PowerShell module is installed"
    Write-Host "  2. Checks for encrypted credentials for CURRENT USER"
    Write-Host "  3. Checks for encrypted credentials for SYSTEM account (standard location)"
    Write-Host "  4. Checks for encrypted credentials for SYSTEM via PsExec (if PsExec detected)"
    Write-Host "  5. At the end, prompts to delete any found credential files"
    Write-Host ""
    Write-Host "CREDENTIAL LOCATIONS:" -ForegroundColor Yellow
    Write-Host "  Current User:  %USERPROFILE%\Documents\WindowsPowerShell\rubrik-powershell-sdk\"
    Write-Host "  SYSTEM:        C:\Windows\System32\config\systemprofile\Documents\WindowsPowerShell\rubrik-powershell-sdk\"
    Write-Host "  SYSTEM/PsExec: C:\Windows\SysWOW64\config\systemprofile\Documents\WindowsPowerShell\rubrik-powershell-sdk\"
    Write-Host ""
    Write-Host "NOTE ABOUT SYSTEM (PsExec):" -ForegroundColor Yellow
    Write-Host "  When you run a script as SYSTEM using PsExec, Windows may create credentials"
    Write-Host "  in a different location (SysWOW64 instead of System32). This script checks"
    Write-Host "  both locations if PsExec.exe is detected in the script directory."
    Write-Host ""
    Write-Host "INTERACTIVE DELETION:" -ForegroundColor Yellow
    Write-Host "  At the end of the check, you'll be prompted to select which credentials"
    Write-Host "  to delete (if any were found). You can choose:"
    Write-Host "    [1,2,3...] - Delete specific credential files individually"
    Write-Host "    [A]        - Delete all credential files at once"
    Write-Host "    [0]        - Exit without deleting anything"
    Write-Host ""
}

if ($Help) {
    Show-Help
    exit 0
}

#endregion

#region --- FUNCTIONS ----------------------------------------------------------

function Get-SystemProfilePath {
    <#
    .SYNOPSIS
        Gets the PowerShell profile path for the SYSTEM account
    #>
    
    # SYSTEM account profile location varies by OS
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        # PowerShell Core/7+
        return "C:\Windows\System32\config\systemprofile\Documents\PowerShell"
    } else {
        # Windows PowerShell 5.1
        return "C:\Windows\System32\config\systemprofile\Documents\WindowsPowerShell"
    }
}

function Get-SystemPsExecProfilePath {
    <#
    .SYNOPSIS
        Gets the PowerShell profile path for SYSTEM when running via PsExec
    #>
    
    # PsExec typically uses SysWOW64 on 64-bit systems
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        # PowerShell Core/7+
        return "C:\Windows\SysWOW64\config\systemprofile\Documents\PowerShell"
    } else {
        # Windows PowerShell 5.1
        return "C:\Windows\SysWOW64\config\systemprofile\Documents\WindowsPowerShell"
    }
}

function Find-AllCredentialFiles {
    <#
    .SYNOPSIS
        Searches for all rsc_service_account_default.xml files on the system
    #>
    
    Write-Host ""
    Write-Host "Searching for credential files in all Windows profile locations..." -ForegroundColor Yellow
    Write-Host "This may take a moment..." -ForegroundColor Gray
    Write-Host ""
    
    $searchPaths = @(
        "C:\Users",
        "C:\Windows\System32\config\systemprofile",
        "C:\Windows\SysWOW64\config\systemprofile"
    )
    
    # Also check the script directory (in case of misconfigured $PROFILE)
    $scriptDir = Split-Path -Parent $MyInvocation.ScriptName
    if ($scriptDir) {
        $searchPaths += $scriptDir
    }
    
    $foundFiles = @()
    
    foreach ($path in $searchPaths) {
        if (Test-Path $path) {
            try {
                $files = Get-ChildItem -Path $path -Filter "rsc_service_account_default.xml" -Recurse -ErrorAction SilentlyContinue -Force
                foreach ($file in $files) {
                    $foundFiles += @{
                        Path = $file.FullName
                        Size = $file.Length
                        Created = $file.CreationTime
                        Modified = $file.LastWriteTime
                    }
                }
            } catch {
                # Silently skip access denied errors
            }
        }
    }
    
    if ($foundFiles.Count -gt 0) {
        Write-Host "Found $($foundFiles.Count) credential file(s):" -ForegroundColor Green
        Write-Host ""
        foreach ($file in $foundFiles) {
            Write-Host "  Location: $($file.Path)" -ForegroundColor Cyan
            Write-Host "  Size: $($file.Size) bytes" -ForegroundColor Gray
            Write-Host "  Created: $($file.Created)" -ForegroundColor Gray
            Write-Host "  Modified: $($file.Modified)" -ForegroundColor Gray
            Write-Host ""
        }
    } else {
        Write-Host "No credential files found in common locations" -ForegroundColor Yellow
        Write-Host ""
    }
    
    return $foundFiles
}

function Test-PsExecAvailable {
    <#
    .SYNOPSIS
        Checks if PsExec.exe is available in the script directory
    #>
    
    $scriptDir = Split-Path -Parent $MyInvocation.ScriptName
    if (-not $scriptDir) {
        $scriptDir = Get-Location
    }
    
    $psexecPath = Join-Path $scriptDir "PsExec.exe"
    $psexec64Path = Join-Path $scriptDir "PsExec64.exe"
    
    if (Test-Path $psexecPath) {
        return @{
            Available = $true
            Path = $psexecPath
            Version = "32-bit"
        }
    } elseif (Test-Path $psexec64Path) {
        return @{
            Available = $true
            Path = $psexec64Path
            Version = "64-bit"
        }
    } else {
        return @{
            Available = $false
            Path = $null
            Version = $null
        }
    }
}

function Test-CredentialFile {
    param(
        [string]$BasePath,
        [string]$AccountName,
        [string]$AccountType  # "CurrentUser", "System", "SystemPsExec"
    )
    
    $credPath = Join-Path $BasePath "rubrik-powershell-sdk\rsc_service_account_default.xml"
    
    Write-Host ""
    Write-Host "Checking $AccountName credentials..." -ForegroundColor Yellow
    Write-Host "Expected location: $credPath" -ForegroundColor Gray
    Write-Host ""
    
    $found = $false
    $fileInfo = $null
    
    if (Test-Path -Path $credPath) {
        $found = $true
        $fileInfo = Get-Item -Path $credPath
        
        Write-Host " [+] CREDENTIALS FOUND" -ForegroundColor Green
        Write-Host ""
        
        Write-Host "Credential File Details:" -ForegroundColor Cyan
        Write-Host "  Account: $AccountName" -ForegroundColor White
        Write-Host "  Location: $($fileInfo.FullName)" -ForegroundColor White
        Write-Host "  Size: $($fileInfo.Length) bytes" -ForegroundColor White
        Write-Host "  Created: $($fileInfo.CreationTime)" -ForegroundColor White
        Write-Host "  Last Modified: $($fileInfo.LastWriteTime)" -ForegroundColor White
        Write-Host "  Last Accessed: $($fileInfo.LastAccessTime)" -ForegroundColor White
        
    } else {
        Write-Host " [-] CREDENTIALS NOT FOUND" -ForegroundColor Red
    }
    
    return @{
        Found = $found
        Path = $credPath
        FileInfo = $fileInfo
        AccountName = $AccountName
        AccountType = $AccountType
    }
}

function Remove-CredentialFile {
    param(
        [Parameter(Mandatory)]
        [hashtable]$CredInfo
    )
    
    Write-Host ""
    Write-Host "Attempting to delete: $($CredInfo['AccountName'])" -ForegroundColor Yellow
    Write-Host "Location: $($CredInfo['Path'])" -ForegroundColor Gray
    
    try {
        Remove-Item -Path $CredInfo['Path'] -Force -ErrorAction Stop
        Write-Host " [+] Successfully deleted" -ForegroundColor Green
        return $true
    } catch {
        Write-Host " [-] ERROR: $($_.Exception.Message)" -ForegroundColor Red
        
        if ($_.Exception.Message -like "*Access*denied*" -or $_.Exception.Message -like "*UnauthorizedAccessException*") {
            Write-Host "     TIP: Run PowerShell as Administrator to delete SYSTEM credentials" -ForegroundColor Yellow
        }
        return $false
    }
}

function Show-DeletionMenu {
    param(
        [Parameter(Mandatory)]
        [array]$CredentialResults
    )
    
    # Filter only found credentials - use ArrayList for proper hashtable handling
    $foundCreds = New-Object System.Collections.ArrayList
    
    foreach ($result in $CredentialResults) {
        if ($null -ne $result -and $result['Found'] -eq $true) {
            [void]$foundCreds.Add($result)
        }
    }
    
    if ($foundCreds.Count -eq 0) {
        Write-Host "No credential files to delete." -ForegroundColor Gray
        return
    }
    
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host " CREDENTIAL DELETION MENU" -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Found $($foundCreds.Count) credential file(s):" -ForegroundColor White
    Write-Host ""
    
    # Display found credentials with numbers
    for ($i = 0; $i -lt $foundCreds.Count; $i++) {
        $num = $i + 1
        $cred = $foundCreds[$i]
        
        Write-Host "  [$num] $($cred['AccountName'])" -ForegroundColor Cyan
        Write-Host "      $($cred['Path'])" -ForegroundColor Gray
        Write-Host ""
    }
    
    Write-Host "  [A] Delete ALL credential files" -ForegroundColor Red
    Write-Host "  [0] Exit WITHOUT deleting anything" -ForegroundColor Green
    Write-Host ""
    
    # Get user choice
    do {
        Write-Host "Select an option: " -NoNewline -ForegroundColor Yellow
        $choice = Read-Host
        $choice = $choice.ToUpper().Trim()
        
        $validChoice = $false
        
        # Check if it's a number
        if ($choice -match '^\d+$') {
            $index = [int]$choice - 1
            if ($index -ge 0 -and $index -lt $foundCreds.Count) {
                $validChoice = $true
                $selectedCred = $foundCreds[$index]
                Write-Host ""
                Write-Host "You selected: $($selectedCred['AccountName'])" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "WARNING: This will permanently delete the credential file!" -ForegroundColor Red
                Write-Host "Type 'YES' to confirm deletion, or anything else to cancel: " -NoNewline
                $confirm = Read-Host
                
                if ($confirm -eq 'YES') {
                    $deleted = Remove-CredentialFile -CredInfo $selectedCred
                    if ($deleted) {
                        Write-Host ""
                        Write-Host "Credential file deleted." -ForegroundColor Green
                    }
                } else {
                    Write-Host ""
                    Write-Host "Deletion cancelled." -ForegroundColor Yellow
                }
                
                Write-Host ""
                Write-Host "Press Enter to continue..." -ForegroundColor Gray
                $null = Read-Host
                
                # Re-check credentials and show menu again
                Write-Host ""
                Write-Host "Re-checking credential status..." -ForegroundColor Cyan
                Write-Host ""
                
                # Re-verify current user
                $currentUserPath = Split-Path $PROFILE
                $currentUserResult = Test-CredentialFile -BasePath $currentUserPath -AccountName "CURRENT USER ($env:USERNAME)" -AccountType "CurrentUser"
                
                # Re-verify SYSTEM (standard)
                $systemPath = Get-SystemProfilePath
                $systemResult = Test-CredentialFile -BasePath $systemPath -AccountName "SYSTEM ACCOUNT (Standard)" -AccountType "System"
                
                # Re-verify SYSTEM (PsExec) if applicable
                $systemPsExecResult = $null
                $psexecInfo = Test-PsExecAvailable
                if ($psexecInfo.Available) {
                    $systemPsExecPath = Get-SystemPsExecProfilePath
                    $systemPsExecResult = Test-CredentialFile -BasePath $systemPsExecPath -AccountName "SYSTEM ACCOUNT (PsExec)" -AccountType "SystemPsExec"
                }
                
                # Rebuild credential results array
                $updatedCredentialResults = @()
                $updatedCredentialResults += $currentUserResult
                $updatedCredentialResults += $systemResult
                if ($null -ne $systemPsExecResult) {
                    $updatedCredentialResults += $systemPsExecResult
                }
                
                # Show menu again with updated results
                Show-DeletionMenu -CredentialResults $updatedCredentialResults
                return
            }
        }
        
        # Check for A (All)
        if ($choice -eq 'A') {
            $validChoice = $true
            Write-Host ""
            Write-Host "WARNING: You are about to delete ALL $($foundCreds.Count) credential file(s)!" -ForegroundColor Red
            Write-Host ""
            foreach ($cred in $foundCreds) {
                Write-Host "  - $($cred['AccountName'])" -ForegroundColor Yellow
            }
            Write-Host ""
            Write-Host "Type 'DELETE ALL' to confirm, or anything else to cancel: " -NoNewline
            $confirm = Read-Host
            
            if ($confirm -eq 'DELETE ALL') {
                Write-Host ""
                $deletedCount = 0
                foreach ($cred in $foundCreds) {
                    $deleted = Remove-CredentialFile -CredInfo $cred
                    if ($deleted) {
                        $deletedCount++
                    }
                }
                Write-Host ""
                Write-Host "Summary: Deleted $deletedCount of $($foundCreds.Count) credential file(s)" -ForegroundColor Green
            } else {
                Write-Host ""
                Write-Host "Deletion cancelled." -ForegroundColor Yellow
            }
            
            Write-Host ""
            return
        }
        
        # Check for 0 (Exit)
        if ($choice -eq '0') {
            $validChoice = $true
            Write-Host ""
            Write-Host "Exiting without deleting any credentials..." -ForegroundColor Green
            Write-Host ""
            return
        }
        
        if (-not $validChoice) {
            Write-Host "Invalid choice. Please select a number (1-$($foundCreds.Count)), A, or 0." -ForegroundColor Red
        }
        
    } while (-not $validChoice)
}

#endregion

#region --- MAIN EXECUTION -----------------------------------------------------

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " RUBRIK SERVICE ACCOUNT STATUS CHECK" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# Check if RubrikSecurityCloud module is installed
Write-Host "Checking RubrikSecurityCloud module..." -ForegroundColor Yellow
$module = Get-Module -ListAvailable -Name RubrikSecurityCloud

if ($module) {
    Write-Host " [+] Module installed: Version $($module.Version)" -ForegroundColor Green
} else {
    Write-Host " [-] Module NOT installed" -ForegroundColor Red
    Write-Host ""
    Write-Host "To install: Install-Module -Name RubrikSecurityCloud -Scope CurrentUser" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan

# Check Current User credentials
# Ensure we have an absolute path
if ([string]::IsNullOrWhiteSpace($PROFILE)) {
    $currentUserPath = Join-Path $HOME "Documents\WindowsPowerShell"
} else {
    $currentUserPath = Split-Path $PROFILE
    # Ensure absolute path
    if (-not [System.IO.Path]::IsPathRooted($currentUserPath)) {
        $currentUserPath = Join-Path $HOME "Documents\WindowsPowerShell"
    }
}
$currentUserResult = Test-CredentialFile -BasePath $currentUserPath -AccountName "CURRENT USER ($env:USERNAME)" -AccountType "CurrentUser"

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan

# Check SYSTEM credentials (standard location)
$systemPath = Get-SystemProfilePath
$systemResult = Test-CredentialFile -BasePath $systemPath -AccountName "SYSTEM ACCOUNT (Standard)" -AccountType "System"

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan

# Check for PsExec and SYSTEM credentials via PsExec location
$psexecInfo = Test-PsExecAvailable
$systemPsExecResult = $null

Write-Host ""
Write-Host "Checking for PsExec availability..." -ForegroundColor Yellow

if ($psexecInfo.Available) {
    Write-Host " [+] PsExec found: $($psexecInfo.Path) ($($psexecInfo.Version))" -ForegroundColor Green
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Cyan
    
    # Check SYSTEM credentials in PsExec location
    $systemPsExecPath = Get-SystemPsExecProfilePath
    $systemPsExecResult = Test-CredentialFile -BasePath $systemPsExecPath -AccountName "SYSTEM ACCOUNT (PsExec)" -AccountType "SystemPsExec"
    
} else {
    Write-Host " [-] PsExec NOT found in script directory" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Note: If you use PsExec to run scripts as SYSTEM, credentials may be stored" -ForegroundColor Gray
    Write-Host "      in a different location (C:\Windows\SysWOW64\config\systemprofile\...)" -ForegroundColor Gray
    Write-Host "      Place PsExec.exe in the script directory to check this location." -ForegroundColor Gray
}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# Collect all results in explicit array
$credentialResults = @()
$credentialResults += $currentUserResult
$credentialResults += $systemResult
if ($null -ne $systemPsExecResult) {
    $credentialResults += $systemPsExecResult
}

# Summary
Write-Host "SUMMARY:" -ForegroundColor Yellow
Write-Host ""

$foundCount = 0

foreach ($result in $credentialResults) {
    if ($result.Found) {
        $foundCount++
        Write-Host " [+] $($result.AccountName): CONFIGURED" -ForegroundColor Green
    } else {
        Write-Host " [-] $($result.AccountName): NOT CONFIGURED" -ForegroundColor Red
    }
}

Write-Host ""

# Add explanation for SYSTEM account types
if ($psexecInfo.Available) {
    Write-Host "Understanding SYSTEM Account Locations:" -ForegroundColor Cyan
    Write-Host "  - SYSTEM (Standard):  Used by regular scheduled tasks" -ForegroundColor White
    Write-Host "  - SYSTEM (PsExec):    Used when running scripts via PsExec as SYSTEM" -ForegroundColor White
    Write-Host ""
    Write-Host "  These are DIFFERENT locations. You may need credentials in one or both," -ForegroundColor Gray
    Write-Host "  depending on how you run your scripts." -ForegroundColor Gray
    Write-Host ""
}

# Provide context based on findings
if ($foundCount -eq 0) {
    Write-Host "Status: No Service Accounts are configured" -ForegroundColor Red
    Write-Host ""
    
    # Try to find credentials in unexpected locations
    Write-Host "==========================================================" -ForegroundColor Cyan
    $allFoundFiles = Find-AllCredentialFiles
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ($allFoundFiles.Count -eq 0) {
        Write-Host "What this means:" -ForegroundColor Yellow
        Write-Host "  - You MUST provide a JSON file for first-time setup" -ForegroundColor White
        Write-Host "  - Place the Service Account JSON file in the script directory" -ForegroundColor White
        Write-Host "  - Run your Rubrik script to configure" -ForegroundColor White
        Write-Host ""
        
        Write-Host "Steps to configure:" -ForegroundColor Yellow
        Write-Host "  1. Download Service Account JSON from Rubrik Security Cloud" -ForegroundColor White
        Write-Host "     - Login to your Rubrik Security Cloud console" -ForegroundColor Gray
        Write-Host "     - Go to: Settings -> Service Accounts -> Create/Download" -ForegroundColor Gray
        Write-Host ""
    } else {
        Write-Host "IMPORTANT: Credential files were found but in unexpected locations!" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "This usually means:" -ForegroundColor Cyan
        Write-Host "  - The script is looking in the wrong place" -ForegroundColor White
        Write-Host "  - OR the files were created with incorrect permissions" -ForegroundColor White
        Write-Host ""
        Write-Host "The files shown above should be accessible by your scripts." -ForegroundColor Yellow
        Write-Host "If backups are working, this is normal and can be ignored." -ForegroundColor Green
        Write-Host ""
    }
    Write-Host "  2. Place JSON file in your script directory" -ForegroundColor White
    Write-Host "     Example: service-account-12345.json" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  3. Run your Rubrik snapshot/backup script" -ForegroundColor White
    Write-Host ""
    
} else {
    Write-Host "Status: $foundCount credential file(s) found" -ForegroundColor Green
    Write-Host ""
    
    # Check for Current User
    $currentUserFound = $currentUserResult.Found
    $systemStandardFound = $systemResult.Found
    $systemPsExecFound = if ($systemPsExecResult) { $systemPsExecResult.Found } else { $false }
    
    Write-Host "What this means:" -ForegroundColor Yellow
    
    if ($currentUserFound) {
        Write-Host "  [OK] Manual script execution as current user: WILL WORK" -ForegroundColor Green
    } else {
        Write-Host "  [!!] Manual script execution as current user: WILL FAIL" -ForegroundColor Red
    }
    
    if ($systemStandardFound -or $systemPsExecFound) {
        Write-Host "  [OK] Scheduled tasks running as SYSTEM: WILL WORK" -ForegroundColor Green
    } else {
        Write-Host "  [!!] Scheduled tasks running as SYSTEM: WILL FAIL" -ForegroundColor Red
    }
    
    Write-Host ""
    
    # Recommendations
    if (-not $currentUserFound -and ($systemStandardFound -or $systemPsExecFound)) {
        Write-Host "Recommendation:" -ForegroundColor Yellow
        Write-Host "  Configure current user credentials for manual script execution" -ForegroundColor White
        Write-Host "  Run your Rubrik script as current user with JSON file" -ForegroundColor White
        Write-Host ""
    }
    
    if ($currentUserFound -and -not $systemStandardFound -and -not $systemPsExecFound) {
        Write-Host "Recommendation:" -ForegroundColor Yellow
        Write-Host "  Configure SYSTEM credentials for scheduled tasks" -ForegroundColor White
        Write-Host "  Use PsExec to run script as SYSTEM with JSON file" -ForegroundColor White
        Write-Host ""
    }
    
    if ($systemStandardFound -and $systemPsExecFound) {
        Write-Host "Note:" -ForegroundColor Yellow
        Write-Host "  You have SYSTEM credentials in both standard and PsExec locations" -ForegroundColor White
        Write-Host "  This is usually not necessary - consider keeping only one" -ForegroundColor White
        Write-Host ""
    }
}

# Interactive deletion menu
Show-DeletionMenu -CredentialResults $credentialResults

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

exit 0

#endregion
