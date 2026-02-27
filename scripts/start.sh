#!/bin/bash
set -euo pipefail

PORT="${port}"
LOG_PATH="${log_path}"
DEBUG="${debug}"
INSTALL_DIR="${install_dir}"

ARGS="--allow-remote-access --port $PORT"

if [ "$DEBUG" = "true" ]; then
  ARGS="$ARGS --debug"
fi

echo "Starting Tidewave on port $PORT..."
$INSTALL_DIR/tidewave $ARGS > "$LOG_PATH" 2>&1 &
TIDEWAVE_PID=$!

sleep 2

if kill -0 "$TIDEWAVE_PID" 2>/dev/null; then
  echo "Tidewave is running (PID $TIDEWAVE_PID), logs at $LOG_PATH"
else
  echo "ERROR: Tidewave failed to start. Logs:"
  cat "$LOG_PATH"
  exit 1
fi
