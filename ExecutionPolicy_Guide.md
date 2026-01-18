# PowerShell Execution Policy - Complete Guide

Documentation for properly configuring PowerShell Execution Policies to run Rubrik scripts.

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)

---

## 📋 Table of Contents

- [Common Problem](#common-problem)
- [Quick Solutions](#quick-solutions)
- [Permanent Solution (Recommended)](#permanent-solution-recommended)
- [Execution Policy Explained](#execution-policy-explained)
- [Verification and Diagnostics](#verification-and-diagnostics)
- [Usage Scenarios](#usage-scenarios)
- [Security](#security)
- [Troubleshooting](#troubleshooting)

---

## ⚠️ Common Problem

### Typical Error

```
.\New-RscFileSnapshotScheduler.ps1 : File C:\Scripts\New-RscFileSnapshotScheduler.ps1 cannot be loaded.
The file C:\Scripts\New-RscFileSnapshotScheduler.ps1 is not digitally signed.
You cannot run this script on the current system.
For more information about running scripts and setting execution policy, see about_Execution_Policies at
https://go.microsoft.com/fwlink/?LinkID=135170.
```

### Cause

Windows blocks execution of unsigned PowerShell scripts for security reasons.

---

## 🔧 Quick Solutions

### Solution 1: Unblock Downloaded File (RECOMMENDED)

```powershell
# Unblock a single file
Unblock-File -Path "C:\Scripts\New-RscFileSnapshotScheduler.ps1"

# Unblock all scripts in the folder
Unblock-File -Path "C:\Scripts\*.ps1"

# Verify the file has been unblocked
Get-Item "C:\Scripts\New-RscFileSnapshotScheduler.ps1" | Select-Object -ExpandProperty FullName, Attributes
```

**When to use:**
- ✅ You downloaded the script from the Internet
- ✅ You want a quick and secure solution
- ✅ You don't want to modify system policies

**Advantages:**
- Doesn't modify system configuration
- Secure: only unblock files you trust
- Permanent: once unblocked, the file stays unblocked

---

### Solution 2: Temporary Session Bypass

```powershell
# Bypass only for this PowerShell session (closes at the end)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Then run the script
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold"
```

**When to use:**
- ✅ You need to run the script just once
- ✅ You don't want permanent changes
- ✅ Quick testing

**Advantages:**
- Temporary: returns to normal when PowerShell closes
- Doesn't require administrator privileges
- Ideal for testing

---

### Solution 3: Inline Bypass (One-Time)

```powershell
# Execute with bypass without modifying the policy
PowerShell.exe -ExecutionPolicy Bypass -File "C:\Scripts\New-RscFileSnapshotScheduler.ps1" -SlaName "Gold"

# With additional parameters
PowerShell.exe -ExecutionPolicy Bypass -File "C:\Scripts\New-RscFileSnapshotScheduler.ps1" -SlaName "Gold" -RecurringIntervalHours 12
```

**When to use:**
- ✅ Command line or batch file execution
- ✅ Scheduled tasks (the scheduling script already does this automatically)
- ✅ CI/CD automation

**Advantages:**
- No system modifications
- Perfect for automation
- Already used in Scheduled Tasks created by the script

---

## 🛡️ Permanent Solution (Recommended)

### Recommended Configuration for Production

```powershell
# STEP 1: Check current policy
Get-ExecutionPolicy -List

# STEP 2: Set RemoteSigned for current user
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force

# STEP 3: Unblock downloaded scripts
Unblock-File -Path "C:\Scripts\*.ps1"

# STEP 4: Verify new configuration
Get-ExecutionPolicy -List
```

### System-Wide Configuration (Requires Administrator)

```powershell
# Open PowerShell as Administrator
# Then run:

Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy RemoteSigned -Force

# Verify
Get-ExecutionPolicy -List
```

**When to use:**
- ✅ Production environment
- ✅ Regular use of Rubrik scripts
- ✅ You want Microsoft's standard configuration

**Advantages:**
- Permanent configuration
- Perfect balance between security and usability
- Recommended by Microsoft for enterprise environments

---

## 📚 Execution Policy Explained

### Policy Levels

| Policy | Description | Local Scripts | Remote Scripts | Security | Typical Use |
|--------|-------------|---------------|----------------|----------|-------------|
| **Restricted** | Blocks all scripts | ❌ Blocked | ❌ Blocked | 🔒 Maximum | Default on Windows client |
| **AllSigned** | Only digitally signed scripts | ⚠️ If signed | ⚠️ If signed | 🔒 Very High | Highly regulated environments |
| **RemoteSigned** | Local scripts OK, remote signed | ✅ Allowed | ⚠️ If signed/unblocked | 🔓 Balanced | **RECOMMENDED** |
| **Unrestricted** | All scripts (with confirmation) | ✅ Allowed | ⚠️ Asks confirmation | 🔓 Medium | Development |
| **Bypass** | No restrictions | ✅ Allowed | ✅ Allowed | ⚠️ Low | Testing/Automation |
| **Undefined** | No policy set | - | - | - | Inherits from higher scope |

### Policy Scopes

PowerShell manages policies at different levels (from broadest to most specific):

```
MachinePolicy    (Group Policy - domain)
    ↓
UserPolicy       (Group Policy - user)
    ↓
Process          (Current session only)
    ↓
CurrentUser      (Current user - registry)
    ↓
LocalMachine     (All users - registry)
```

**Precedence order:** MachinePolicy > UserPolicy > Process > CurrentUser > LocalMachine

---

## 🔍 Verification and Diagnostics

### Check Current Policy

```powershell
# Effective policy (the one that matters)
Get-ExecutionPolicy

# All policies for each scope
Get-ExecutionPolicy -List

# Example output:
#         Scope ExecutionPolicy
#         ----- ---------------
# MachinePolicy       Undefined
#    UserPolicy       Undefined
#       Process       Undefined
#   CurrentUser    RemoteSigned
#  LocalMachine    RemoteSigned
```

### Check if a File is Blocked

```powershell
# Check file's security zone
Get-Item "C:\Scripts\New-RscFileSnapshotScheduler.ps1" -Stream Zone.Identifier -ErrorAction SilentlyContinue

# If the command returns something, the file is marked as "from Internet"
# If it returns nothing, the file is not blocked
```

### Test Execution

```powershell
# Test 1: Check syntax without executing
powershell.exe -NoProfile -NoLogo -NonInteractive -File "C:\Scripts\New-RscFileSnapshotScheduler.ps1" -Help

# Test 2: Execute with bypass for testing
PowerShell.exe -ExecutionPolicy Bypass -File "C:\Scripts\New-RscFileSnapshotScheduler.ps1" -Help

# Test 3: Check specific errors
$Error[0] | Format-List * -Force
```

---

## 💼 Usage Scenarios

### Scenario 1: Developer Workstation

```powershell
# Flexible configuration for development
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force

# Unblock project scripts
Unblock-File -Path "C:\Scripts\*.ps1"
```

**Characteristics:**
- Modifies only for current user
- Local scripts executable
- Downloaded scripts require manual unblocking

---

### Scenario 2: Production Server

```powershell
# Open PowerShell as Administrator
Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy RemoteSigned -Force

# Unblock automation scripts
Unblock-File -Path "C:\Scripts\*.ps1"
```

**Characteristics:**
- Configuration for all users
- Allows secure automation
- Requires administrative privileges

---

### Scenario 3: GPO-Managed Environment

If the environment is controlled by **Group Policy (GPO)**:

```powershell
# Check if GPO controls the policy
Get-ExecutionPolicy -List

# If MachinePolicy or UserPolicy are not "Undefined",
# contact the domain administrator
```

**Options:**
1. Request GPO modification from administrator
2. Use `-ExecutionPolicy Bypass` inline (cannot be blocked by GPO)
3. Create GPO exception for specific scripts

---

### Scenario 4: Scheduled Task

**Scheduled Tasks created by `New-RscFileSnapshotScheduler.ps1` already use automatic bypass:**

```powershell
# The script creates the task with this action:
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\New-RscFileSnapshot.ps1" -SlaName "Gold"

# No manual configuration required!
```

**No action necessary** - bypass is already integrated.

---

### Scenario 5: Remote Execution (PSRemoting)

```powershell
# Execute script on remote server
Invoke-Command -ComputerName SERVER01 -ScriptBlock {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
    & "C:\Scripts\New-RscFileSnapshot.ps1" -SlaName "Gold"
}

# Or with credentials
$cred = Get-Credential
Invoke-Command -ComputerName SERVER01 -Credential $cred -ScriptBlock {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
    & "C:\Scripts\New-RscFileSnapshot.ps1" -SlaName "Gold"
}
```

---

## 🔐 Security

### Why is RemoteSigned Secure?

**RemoteSigned** offers the best security/usability balance:

1. **Local Scripts (created on the PC):**
   - ✅ Executable without signature
   - ✅ Assumes you control your system

2. **Remote Scripts (downloaded from Internet):**
   - ❌ Blocked by default
   - ✅ Require manual unblocking (`Unblock-File`)
   - ✅ Or digital signature

3. **Protection:**
   - 🛡️ Prevents accidental malware execution
   - 🛡️ Requires explicit action for Internet scripts
   - 🛡️ Maintains full user control

### Best Practices

#### ✅ DO

```powershell
# 1. Use RemoteSigned for production
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

# 2. Unblock only scripts you trust
Unblock-File -Path "C:\Scripts\script.ps1"

# 3. Verify content before unblocking
Get-Content "C:\Downloads\script.ps1" | Select-Object -First 50

# 4. Use Bypass only temporarily
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# 5. Document policy changes
Add-Content -Path "C:\IT\Logs\ExecutionPolicy_Changes.log" -Value "$(Get-Date): Set RemoteSigned for $env:USERNAME"
```

#### ❌ DON'T

```powershell
# ❌ DON'T use Unrestricted permanently
Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy Unrestricted

# ❌ DON'T disable checks with -Force without verification
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine -Force

# ❌ DON'T unblock entire folders without checking
Unblock-File -Path "C:\Downloads\*" -Recurse
```

### Verify Script Integrity

Before unblocking a downloaded script:

```powershell
# 1. Display file hash
Get-FileHash -Path "C:\Downloads\New-RscFileSnapshot.ps1" -Algorithm SHA256

# 2. Compare with official hash (if available on GitHub)

# 3. Check content
notepad.exe "C:\Downloads\New-RscFileSnapshot.ps1"

# 4. Search for suspicious patterns
Select-String -Path "C:\Downloads\New-RscFileSnapshot.ps1" -Pattern "(Invoke-Expression|IEX|DownloadString|WebClient)"
```

---

## 🔧 Troubleshooting

### Problem 1: "Set-ExecutionPolicy: Access Denied"

**Error:**
```
Set-ExecutionPolicy : Access to the registry path is denied.
```

**Cause:** You don't have sufficient privileges.

**Solution:**

```powershell
# Option A: Use CurrentUser (doesn't require admin)
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force

# Option B: Run PowerShell as Administrator
# Right-click PowerShell → "Run as administrator"
Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy RemoteSigned -Force
```

---

### Problem 2: Policy Controlled by GPO

**Error:**
```
Set-ExecutionPolicy : Windows PowerShell updated your execution policy successfully,
but the setting is overridden by a policy defined at a more specific scope.
```

**Cause:** Enterprise Group Policy controls the policy.

**Solution:**

```powershell
# Check who's in control
Get-ExecutionPolicy -List

# If you see MachinePolicy or UserPolicy != Undefined, GPO is in control

# Option 1: Request exception from IT
# Contact domain administrator

# Option 2: Use inline bypass (GPO cannot block it)
PowerShell.exe -ExecutionPolicy Bypass -File "script.ps1"

# Option 3: Use Process scope (temporary, GPO doesn't interfere)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

---

### Problem 3: Script Still Blocked After Unblock

**Cause:** `Zone.Identifier` stream not completely removed.

**Solution:**

```powershell
# Manually remove security stream
Remove-Item -Path "C:\Scripts\New-RscFileSnapshot.ps1" -Stream Zone.Identifier -ErrorAction SilentlyContinue

# Verify removal
Get-Item "C:\Scripts\New-RscFileSnapshot.ps1" -Stream Zone.Identifier -ErrorAction SilentlyContinue

# If it returns nothing, the stream has been removed
```

---

### Problem 4: "Invalid Digital Signature" Error

**Error:**
```
The file cannot be loaded because its signature or hash operation is not allowed.
```

**Cause:** `AllSigned` policy requires valid digital signature.

**Solution:**

```powershell
# Check current policy
Get-ExecutionPolicy

# If it's "AllSigned", change to "RemoteSigned"
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force

# Or sign the script (requires code-signing certificate)
# Set-AuthenticodeSignature -FilePath "script.ps1" -Certificate (Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert)
```

---

### Problem 5: Changes Have No Effect

**Cause:** PowerShell ISE or VS Code uses separate policy.

**Solution:**

```powershell
# Close and reopen PowerShell/ISE/VS Code

# Verify in new session
Get-ExecutionPolicy -List

# If still not working, restart PC
Restart-Computer -Force
```

---

## 📖 Official References

### Microsoft Documentation

- [About Execution Policies](https://docs.microsoft.com/powershell/module/microsoft.powershell.core/about/about_execution_policies)
- [Set-ExecutionPolicy](https://docs.microsoft.com/powershell/module/microsoft.powershell.security/set-executionpolicy)
- [Get-ExecutionPolicy](https://docs.microsoft.com/powershell/module/microsoft.powershell.security/get-executionpolicy)
- [Unblock-File](https://docs.microsoft.com/powershell/module/microsoft.powershell.utility/unblock-file)

### Direct Links

- Execution Policies: https://go.microsoft.com/fwlink/?LinkID=135170
- PowerShell Security: https://docs.microsoft.com/powershell/scripting/security/

---

## 📝 Quick Command Summary

### Recommended Initial Setup

```powershell
# 1. Set permanent policy
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force

# 2. Unblock Rubrik scripts
Set-Location "C:\Scripts"
Unblock-File -Path "*.ps1"

# 3. Verify configuration
Get-ExecutionPolicy -List

# 4. Test execution
.\New-RscFileSnapshotScheduler.ps1 -Help
```

### One-Time Execution (No Changes)

```powershell
# Method 1: Unblock + execute
Unblock-File -Path "C:\Scripts\New-RscFileSnapshotScheduler.ps1"
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold"

# Method 2: Inline bypass
PowerShell.exe -ExecutionPolicy Bypass -File "C:\Scripts\New-RscFileSnapshotScheduler.ps1" -SlaName "Gold"
```

### Reset to Default Policy

```powershell
# Remove custom policy (returns to system default)
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Undefined

# Or set Restricted (maximum security)
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Restricted
```

---

## ✅ Pre-Execution Checklist

Before running Rubrik scripts for the first time:

- [ ] PowerShell 5.1+ installed
- [ ] Execution Policy verified (`Get-ExecutionPolicy -List`)
- [ ] RemoteSigned configured (`Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned`)
- [ ] Scripts unblocked (`Unblock-File -Path "*.ps1"`)
- [ ] Help test working (`.\script.ps1 -Help`)
- [ ] Rubrik PowerShell SDK installed (`Get-Module -ListAvailable RubrikSecurityCloud`)

---

## 📞 Support

For Execution Policy issues:

- **Rubrik Scripts Documentation**: Check script READMEs
- **Microsoft Docs**: https://docs.microsoft.com/powershell/
- **GitHub Issues**: https://github.com/mbriotto/New-RscFileSnapshot/issues

---

## 📄 Version

- **1.0** (January 2026): Initial release

---

## 📜 License

This document is part of the **New-RscFileSnapshot** project released under GPL-3.0 license.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

---

## 👤 Author

GitHub: [@mbriotto](https://github.com/mbriotto)  
Repository: https://github.com/mbriotto/New-RscFileSnapshot

---

**🎯 TL;DR (Quick Solution)**

```powershell
# Copy and paste these commands:
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
Set-Location "C:\Scripts"
Unblock-File -Path "*.ps1"
.\New-RscFileSnapshotScheduler.ps1 -SlaName "Gold"
```

**Done! Scripts are now executable.** 🚀
