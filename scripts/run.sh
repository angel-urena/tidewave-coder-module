#!/bin/bash
set -euo pipefail

# --- Install ---
INSTALL_DIR="${install_dir}"
VERSION="${tidewave_version}"
LIBC="${libc}"
BINARY="$INSTALL_DIR/tidewave"

# Detect platform at runtime (not at Terraform plan time) so the correct
# binary is downloaded even when the provisioner runs on a different OS/arch
# than the workspace (e.g. macOS provisioner → Linux Docker workspace).
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$OS" in
  linux)
    case "$ARCH" in
      x86_64)  TARGET="x86_64-unknown-linux-$LIBC" ;;
      aarch64) TARGET="aarch64-unknown-linux-$LIBC" ;;
      *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
    esac
    ;;
  darwin)
    case "$ARCH" in
      x86_64)  TARGET="x86_64-apple-darwin" ;;
      arm64)   TARGET="aarch64-apple-darwin" ;;
      *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
    esac
    ;;
  *) echo "Unsupported OS: $OS"; exit 1 ;;
esac

if [ "$VERSION" = "latest" ]; then
  DOWNLOAD_URL="https://github.com/tidewave-ai/tidewave_app/releases/latest/download/tidewave-cli-$TARGET"
else
  DOWNLOAD_URL="https://github.com/tidewave-ai/tidewave_app/releases/download/$VERSION/tidewave-cli-$TARGET"
fi

# If a specific version is pinned, skip download if already installed.
if [ "$VERSION" != "latest" ] && command -v tidewave >/dev/null 2>&1; then
  INSTALLED_VERSION=$(tidewave --version 2>/dev/null || true)
  if echo "$INSTALLED_VERSION" | grep -q "$VERSION"; then
    echo "Tidewave $VERSION is already installed, skipping download."
  else
    echo "Tidewave version mismatch (installed: $INSTALLED_VERSION, wanted: $VERSION), upgrading..."
    TMP_BINARY=$(mktemp)
    curl -fsSL -o "$TMP_BINARY" "$DOWNLOAD_URL"
    chmod +x "$TMP_BINARY"
    sudo mv "$TMP_BINARY" "$BINARY"
  fi
else
  echo "Downloading Tidewave from $DOWNLOAD_URL..."
  TMP_BINARY=$(mktemp)
  curl -fsSL -o "$TMP_BINARY" "$DOWNLOAD_URL"
  chmod +x "$TMP_BINARY"
  sudo mv "$TMP_BINARY" "$BINARY"
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

ALLOWED_ORIGINS="${allowed_origins}"
ARGS="--allow-remote-access --port $PORT"

if [ -n "$ALLOWED_ORIGINS" ]; then
  ARGS="$ARGS --allowed-origins $ALLOWED_ORIGINS"
fi

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
