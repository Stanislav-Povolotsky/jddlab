#!/usr/bin/env sh
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PYTHON="${PYTHON:-python3}"
"$PYTHON" "$SCRIPT_DIR/install.py" add opencode "$@"
