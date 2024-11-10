#!/bin/bash
set -e

mkdir -p $venv
python3 -m venv $venv
source $venv/bin/activate
pip3 install requests
find $venv/bin/ -type f -executable -exec basename {} \; | sort >$venv/list-commands-start.txt