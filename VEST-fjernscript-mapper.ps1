# -----------------------------
# DEL 4 – FJERNINGSSCRIPT
# -----------------------------
$basePath = "C:\Data"
$groupNames = @("employees", "external", "IT")

foreach ($group in $groupNames) {
    $folderPath = Join-Path -Path $basePath -ChildPath $group
    $shareName = "${group}$"

    # Fjern SMB-share
    if (Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue) {
        try {
            Remove-SmbShare -Name $shareName -Force
            Write-Host "🧹 Removed SMB share: $shareName"
        } catch {
            Write-Host "❌ Could not remove share: $shareName - $_"
        }
    }

    # Slett mappen
    if (Test-Path -Path $folderPath) {
        try {
            Remove-Item -Path $folderPath -Recurse -Force
            Write-Host "🗑️ Removed folder: $folderPath"
        } catch {
            Write-Host "❌ Could not remove folder: $folderPath - $_"
        }
    }
}

# Slett base mappe hvis tom
if ((Test-Path -Path $basePath) -and ((Get-ChildItem $basePath | Measure-Object).Count -eq 0)) {
    Remove-Item $basePath -Force
    Write-Host "🧼 Removed base folder: $basePath"
}
