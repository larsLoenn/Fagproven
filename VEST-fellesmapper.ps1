# -----------------------------
# DEL 1 – OPPRETT MAPPER OG DEL DEM
# -----------------------------
$basePath = "C:\Data"  # Skjult hovedmappe
$adminGroup = "SJOBRIS\Domain Admins"
$groupNames = @("employees", "external","oekonomi", "IT")

# Sørg for at base-mappe finnes
if (-not (Test-Path -Path $basePath)) {
    New-Item -Path $basePath -ItemType Directory
    Write-Host "📁 Created base path: $basePath"
}

# Opprett mapper og SMB-share for hver gruppe
foreach ($group in $groupNames) {
    $folderPath = Join-Path -Path $basePath -ChildPath $group
    $shareName = "${group}$"

    if (-not (Test-Path -Path $folderPath)) {
        New-Item -Path $folderPath -ItemType Directory
        Write-Host "📁 Created folder: $folderPath"
    }

    if (-not (Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue)) {
        New-SmbShare -Name $shareName -Path $folderPath -FullAccess "SJOBRIS\Domain Admins" -ChangeAccess $group
        Write-Host "📡 Created SMB share: $shareName"
    } else {
        Write-Host "⚠️ Share already exists: $shareName"
    }
}


foreach ($group in $groupNames) {
    $folderPath = Join-Path -Path $basePath -ChildPath $group

    if (Test-Path -Path $folderPath) {
        $acl = Get-Acl $folderPath

        # Slå av arv og fjern eksisterende tillatelser
        $acl.SetAccessRuleProtection($true, $false)
        $acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) }

        # Legg til nødvendige systemtillatelser
        $systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $builtinAdminsRule = New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")

        # Gruppe- og adminregler
        $groupRule = New-Object System.Security.AccessControl.FileSystemAccessRule($group, "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")
        $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule($adminGroup, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        
        #Creator Owner
        $creatorRule = New-Object System.Security.AccessControl.FileSystemAccessRule("CREATOR OWNER", "FullControl", "ContainerInherit,ObjectInherit", "InheritOnly", "Allow")

        # Legg til regler
        $acl.AddAccessRule($systemRule)
        $acl.AddAccessRule($builtinAdminsRule)
        $acl.AddAccessRule($groupRule)
        $acl.AddAccessRule($adminRule)
        $acl.AddAccessRule($creatorRule)

        # Lagre ACL
        Set-Acl -Path $folderPath -AclObject $acl
        Write-Host "🔐 Permissions set for: $group"
    } else {
        Write-Host "❌ Folder not found: $folderPath"
    }
}
