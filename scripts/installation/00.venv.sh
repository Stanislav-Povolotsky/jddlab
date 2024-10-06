#!/bin/bash
set -e

mkdir -p $venv
python3 -m venv $venv
source $venv/bin/activate
pip3 install requests