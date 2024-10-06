#!/bin/bash
set -e

SCRIPT_FILE="$(readlink --canonicalize-existing "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_FILE")"
export target_install_path=$SCRIPT_DIR/installed
export venv=/usr/local/python-venv
export PATH="/root/.cargo/bin:$PATH"

pushd $SCRIPT_DIR
for filename in ??.*.sh; do
  source $filename
done
popd
