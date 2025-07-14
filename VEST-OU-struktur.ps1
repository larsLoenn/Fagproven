# Definerer $RootOU
$rootOU = "OU=Vestkommune,DC=vestkommune,DC=ad"

# Lager Root OU / Vestkommune
New-ADOrganizationalUnit -Name "vestkommune" -Path "DC=vestkommune,DC=ad"

# Lager under-OU-er under Root OU / vestkommune
New-ADOrganizationalUnit -Name "Users" -Path $rootOU
New-ADOrganizationalUnit -Name "Computers" -Path $rootOU
New-ADOrganizationalUnit -Name "Groups" -Path $rootOU

# -----------------------------
# Lager standardgrupper
# -----------------------------
$groupsOU = "OU=Groups,$rootOU"     # peker på vestkommune\Groups

# Eksterne brukere
New-ADGroup `
    -Name "external" `
    -SamAccountName "external" `
    -GroupCategory Security `
    -GroupScope Global `
    -Path $groupsOU `
    -Description "Gruppe for eksterne brukere"

# Ansatte
New-ADGroup `
    -Name "employees" `
    -SamAccountName "employees" `
    -GroupCategory Security `
    -GroupScope Global `
    -Path $groupsOU `
    -Description "Gruppe for alle ansatte"

    New-ADGroup `
    -Name "It" `
    -SamAccountName "IT" `
    -GroupCategory Security `
    -GroupScope Global `
    -Path $groupsOU `
    -Description "Gruppe for alle pae ITavd"

New-ADOrganizationalUnit -Name "Servers" -Path $rootOU
New-ADOrganizationalUnit -Name "Printers" -Path $rootOU

# Redirecter nye datamaskiner til Computers OU
redircmp "OU=Computers,$rootOU"

# Lager under-OU-er for Users
New-ADOrganizationalUnit -Name "Ansatte" -Path "OU=Users,$rootOU"
New-ADOrganizationalUnit -Name "ITavd" -Path "OU=Users,$rootOU"
New-ADOrganizationalUnit -Name "eksterne" -Path "OU=Users,$rootOU"

# Definerer Admin OU og under-OUer
$adminOU = "OU=Admin,$rootOU"
New-ADOrganizationalUnit -Name "Admin" -Path $rootOU
New-ADOrganizationalUnit -Name "users" -Path $adminOU
New-ADOrganizationalUnit -Name "Groups" -Path $adminOU

# -----------------------------
# Lager ÉN testbruker i hver relevant sub-OU
# -----------------------------

# Standard passord
$defaultPassword = ConvertTo-SecureString "UiB2025!" -AsPlainText -Force

# Liste over sub-OUs hvor det skal lages én testbruker
$userOUs = @(
    "OU=Ansatte,OU=Users,$rootOU",
    "OU=ITavd,OU=Users,$rootOU",
    "OU=eksterne,OU=Users,$rootOU",
    "OU=users,$adminOU"
)

# Oppretter én testbruker i hver OU
foreach ($ou in $userOUs) {
    if ($ou -match "OU=([^,]+),") {
        $ouName = $matches[1]
        $username = "${ouName}Test"
        $userPrincipalName = "$username@vestkommune.site"

        if (-not (Get-ADUser -Filter { SamAccountName -eq $username } -ErrorAction SilentlyContinue)) {
            New-ADUser `
                -Name $username `
                -GivenName $username `
                -Surname "User" `
                -SamAccountName $username `
                -UserPrincipalName $userPrincipalName `
                -AccountPassword $defaultPassword `
                -Enabled $true `
                -Path $ou `
                -PasswordNeverExpires $true `
                -ChangePasswordAtLogon $false
        }
    }
    # -----------------------------
# Legger testbrukere i passende grupper basert på OU
# -----------------------------
$groupAssignments = @{
    "AnsatteTest"  = "employees"
    "ITavdTest"    = "IT"
    "eksterneTest" = "external"
}

foreach ($username in $groupAssignments.Keys) {
    $group = $groupAssignments[$username]

    try {
        $userExists = Get-ADUser -Identity $username -ErrorAction Stop
        $groupExists = Get-ADGroup -Identity $group -ErrorAction Stop

        Add-ADGroupMember -Identity $group -Members $username
        Write-Host "✅ La til ${username} i gruppen ${group}"
    } catch {
        Write-Host "❌ Feil ved å legge til ${username} i ${group}: $($_.Exception.Message)"
    }
}
