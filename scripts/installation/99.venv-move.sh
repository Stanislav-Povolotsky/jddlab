#!/bin/bash
set -e

find $venv/bin/ -type f -executable -exec basename {} \; | sort >$venv/list-commands-end.txt
comm -3 $venv/list-commands-start.txt $venv/list-commands-end.txt | awk '{$1=$1; print}' >$venv/list-commands.txt
rm $venv/list-commands-start.txt $venv/list-commands-end.txt

if [ -d "$venv" ]; then 
    pushd $venv/..
    mkdir -p $target_install_path$PWD
    popd
    mv $venv $target_install_path$venv
fi