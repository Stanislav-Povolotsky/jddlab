#!/bin/bash
set -ex

mkdir -p $venv $PIPX_BASE $PIPX_HOME $PIPX_BIN_DIR
python3 -m venv $venv
source $venv/bin/activate
pip3 install requests
find $venv/bin/ -type f -executable -exec basename {} \; | sort >$venv/list-commands-start.txt