$ErrorActionPreference = "Stop"

# Build a deterministic v12 runtime bundle without touching the shipped v11 art.
# Existing authored v12 actions win; missing contracts are normalized from the
# matching v11 pose so every character exposes the same runtime contract.
$projectRoot = Split-Path -Parent $PSScriptRoot
$charactersRoot = Join-Path $projectRoot "assets\characters"
$ids = @(
    "boom_mascot", "cloud_bunny", "cocoa_otter", "coral_diver", "lime_dino",
    "mint_sprout", "red_rider", "star_skater", "sunny_mechanic"
)
$expected = [ordered]@{
    idle_down = 4; idle_up = 4; idle_left = 4; idle_right = 4
    walk_down = 8; walk_up = 8; walk_left = 8; walk_right = 8
    rescue = 4; water_hit = 4; bubble = 6; rescued = 4
    die = 6; win = 6; lose = 6
}
$sourceMap = @{
    rescue = "escape"
    water_hit = "bubbled"
    bubble = "bubbled"
    rescued = "escape"
    die = "lose"
    win = "win"
    lose = "lose"
}

function Get-PngFrames([string]$directory) {
    if (-not (Test-Path $directory)) { return @() }
    return @(Get-ChildItem -LiteralPath $directory -Filter "*.png" -File | Sort-Object Name)
}

function Copy-Contract([string]$sourceDir, [string]$targetDir, [int]$count) {
    $frames = Get-PngFrames $sourceDir
    if ($frames.Count -eq 0) { throw "No source frames: $sourceDir" }
    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    # Do not leave stale frames behind when this script is re-run.
    Get-ChildItem -LiteralPath $targetDir -Filter "*.png" -File -ErrorAction SilentlyContinue | Remove-Item -Force
    for ($i = 0; $i -lt $count; $i++) {
        $src = $frames[$i % $frames.Count].FullName
        $dst = Join-Path $targetDir ("{0:D3}.png" -f $i)
        Copy-Item -LiteralPath $src -Destination $dst -Force
    }
}

$report = @()
foreach ($id in $ids) {
    $v11 = Join-Path $charactersRoot "$id\v11"
    $runtime = Join-Path $charactersRoot "$id\v12_staging\runtime_frames"
    New-Item -ItemType Directory -Force -Path $runtime | Out-Null
    $sources = @{}
    foreach ($action in $expected.Keys) {
        $targetDir = Join-Path $runtime $action
        $existing = Get-PngFrames $targetDir
        if ($existing.Count -ne [int]$expected[$action]) {
            $sourceAction = if ($sourceMap.ContainsKey($action)) { $sourceMap[$action] } else { $action }
            $sourceDir = Join-Path $v11 $sourceAction
            Copy-Contract $sourceDir $targetDir ([int]$expected[$action])
            $sources[$action] = "v11:$sourceAction (normalized)"
        } else {
            $sources[$action] = "v12-authored"
        }
    }
    $report += [ordered]@{
        id = $id
        canvas = "112x112"
        actions = $expected
        sources = $sources
        production_replaced = $false
    }
}

$manifest = [ordered]@{
    schema_version = 1
    generated_at = (Get-Date).ToUniversalTime().ToString("o")
    contract = $expected
    characters = $report
    note = "v12 staging only; v11 remains the production fallback until visual migration approval."
}
$manifestPath = Join-Path $charactersRoot "v12_staging_manifest.json"
$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
Write-Output "CHARACTER_V12_COMPAT BUILT characters=$($ids.Count) manifest=$manifestPath"
