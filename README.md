# Hyper-V Backup and Restore Scripts

## Overview
This repository contains two PowerShell scripts for automating the backup and restore processes of Hyper-V virtual machines using `7-Zip` for compression and `rclone` for cloud storage management. The scripts are designed to streamline the backup of VMs and the restoration of these backups from a remote cloud storage location.

## Scripts

### 1. `hyperv-backup.ps1`
This script performs the following actions:
- Lists all available Hyper-V virtual machines and prompts the user to select one by index.
- Compresses the selected virtual machine's files into a `.7z` archive.
- Uploads the archive to a specified cloud storage using `rclone`.

#### Usage
Run the script and follow the prompts to select the virtual machine you want to back up. The script will handle compression and uploading automatically.

### 2. `hyperv-import.ps1`
This script handles the restoration of virtual machines from cloud storage:
- Lists available backups by virtual machine names and allows the user to select a specific VM and backup by index.
- Downloads the selected backup from cloud storage.
- Extracts the backup and restores the virtual machine using Hyper-V's import feature.
- Migrates the storage to a specified location after the restoration is complete.

#### Usage
Run the script and select the VM and specific backup you want to restore. The script will download, extract, and import the virtual machine, followed by storage migration.

## Dependencies
- **7-Zip:** Required for compression and extraction of the VM archives.
- **rclone:** Required for managing the upload and download of backups to/from cloud storage.

## Environment Variables
Both scripts rely on certain environment variables for paths to binaries and storage:
- `RCLONE_PATH`: Path to `rclone.exe`.
- `SEVEN_ZIP_PATH`: Path to `7z.exe`.
- `CLOUD_PATH`: Cloud storage path for backups (for example: googledrive:/hyperv-backups).
- `BACKUP_PATH`: Local path for storing/restoring backups (for example, C:\Hyper-V\Backups).

## Notes
- Ensure `rclone` is configured with your cloud provider before running these scripts. [Instruction](https://rclone.org/drive/) for setup.
- Modify the environment variables as needed to match your system's configuration.
- Adjust the `finalPath` variable in the import script if you need to change the storage location for restored VMs. For example, C:\Hyper-V.

## License
This project is licensed under the MIT License - see the LICENSE file for details.