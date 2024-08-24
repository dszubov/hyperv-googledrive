# Importing env
$envPath = Join-Path $PSScriptRoot '.env'
if (Test-Path $envPath) {
    Get-Content $envPath | ForEach-Object {
        if ($_ -match "^\s*([^#\s]+)\s*=\s*(.+?)\s*$") {
            [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2])
        }
    }
}

# Set parameters
$date = Get-Date -Format 'MM_dd_yyyy_HH_mm_ss'

# Retrieve and display a list of virtual machines
$vmList = Get-VM | Select-Object -Property Name
$i = 0
$vmList | ForEach-Object {
    Write-Host $i": $($_.Name)"
    $i++
}

# Prompt the user to select a virtual machine by index
$vmIndex = Read-Host "Enter the index of the virtual machine to back up"
$selectedVM = $vmList[$vmIndex]

if (-not $selectedVM) {
    Write-Host "Invalid selection. Exiting."
    exit
}

# Define backup paths
$backupPath = $env:BACKUP_PATH
$archivePath = "$backupPath\$($selectedVM.Name)-$date.7z" # Path and name of the archive

# Paths to 7-zip and rclone
$sevenZipPath = $env:SEVEN_ZIP_PATH
$rclonePath = $env:RCLONE_PATH

# Path to cloud storage
$cloudPath = $env:CLOUD_PATH

# Create the backup folder if it doesn't exist
if (-not (Test-Path -Path $backupPath)) {
    New-Item -ItemType Directory -Path $backupPath
}

# Check if the VM is running
$vm = Get-VM -Name $selectedVM.Name
$wasRunning = $false

if ($vm.State -eq 'Running') {
    $wasRunning = $true
    Write-Host "Stopping the virtual machine $($selectedVM.Name)..."
    Stop-VM -Name $selectedVM.Name -Force
    Start-Sleep -Seconds 10 # Pause to allow the VM to stop
}

# Export the virtual machine
$exportPath = "$backupPath\$($selectedVM.Name)"
Write-Host "Exporting the virtual machine $($selectedVM.Name) to $exportPath..."
Export-VM -Name $selectedVM.Name -Path $exportPath

# Compress the exported files using 7-Zip
Write-Host "Compressing the backup using 7-Zip..."
Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "$sevenZipPath a -r -t7z -m0=lzma2 -mx=9 -mmt=on -mfb=256 -md=512m -ms=on $archivePath $exportPath\* >nul 2>&1" -NoNewWindow -Wait
$archiveFilename = [System.IO.Path]::GetFileName($archivePath)

# Upload the archive to cloud storage
Write-Host "Uploading the backup to cloud storage..."
& $rclonePath copy $archivePath $cloudPath
$link = rclone link $cloudPath$archiveFilename

# Clean up the export directory
Write-Host "Cleaning up temporary export files..."
Remove-Item -Path $exportPath -Recurse -Force
Remove-Item -Path $archivePath -Recurse -Force

# Restart the virtual machine if it was running
if ($wasRunning) {
    Write-Host "Restarting the virtual machine $($selectedVM.Name)..."
    Start-VM -Name $selectedVM.Name
}

Write-Host "Backup process completed. Link: $link"