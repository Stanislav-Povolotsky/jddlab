#!/bin/bash
set -ex

# Python CLI tools installed into isolated pipx venvs (see helpers/pipx-tool.sh).

source $SCRIPT_DIR/helpers/pipx-tool.sh

# APKiD - identifies packers, protectors, obfuscators and compilers in APK/DEX files
pipx_tool apkid apkid "https://github.com/rednaga/APKiD" apkid

# hermes-dec - disassembler/decompiler for React Native Hermes bytecode (index.android.bundle)
pipx_tool hermes-dec hermes-dec "https://github.com/P1sec/hermes-dec" \
    hbc-decompiler hbc-disassembler hbc-file-parser

# mobsfscan - static analysis (SAST) of Android/iOS source code (e.g. jadx output)
pipx_tool mobsfscan mobsfscan "https://github.com/MobSF/mobsfscan" mobsfscan
if [[ "$versions_collect_mode" == "0" ]]; then
    # mobsfscan runs `semgrep` from PATH (without it every Java/Kotlin rule is
    # silently skipped): expose the semgrep installed in mobsfscan's venv.
    ln -s ../venvs/venvs/mobsfscan/bin/semgrep $PIPX_BIN_DIR/semgrep
    $PIPX_BIN_DIR/semgrep --version
fi

# quark-engine - Android malware behaviour scoring (pins its own androguard)
pipx_tool quark-engine quark-engine "https://github.com/quark-engine/quark-engine" quark freshquark

if [[ "$versions_collect_mode" == "0" ]]; then
    # quark-engine needs its rule set; bake it into the image instead of downloading
    # it on every run. quark looks for rules in $HOME/.quark-engine/quark-rules and
    # the image uses HOME=/root for every user (see Dockerfile).
    quark_home=/tmp/quark-home
    mkdir -p $quark_home
    HOME=$quark_home $PIPX_BIN_DIR/freshquark
    test "$(find $quark_home/.quark-engine/quark-rules/rules -name '*.json' | wc -l)" -gt 0
    rm -rf $quark_home/.quark-engine/quark-rules/.git
    mkdir -p ${target_install_path}${HOME}
    mv $quark_home/.quark-engine ${target_install_path}${HOME}/
    rm -rf $quark_home
fi
