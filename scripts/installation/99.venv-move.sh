#!/bin/bash
set -ex

find $venv/bin/ -type f -executable -exec basename {} \; | sort >$venv/list-commands-end.txt
comm -3 $venv/list-commands-start.txt $venv/list-commands-end.txt | awk '{$1=$1; print}' >$venv/list-commands.txt
rm $venv/list-commands-start.txt $venv/list-commands-end.txt

if [ -d "$venv" ]; then 
    pushd $venv/..
    mkdir -p $target_install_path$PWD
    popd
    mv $venv $target_install_path$venv
fi

if [ -d "$PIPX_BASE" ]; then 
    if [ -d "$PIPX_BASE/venvs/logs" ]; then 
        rm -rf $PIPX_BASE/venvs/logs
    fi
    if [ -d "$PIPX_BASE/venvs/.cache" ]; then 
        rm -rf $PIPX_BASE/venvs/.cache
    fi
    pushd $PIPX_BASE/..
    mkdir -p $target_install_path$PWD
    popd
    mv $PIPX_BASE $target_install_path$PIPX_BASE
fi
