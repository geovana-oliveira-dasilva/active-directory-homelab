<#
.SYNOPSIS
    Creates Active Directory user accounts in bulk from a list of names.

.DESCRIPTION
    Lab script for the Active Directory Home Lab.
    Reads "First Last" names from names.txt, creates the OU "_USERS" and creates
    one enabled user per name. Username pattern: first letter of first name + last name
    (e.g. "Anna Birk" -> "abirk").

    The initial password is requested at run time and is never stored in the script.

.NOTES
    For lab use only. Run on the Domain Controller with the ActiveDirectory module.
#>

# ----- Adjustable variables ----- #
$USER_FIRST_LAST_LIST = Get-Content .\names.txt
# -------------------------------- #

# Initial password is requested at run time (not stored in plain text)
$password = Read-Host -Prompt "Initial password for the users" -AsSecureString

New-ADOrganizationalUnit -Name _USERS -ProtectedFromAccidentalDeletion $false

foreach ($n in $USER_FIRST_LAST_LIST) {
    $first    = $n.Split(" ")[0].ToLower()
    $last     = $n.Split(" ")[1].ToLower()
    $username = "$($first.Substring(0,1))$($last)".ToLower()
    Write-Host "Creating user: $($username)" -BackgroundColor Black -ForegroundColor Cyan

    New-ADUser -AccountPassword $password `
               -GivenName $first `
               -Surname $last `
               -DisplayName $username `
               -Name $username `
               -EmployeeID $username `
               -PasswordNeverExpires $true `
               -Path "ou=_USERS,$(([ADSI]`"").distinguishedName)" `
               -Enabled $true
}
