# Boom 2D - Dedicated Server (Windows)
# Chạy script này trên máy host tại nhà

param(
    [int]$Port = 7777
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    BOOM 2D - DEDICATED SERVER" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Port:    $Port (WebSocket)" -ForegroundColor Yellow
Write-Host "Tunnel:  Playit.gg" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

# Tìm Godot binary
$GODOT_BIN = $null
$paths = @(
    "$env:USERPROFILE\Downloads\Godot_v4.7.1-stable_win64.exe",
    "$env:USERPROFILE\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe",
    "C:\Godot\Godot_v4.7.1-stable_win64.exe"
)

foreach ($p in $paths) {
    if (Test-Path $p) {
        $GODOT_BIN = $p
        break
    }
}

if (-not $GODOT_BIN) {
    # Fallback: search Downloads
    $found = Get-ChildItem "$env:USERPROFILE\Downloads\Godot*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { $GODOT_BIN = $found.FullName }
}

if (-not $GODOT_BIN) {
    Write-Host "[ERROR] Godot not found in Downloads" -ForegroundColor Red
    exit 1
}

Write-Host "Using: $GODOT_BIN" -ForegroundColor Green

# Kiểm tra Playit
$playitRunning = Get-Process -Name "playit" -ErrorAction SilentlyContinue
if ($playitRunning) {
    Write-Host "[OK] Playit agent is running" -ForegroundColor Green
} else {
    Write-Host "[WARN] Playit agent not detected. Start it manually!" -ForegroundColor Yellow
}

# Chạy server
& $GODOT_BIN --headless --path $PSScriptRoot -- --server --port=$Port
