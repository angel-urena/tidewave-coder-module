#!/bin/bash
set -euo pipefail

# --- Install ---
DOWNLOAD_URL="${download_url}"
INSTALL_DIR="${install_dir}"
VERSION="${tidewave_version}"
BINARY="$INSTALL_DIR/tidewave"

# If a specific version is pinned, skip download if already installed.
if [ "$VERSION" != "latest" ] && command -v tidewave >/dev/null 2>&1; then
  INSTALLED_VERSION=$(tidewave --version 2>/dev/null || true)
  if echo "$INSTALLED_VERSION" | grep -q "$VERSION"; then
    echo "Tidewave $VERSION is already installed, skipping download."
  else
    echo "Tidewave version mismatch (installed: $INSTALLED_VERSION, wanted: $VERSION), upgrading..."
    curl -fsSL -o "$BINARY" "$DOWNLOAD_URL"
    chmod +x "$BINARY"
  fi
else
  echo "Downloading Tidewave from $DOWNLOAD_URL..."
  curl -fsSL -o "$BINARY" "$DOWNLOAD_URL"
  chmod +x "$BINARY"
  echo "Tidewave installed to $BINARY"
  tidewave --version
fi

# --- Start ---
PORT="${port}"
LOG_PATH="${log_path}"
DEBUG="${debug}"

# Kill any existing Tidewave process so re-runs don't fail on port conflicts.
pkill -f "$BINARY" 2>/dev/null || true
sleep 0.5

ARGS="--allow-remote-access --port $PORT"

if [ "$DEBUG" = "true" ]; then
  ARGS="$ARGS --debug"
fi

echo "Starting Tidewave on port $PORT..."
$BINARY $ARGS > "$LOG_PATH" 2>&1 &
TIDEWAVE_PID=$!

sleep 2

if kill -0 "$TIDEWAVE_PID" 2>/dev/null; then
  echo "Tidewave is running (PID $TIDEWAVE_PID), logs at $LOG_PATH"
else
  echo "ERROR: Tidewave failed to start. Logs:"
  cat "$LOG_PATH"
  exit 1
fi
