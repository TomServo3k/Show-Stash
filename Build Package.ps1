# New-ShowStashBackup.ps1
# Zips: manifest, README.md, components/, images/, source/
# Output: Backups\Show Stash M.m.zip  where M=major_version, m=minor_version

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Work relative to this script's folder
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

$ManifestPath = Join-Path $Root 'manifest'
$ReadmePath   = Join-Path $Root 'README.md'
$Components   = Join-Path $Root 'components'
$Images       = Join-Path $Root 'images'
$Source       = Join-Path $Root 'source'
$BackupsDir   = Join-Path $Root 'Backups'

# ---- OPTIONAL: Hardcode 7z.exe path if needed ----
# If 7z.exe is in PATH, just use:
$SevenZip = "C:\Program Files\7-Zip\7z.exe"
#$SevenZip = "7z.exe"

function Get-VersionFromManifest {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Manifest file not found at: $Path"
    }

    $raw = Get-Content -LiteralPath $Path -Raw

    # 1) Try JSON
    try {
        $json = $raw | ConvertFrom-Json -ErrorAction Stop
        if ($null -ne $json.major_version -and $null -ne $json.minor_version) {
            return @{
                Major = [int]$json.major_version
                Minor = [int]$json.minor_version
            }
        }
    } catch {}

    # 2) Try XML
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
    } catch {}

    # 3) Try key/value
    $maj = $null
    $min = $null

    foreach ($line in ($raw -split "`r?`n")) {
        if (-not $maj -and $line -match '^\s*major_version\s*[:=]\s*(\d+)\s*$') { $maj = [int]$Matches[1] }
        if (-not $min -and $line -match '^\s*minor_version\s*[:=]\s*(\d+)\s*$') { $min = [int]$Matches[1] }
    }

    if ($null -ne $maj -and $null -ne $min) {
        return @{ Major = $maj; Minor = $min }
    }

    throw "Could not find major_version and minor_version in manifest."
}

# ---- Validate inputs exist ----
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

# ---- Remove old zip if exists ----
if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}

# ---- Build 7z command ----
$itemsToZip = @(
    $ManifestPath,
    $ReadmePath,
    $Components,
    $Images,
    $Source
)

# Quote a single argument for 7z
function Quote {
    param([string]$s)
    '"' + $s.Replace('"', '\"') + '"'
}

# 7z syntax: 7z a -tzip -y "output.zip" "item1" "item2" ...
$argParts = @(
    "a",
    "-tzip",
    "-y",
    (Quote $zipPath)          # <-- MUST be wrapped in parentheses
) + ($itemsToZip | ForEach-Object { Quote $_ })

$argumentString = $argParts -join ' '

$process = Start-Process -FilePath $SevenZip -ArgumentList $argumentString -NoNewWindow -Wait -PassThru

if ($process.ExitCode -ne 0) {
    throw "7-Zip failed with exit code $($process.ExitCode). Command line: $SevenZip $argumentString"
}

Write-Host "Created: $zipPath"
