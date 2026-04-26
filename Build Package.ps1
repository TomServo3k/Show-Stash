# Build-ShowStashPackage.ps1
# Creates a clean sideload zip for Roku development from runtime files only.
# Output: Backups\Show Stash M.m.zip where M=major_version and m=minor_version.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

$ManifestPath = Join-Path $Root 'manifest'
$Components   = Join-Path $Root 'components'
$Images       = Join-Path $Root 'images'
$Source       = Join-Path $Root 'source'
$BackupsDir   = Join-Path $Root 'Backups'

function Get-VersionFromManifest {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Manifest file not found at: $Path"
    }

    $raw = Get-Content -LiteralPath $Path -Raw
    $major = $null
    $minor = $null

    foreach ($line in ($raw -split "`r?`n")) {
        if ($null -eq $major -and $line -match '^\s*major_version\s*[:=]\s*(\d+)\s*$') { $major = [int]$Matches[1] }
        if ($null -eq $minor -and $line -match '^\s*minor_version\s*[:=]\s*(\d+)\s*$') { $minor = [int]$Matches[1] }
    }

    if ($null -eq $major -or $null -eq $minor) {
        throw "Could not find major_version and minor_version in manifest."
    }

    return @{ Major = $major; Minor = $minor }
}

function Get-ManifestAssetPaths {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $raw = Get-Content -LiteralPath $Path
    $assetKeys = @(
        'mm_icon_focus_fhd',
        'mm_icon_focus_hd',
        'mm_icon_focus_sd',
        'mm_icon_side_hd',
        'mm_icon_side_sd',
        'splash_screen_fhd',
        'splash_screen_hd',
        'splash_screen_sd'
    )

    foreach ($line in $raw) {
        foreach ($key in $assetKeys) {
            if ($line -match "^\s*$key\s*=\s*pkg:/(.+?)\s*$") {
                Join-Path $Root $Matches[1]
            }
        }
    }
}

$requiredPaths = @($ManifestPath, $Components, $Images, $Source)
foreach ($path in $requiredPaths) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required file/folder missing: $path"
    }
}

foreach ($assetPath in (Get-ManifestAssetPaths -Path $ManifestPath)) {
    if (-not (Test-Path -LiteralPath $assetPath)) {
        throw "Manifest asset missing: $assetPath"
    }
}

$version = Get-VersionFromManifest -Path $ManifestPath
$zipName = "Show Stash $($version.Major).$($version.Minor).zip"

if (-not (Test-Path -LiteralPath $BackupsDir)) {
    New-Item -ItemType Directory -Path $BackupsDir | Out-Null
}

$zipPath = Join-Path $BackupsDir $zipName
if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}

$sevenZip = "C:\Program Files\7-Zip\7z.exe"
if (-not (Test-Path -LiteralPath $sevenZip)) {
    $sevenZip = "7z.exe"
}

$itemsToZip = @($ManifestPath, $Components, $Images, $Source)

$arguments = @('a', '-tzip', '-y', $zipPath) + $itemsToZip

& $sevenZip @arguments
if ($LASTEXITCODE -ne 0) {
    throw "7-Zip failed with exit code $LASTEXITCODE."
}

Write-Host "Created: $zipPath"
