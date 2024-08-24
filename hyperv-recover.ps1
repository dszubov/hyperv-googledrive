# Set UTF-8 encoding for console output
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Paths to rclone.exe and 7z.exe
$rclonePath = $env:RCLONE_PATH
$sevenZipPath = $env:SEVEN_ZIP_PATH

# Paths for cloud storage and local restore directory
$cloudPath = $env:CLOUD_PATH
$restorePath = $env:BACKUP_PATH
$finalPath = "C:\Hyper-V\$($selectedVM.Name)"

# Fetch the list of available backups from the cloud
Write-Host "Fetching the list of available backups from cloud storage..."
$backups = & $rclonePath lsf $cloudPath --format "p"
Write-Host "Backups found: $($backups.Count)"

# Extract VM names from backup files
$vmNames = $backups | ForEach-Object {
    if ($_ -match '^(.*?)-(\d{2})_(\d{2})_(\d{4})_(\d{2})_(\d{2})_(\d{2})\.7z$') {
        [PSCustomObject]@{
            Name = $matches[1]
            Date = Get-Date -Year $matches[4] -Month $matches[2] -Day $matches[3] -Hour $matches[5] -Minute $matches[6] -Second $matches[7]
            Backup = $_
        }
    }
}

# Group backups by VM name and prompt the user to select a VM
$groupedVMs = $vmNames | Group-Object -Property Name
$i = 0
$groupedVMs | ForEach-Object {
    Write-Host $i": $($_.Name)"
    $i++
}

$vmIndex = Read-Host "Enter the index of the VM to view backups"
$selectedVMGroup = $groupedVMs[$vmIndex]

if (-not $selectedVMGroup) {
    Write-Host "Invalid selection. Exiting."
    exit
}

# Display the backups for the selected VM
$i = 0
$selectedVMGroup.Group | Sort-Object Date -Descending | ForEach-Object {
    Write-Host $i": $($_.Date)"
    $i++
}

$backupIndex = Read-Host "Enter the index of the backup to restore"
$selectedBackup = $selectedVMGroup.Group[$backupIndex]

if (-not $selectedBackup) {
    Write-Host "Restoration canceled."
    exit
}

# Cloud archive path
$backupFile = "$cloudPath$($selectedVM.Backup)"
$localArchivePath = "$restorePath\$($selectedVM.Backup)"

# Download the selected backup
$backupFile = "$cloudPath$($selectedBackup.Backup)"
$localArchivePath = Join-Path $restorePath $selectedBackup.Backup

Write-Host "Downloading backup $($selectedBackup.Backup)..."
& $rclonePath copy "$backupFile" "$restorePath"

# Extract the downloaded archive directly to the restore folder
$extractionPath = $restorePath
$cmdCommand = "`"$sevenZipPath`" x `"$localArchivePath`" -o`"$extractionPath`" -y >nul 2>&1"
# Write-Host $cmdCommand  # For debugging
cmd.exe /c $cmdCommand

# Locate the configuration file for the VM
$vmConfigPath = Get-ChildItem -Path $extractionPath -Recurse | Where-Object { $_.Extension -eq ".vmcx" -or $_.Extension -eq ".xml" } | Select-Object -First 1

if ($vmConfigPath) {
    # Import the virtual machine
    Write-Host "Importing virtual machine $($selectedVM.Name)..."
    $vm = Import-VM -Path $vmConfigPath.FullName

    # Use Storage Migration to move the VM storage to the final path
    $finalPath = "C:\hyper-v\$($selectedVMGroup.Name)"
    Write-Host "Migrating storage to $finalPath..."
    Move-VMStorage -VM $vm -DestinationStoragePath $finalPath

    Write-Host "Restoration and storage migration completed."
} else {
    Write-Host "Error: No valid VM configuration file found for import."
}

# Cleanup
Remove-Item $localArchivePath -Force  # Remove downloaded archive
Remove-Item -Path "$restorePath\$($selectedVMGroup.Name)" -Recurse -Force  # Remove extracted folder

Write-Host "Cleanup completed."