# Windows Debloat, Restriction, and Cleanup Script
# Save this file as "debloat-and-clean.ps1"

# Run this script as administrator

# Function to uninstall apps
function Uninstall-Bloatware {
    $keepApps = @("Python", "Minecraft", "Roblox Studio", "Visual Studio Code", "Minecraft Education")
    
    Get-AppxPackage | Where-Object {$_.Name -notin $keepApps} | Remove-AppxPackage
}

# Function to disable features
function Disable-Features {
    # Disable Cortana
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Type DWord -Value 0

    # Disable telemetry
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0

    # Disable Bing search in Start Menu
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Type DWord -Value 0
}

# Function to edit hosts file
function Edit-HostsFile {
    $hostsFile = "$env:windir\System32\drivers\etc\hosts"
    $websites = @("youtube.com", "poki.com")
    
    foreach ($site in $websites) {
        Add-Content -Path $hostsFile -Value "127.0.0.1 $site"
        Add-Content -Path $hostsFile -Value "127.0.0.1 www.$site"
    }
}

# Function to block Roblox using Windows Firewall
function Block-RobloxFirewall {
    New-NetFirewallRule -DisplayName "Block Roblox" -Direction Outbound -Program "C:\Program Files (x86)\Roblox\Versions\version-*\RobloxPlayerBeta.exe" -Action Block
    New-NetFirewallRule -DisplayName "Block Roblox" -Direction Outbound -Program "C:\Users\*\AppData\Local\Roblox\Versions\version-*\RobloxPlayerBeta.exe" -Action Block
}

# Function to clean up user folders
function Clean-UserFolders {
    $foldersToClean = @(
        [Environment]::GetFolderPath("MyDocuments"),
        [Environment]::GetFolderPath("Desktop"),
        [Environment]::GetFolderPath("MyPictures"),
        [Environment]::GetFolderPath("MyVideos"),
        [Environment]::GetFolderPath("MyMusic")
    )

    foreach ($folder in $foldersToClean) {
        Get-ChildItem -Path $folder -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        Write-Host "Cleaned $folder"
    }
}

# Function to empty the Recycle Bin
function Empty-RecycleBin {
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Host "Emptied the Recycle Bin"
}

# Main execution
Write-Host "Warning: This script will delete files and modify system settings. Ensure you have backups before proceeding."
$confirmation = Read-Host "Do you want to continue? (y/n)"
if ($confirmation -eq 'y') {
    Uninstall-Bloatware
    Disable-Features
    Edit-HostsFile
    Block-RobloxFirewall
    Clean-UserFolders
    Empty-RecycleBin
    Write-Host "Script execution completed. Please restart your computer for changes to take effect."
} else {
    Write-Host "Script execution cancelled."
}

# Pause to keep the window open
Read-Host -Prompt "Press Enter to exit"