#!/bin/bash
set -e

if [ -d "$venv" ]; then 
    pushd $venv/..
    mkdir -p $target_install_path$PWD
    popd
    mv $venv $target_install_path$venv
fi