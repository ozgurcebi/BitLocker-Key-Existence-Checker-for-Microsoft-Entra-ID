# Simple BitLocker Key Existence Check for Entra ID
# This script checks if BitLocker recovery keys exist in Entra ID

# Required permissions:
# - BitLockerKey.ReadBasic.All (Application permission)
# - Device.Read.All (Application permission)

# Configure Variables
$tenantId = "YOUR_TENANT_ID"
$clientId = "YOUR_CLIENT_ID"
$clientSecret = "YOUR_CLIENT_SECRET"
$outputPath = "C:\Temp\BitlockerKeysReport.csv"

# Install and Import Required PowerShell Modules
$requiredModules = @(
    'Microsoft.Graph.Authentication',
    'Microsoft.Graph.Identity.SignIns',
    'Microsoft.Graph.Identity.DirectoryManagement'
)

foreach ($module in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "$module module is not installed. Installing..." -ForegroundColor Yellow
        try {
            Install-Module -Name $module -Scope CurrentUser -Force -AllowClobber
            Write-Host "$module successfully installed." -ForegroundColor Green
        }
        catch {
            Write-Error "Module installation error: $_"
            exit 1
        }
    }
}

# Import modules
try {
    Import-Module Microsoft.Graph.Authentication -Force
    Import-Module Microsoft.Graph.Identity.SignIns -Force
    Import-Module Microsoft.Graph.Identity.DirectoryManagement -Force
}
catch {
    Write-Error "Module import error: $_"
    exit 1
}

# Check and Create Output Directory
$outputDir = Split-Path -Path $outputPath -Parent
if (-not (Test-Path -Path $outputDir)) {
    Write-Host "Creating output directory: $outputDir" -ForegroundColor Yellow
    try {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    catch {
        Write-Error "Could not create output directory: $_"
        exit 1
    }
}

# Authentication
$secureClientSecret = ConvertTo-SecureString -String $clientSecret -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($clientId, $secureClientSecret)

try {
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
    Connect-MgGraph -ClientSecretCredential $credential -TenantId $tenantId -NoWelcome
    Write-Host "Connection successful." -ForegroundColor Green
}
catch {
    Write-Error "Authentication failed: $_"
    exit 1
}

# Get All BitLocker Keys from Entra ID
Write-Host "Retrieving BitLocker recovery keys from Entra ID..." -ForegroundColor Cyan

try {
    $allBitlockerKeys = Get-MgInformationProtectionBitlockerRecoveryKey -All -Property CreatedDateTime,DeviceId,VolumeType -ErrorAction Stop
    Write-Host "Found $($allBitlockerKeys.Count) BitLocker recovery keys in Entra ID." -ForegroundColor Green
    
    if ($allBitlockerKeys.Count -eq 0) {
        Write-Warning "No BitLocker recovery keys found in Entra ID."
        Write-Host "Possible reasons:" -ForegroundColor Yellow
        Write-Host "1. No devices have BitLocker keys escrowed" -ForegroundColor Yellow
        Write-Host "2. Missing BitLockerKey.ReadBasic.All permission" -ForegroundColor Yellow
        Write-Host "3. BitLocker policy not configured" -ForegroundColor Yellow
        exit 0
    }
}
catch {
    Write-Error "Could not retrieve BitLocker keys: $_"
    Write-Host "Required permissions:" -ForegroundColor Red
    Write-Host "- BitLockerKey.ReadBasic.All" -ForegroundColor White
    Write-Host "- Device.Read.All" -ForegroundColor White
    exit 1
}

# Get Device Information for Each BitLocker Key
Write-Host "Getting device information..." -ForegroundColor Cyan

$bitlockerReport = @()
$processedCount = 0

foreach ($key in $allBitlockerKeys) {
    $processedCount++
    Write-Progress -Activity "Processing keys" -Status "Processed: $processedCount / $($allBitlockerKeys.Count)" -PercentComplete (($processedCount / $allBitlockerKeys.Count) * 100)
    
    # Initialize device information
    $deviceName = "Unknown"
    $deviceOS = "Unknown"
    $deviceTrustType = "Unknown"
    
    try {
        $deviceInfo = Get-MgDevice -DeviceId $key.DeviceId -Property DisplayName,OperatingSystem,TrustType,DeviceId -ErrorAction SilentlyContinue
        
        if ($deviceInfo) {
            $deviceName = $deviceInfo.DisplayName
            $deviceOS = $deviceInfo.OperatingSystem
            $deviceTrustType = $deviceInfo.TrustType
        }
    }
    catch {
        # Device info not available
    }
    
    # Create report object
    $reportObject = [PSCustomObject]@{
        DeviceName          = $deviceName
        DeviceId            = $key.DeviceId
        HasBitLockerKey     = "Yes"
        BitLockerKeyId      = $key.Id
        VolumeType          = if ($key.VolumeType) { $key.VolumeType } else { "Unknown" }
        KeyCreatedDateTime  = if ($key.CreatedDateTime) { $key.CreatedDateTime.ToString("yyyy-MM-dd HH:mm:ss") } else { "Unknown" }
        DeviceOS            = $deviceOS
        DeviceTrustType     = $deviceTrustType
        ProcessedDate       = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    $bitlockerReport += $reportObject
}

Write-Progress -Activity "Processing keys" -Completed

# Export Results and Summary
if ($bitlockerReport.Count -eq 0) {
    Write-Warning "No data to export."
}
else {
    try {
        # Export to CSV
        $bitlockerReport | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8
        Write-Host "Report exported to: $outputPath" -ForegroundColor Green
        
        # Summary statistics
        Write-Host ""
        Write-Host "BITLOCKER KEY SUMMARY" -ForegroundColor Cyan
        Write-Host "Total keys found: $($bitlockerReport.Count)" -ForegroundColor Green
        
        $uniqueDevices = ($bitlockerReport | Select-Object -Unique DeviceId).Count
        Write-Host "Unique devices: $uniqueDevices" -ForegroundColor Green
        
        # Volume types
        $volumeTypes = $bitlockerReport | Group-Object VolumeType | Sort-Object Name
        Write-Host ""
        Write-Host "Volume Types:" -ForegroundColor White
        foreach ($type in $volumeTypes) {
            Write-Host "  $($type.Name): $($type.Count)" -ForegroundColor White
        }
        
        # Device trust types
        $trustTypes = $bitlockerReport | Group-Object DeviceTrustType | Sort-Object Name
        Write-Host ""
        Write-Host "Trust Types:" -ForegroundColor White
        foreach ($trust in $trustTypes) {
            Write-Host "  $($trust.Name): $($trust.Count)" -ForegroundColor White
        }
        
        # Match method statistics
        $matchMethods = $bitlockerReport | Group-Object MatchMethod | Sort-Object Count -Descending
        Write-Host ""
        Write-Host "Device Matching Results:" -ForegroundColor White
        foreach ($method in $matchMethods) {
            $color = if ($method.Name -eq "No Match") { "Red" } else { "Green" }
            Write-Host "  $($method.Name): $($method.Count)" -ForegroundColor $color
        }
        
        # Devices with keys
        $knownDevices = $bitlockerReport | Where-Object { $_.DeviceName -ne "Unknown" } | Select-Object -Unique DeviceName
        if ($knownDevices.Count -gt 0) {
            Write-Host ""
            Write-Host "Devices with BitLocker keys:" -ForegroundColor Green
            foreach ($device in $knownDevices) {
                Write-Host "  $($device.DeviceName)" -ForegroundColor White
            }
        }
        
        $unknownCount = ($bitlockerReport | Where-Object { $_.DeviceName -eq "Unknown" }).Count
        if ($unknownCount -gt 0) {
            Write-Host ""
            Write-Warning "$unknownCount BitLocker keys could not be matched to device names."
            Write-Host "Possible reasons:" -ForegroundColor Yellow
            Write-Host "- Devices were deleted from Entra ID but keys remain" -ForegroundColor Yellow
            Write-Host "- Different device identifier formats" -ForegroundColor Yellow
            Write-Host "- Insufficient permissions to read device directory" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Error "Error creating CSV: $_"
        exit 1
    }
}

# Cleanup
try {
    Write-Host ""
    Write-Host "Disconnecting..." -ForegroundColor Cyan
    Disconnect-MgGraph -ErrorAction SilentlyContinue
    Write-Host "Completed successfully." -ForegroundColor Green
}
catch {
    # Ignore disconnection errors
}