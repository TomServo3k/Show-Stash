# New-ShowStashBackup.ps1
# Zips: manifest, README.md, components/, images/, source/
# Output: Backups\Show Stash M.m.zip  where M=major_version, m=minor_version

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Work relative to this script's folder (more reliable than current directory)
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

$ManifestPath = Join-Path $Root 'manifest'
$ReadmePath   = Join-Path $Root 'README.md'
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

    # 1) Try JSON: { "major_version": 1, "minor_version": 2 }
    try {
        $json = $raw | ConvertFrom-Json -ErrorAction Stop
        if ($null -ne $json.major_version -and $null -ne $json.minor_version) {
            return @{
                Major = [int]$json.major_version
                Minor = [int]$json.minor_version
            }
        }
    } catch {
        # ignore, try next format
    }

    # 2) Try XML: <manifest><major_version>1</major_version><minor_version>2</minor_version></manifest>
    try {
        [xml]$xml = $raw
        $majNode = $xml.SelectSingleNode('//*[local-name()="major_version"]')
        $minNode = $xml.SelectSingleNode('//*[local-name()="minor_version"]')
        if ($majNode -and $minNode) {
            return @{
                Major = [int]$majNode.InnerText
                Minor = [int]$minNode.InnerText
            }
        }
    } catch {
        # ignore, try next format
    }

    # 3) Try key/value lines:
    # major_version=1
    # minor_version: 2
    $maj = $null
    $min = $null

    foreach ($line in ($raw -split "`r?`n")) {
        if (-not $maj -and $line -match '^\s*major_version\s*[:=]\s*(\d+)\s*$') { $maj = [int]$Matches[1] }
        if (-not $min -and $line -match '^\s*minor_version\s*[:=]\s*(\d+)\s*$') { $min = [int]$Matches[1] }
    }

    if ($null -ne $maj -and $null -ne $min) {
        return @{ Major = $maj; Minor = $min }
    }

    throw "Could not find major_version and minor_version in manifest. Supported formats: JSON, XML, or key/value lines."
}

# ---- Validate inputs exist (fail fast with clear errors) ----
$requiredPaths = @(
    $ManifestPath, $ReadmePath,
    $Components, $Images, $Source
)

foreach ($p in $requiredPaths) {
    if (-not (Test-Path -LiteralPath $p)) {
        throw "Required file/folder missing: $p"
    }
}

# ---- Read version ----
$ver = Get-VersionFromManifest -Path $ManifestPath
$major = $ver.Major
$minor = $ver.Minor

# ---- Build output path ----
if (-not (Test-Path -LiteralPath $BackupsDir)) {
    New-Item -ItemType Directory -Path $BackupsDir | Out-Null
}

$zipName = "Show Stash $major.$minor.zip"
$zipPath = Join-Path $BackupsDir $zipName

# ---- Collect items to zip ----
# Compress-Archive needs paths; include the folder paths themselves so structure is preserved
$itemsToZip = @(
    $ManifestPath,
    $ReadmePath,
    $Components,
    $Images,
    $Source
)

# If a previous zip exists, overwrite it
if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}

Compress-Archive -Path $itemsToZip -DestinationPath $zipPath -Force

Write-Host "Created: $zipPath"