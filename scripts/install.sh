#!/bin/bash
set -euo pipefail

DOWNLOAD_URL="${download_url}"
INSTALL_DIR="${install_dir}"
VERSION="${tidewave_version}"
BINARY="$INSTALL_DIR/tidewave"

# If a specific version is pinned, skip download if already installed.
if [ "$VERSION" != "latest" ] && command -v tidewave >/dev/null 2>&1; then
  INSTALLED_VERSION=$(tidewave --version 2>/dev/null || true)
  if echo "$INSTALLED_VERSION" | grep -q "$VERSION"; then
    echo "Tidewave $VERSION is already installed, skipping download."
    exit 0
  fi
fi

echo "Downloading Tidewave from $DOWNLOAD_URL..."
curl -fsSL -o "$BINARY" "$DOWNLOAD_URL"
chmod +x "$BINARY"

echo "Tidewave installed to $BINARY"
tidewave --version
