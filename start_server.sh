#!/bin/bash
PORT="${SERVER_PORT:-7777}"
REGION="${REGION:-vn}"

echo "========================================"
echo "    BOOM 2D - DEDICATED SERVER"
echo "========================================"
echo "Region:  $REGION"
echo "Port:    $PORT (WebSocket)"
echo "========================================"

GODOT_BIN=""
if command -v godot &> /dev/null; then
    GODOT_BIN="godot"
elif [ -f "/usr/local/bin/godot" ]; then
    GODOT_BIN="/usr/local/bin/godot"
fi

if [ -z "$GODOT_BIN" ]; then
    echo "[ERROR] Godot binary not found."
    exit 1
fi

exec "$GODOT_BIN" --headless --path "$(dirname "$0")" -- --server --port "$PORT"
