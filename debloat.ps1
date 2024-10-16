# List of built-in apps to remove
$UninstallPackages = @(
    "AD2F1837.HPJumpStarts",
    "AD2F1837.HPPCHardwareDiagnosticsWindows",
    "AD2F1837.HPPowerManager",
    "AD2F1837.HPPrivacySettings",
    "AD2F1837.HPSupportAssistant",
    "AD2F1837.HPSureShieldAI",
    "AD2F1837.HPSystemInformation",
    "AD2F1837.HPQuickDrop",
    "AD2F1837.HPWorkWell",
    "AD2F1837.myHP",
    "AD2F1837.HPDesktopSupportUtilities",
    "AD2F1837.HPQuickTouch",
    "AD2F1837.HPEasyClean",
    "AD2F1837.HPSystemInformation",
    "Microsoft.Office.OneNote",
    "Microsoft.Office.Access",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.Office.Desktop",
    "ROBLOXCORPORATION.ROBLOX"
)

# List of programs to uninstall
$UninstallPrograms = @(
    "HP Client Security Manager",
    "HP Connection Optimizer",
    "HP Documentation",
    "HP MAC Address Manager",
    "HP Notifications",
    "HP Security Update Service",
    "HP System Default Settings",
    "HP Sure Click",
    "HP Sure Click Security Browser",
    "HP Sure Run",
    "HP Sure Recover",
    "HP Sure Sense",
    "HP Sure Sense Installer",
    "HP Wolf Security",
    "HP Wolf Security Application Support for Sure Sense",
    "HP Wolf Security Application Support for Windows",
    "McAfee AntiVirus",
    "Norton AntiVirus",
    "Microsoft 365"
)

$HPidentifier = "AD2F1837"

$InstalledPackages = Get-AppxPackage -AllUsers | Where-Object {
    ($UninstallPackages -contains $_.Name) -or 
    ($_.Name -match "^$HPidentifier") -or 
    ($_.Name -like "*HP*") -or 
    ($_.Name -like "*McAfee*") -or 
    ($_.Name -like "*Norton*") -or 
    ($_.Name -like "*Microsoft.Office*")
}

$ProvisionedPackages = Get-AppxProvisionedPackage -Online | Where-Object {
    ($UninstallPackages -contains $_.DisplayName) -or 
    ($_.DisplayName -match "^$HPidentifier") -or 
    ($_.DisplayName -like "*HP*") -or 
    ($_.DisplayName -like "*McAfee*") -or 
    ($_.DisplayName -like "*Norton*") -or 
    ($_.DisplayName -like "*Microsoft.Office*")
}

$InstalledPrograms = Get-Package | Where-Object {
    ($UninstallPrograms -contains $_.Name) -or 
    ($_.Name -like "*HP*") -or 
    ($_.Name -like "*McAfee*") -or 
    ($_.Name -like "*Norton*") -or 
    ($_.Name -like "*Microsoft 365*") -or 
    ($_.Name -like "*Office*")
}

# Remove appx provisioned packages - AppxProvisionedPackage
ForEach ($ProvPackage in $ProvisionedPackages) {
    Write-Host -Object "Attempting to remove provisioned package: [$($ProvPackage.DisplayName)]..."
    Try {
        $Null = Remove-AppxProvisionedPackage -PackageName $ProvPackage.PackageName -Online -ErrorAction Stop
        Write-Host -Object "Successfully removed provisioned package: [$($ProvPackage.DisplayName)]"
    }
    Catch {
        Write-Warning -Message "Failed to remove provisioned package: [$($ProvPackage.DisplayName)]"
    }
}

# Remove appx packages - AppxPackage
ForEach ($AppxPackage in $InstalledPackages) {
    Write-Host -Object "Attempting to remove Appx package: [$($AppxPackage.Name)]..."
    Try {
        $Null = Remove-AppxPackage -Package $AppxPackage.PackageFullName -AllUsers -ErrorAction Stop
        Write-Host -Object "Successfully removed Appx package: [$($AppxPackage.Name)]"
    }
    Catch {
        Write-Warning -Message "Failed to remove Appx package: [$($AppxPackage.Name)]"
    }
}

# Remove installed programs
$InstalledPrograms | ForEach-Object {
    Write-Host -Object "Attempting to uninstall: [$($_.Name)]..."
    Try {
        $Null = $_ | Uninstall-Package -AllVersions -Force -ErrorAction Stop
        Write-Host -Object "Successfully uninstalled: [$($_.Name)]"
    }
    Catch {
        Write-Warning -Message "Failed to uninstall: [$($_.Name)]"
    }
}

# Fallback attempt 1 to remove HP Wolf Security using msiexec
Try {
    MsiExec /x "{0E2E04B0-9EDD-11EB-B38C-10604B96B11E}" /qn /norestart
    Write-Host -Object "Fallback to MSI uninstall for HP Wolf Security initiated"
}
Catch {
    Write-Warning -Object "Failed to uninstall HP Wolf Security using MSI - Error message: $($_.Exception.Message)"
}

# Fallback attempt 2 to remove HP Wolf Security using msiexec
Try {
    MsiExec /x "{4DA839F0-72CF-11EC-B247-3863BB3CB5A8}" /qn /norestart
    Write-Host -Object "Fallback to MSI uninstall for HP Wolf 2 Security initiated"
}
Catch {
    Write-Warning -Object "Failed to uninstall HP Wolf Security 2 using MSI - Error message: $($_.Exception.Message)"
}

# Remove taskbar pins
Write-Host "Removing taskbar pins..."
Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -Force -ErrorAction SilentlyContinue

# Remove Start menu advertisement links
Write-Host "Removing Start menu advertisement links..."
$layoutFile = "$env:LOCALAPPDATA\Microsoft\Windows\Shell\LayoutModification.xml"
if (Test-Path $layoutFile) {
    $layoutXml = [xml](Get-Content $layoutFile)
    $layoutXml.LayoutModificationTemplate.DefaultLayoutOverride.StartLayoutCollection.StartLayout.Group | 
    ForEach-Object {
        $_.DesktopApplicationTile | Where-Object { $_.DesktopApplicationLinkPath -like "*:\Program Files*" } | ForEach-Object {
            $_.ParentNode.RemoveChild($_)
        }
    }
    $layoutXml.Save($layoutFile)
}

Write-Host "Script execution completed."