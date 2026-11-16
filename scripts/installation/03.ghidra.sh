#!/bin/bash
set -ex

pkg=ghidra
#target_install_path=$PWD/installed
pkg_path=$target_install_path/usr/local/$pkg
bin_path=$target_install_path/usr/local/bin
pkg_info=$pkg_path/$pkg.software_version.txt
cmd_ghidra_analyze_headless=ghidra
cmd_decompile=ghidra-decompile

mkdir -p $pkg_path $bin_path /tmp/$pkg

python3 helpers/get-release-info.py https://github.com/NationalSecurityAgency/ghidra -fan '^ghidra_[\d.]+_PUBLIC_[\d]+.zip$' -o $pkg_info
fname=`head -n 3 $pkg_info | tail -n 1`
url=`head -n 4 $pkg_info | tail -n 1`
echo "File: $fname; Url: $url"

if [[ "$versions_collect_mode" == "0" ]]; then
    # Installation mode
    pushd /tmp/$pkg
    curl -L -o $fname $url
    unzip $fname
    rm $fname
    cd ghidra*
    rm -rf docs Extensions server 
    mv * $pkg_path/
    popd
    ln -s ../$pkg/support/analyzeHeadless $bin_path/$cmd_ghidra_analyze_headless

    # Ghidra releases ship the native decompiler for linux_x86_64 only. On arm64
    # build it from the C++ sources included in the release (a few minutes).
    # 'ghidra_opt' is the decompiler process Ghidra talks to (os/<os>/decompile);
    # the Makefile only knows x86/mac, and would pass -m32: clear ARCH_TYPE.
    decompiler_dir=$pkg_path/Ghidra/Features/Decompiler
    if [[ "$(uname -m)" == "aarch64" && ! -x $decompiler_dir/os/linux_arm_64/decompile ]]; then
        make -C $decompiler_dir/src/decompile/cpp -j$(nproc) ARCH_TYPE= ghidra_opt
        mkdir -p $decompiler_dir/os/linux_arm_64
        mv $decompiler_dir/src/decompile/cpp/ghidra_opt $decompiler_dir/os/linux_arm_64/decompile
        rm -rf $decompiler_dir/src/decompile/cpp/ghi_opt
    fi

    chmod +x helpers/ghidra/*.sh
    mv helpers/ghidra/* $pkg_path/
    ln -s ../$pkg/ghidra-decompile.sh $bin_path/$cmd_decompile

    # Checking it can be runned
    $bin_path/$cmd_ghidra_analyze_headless 2>&1 | tee -a $pkg_path/$cmd_ghidra_analyze_headless.command_help.txt
    rc=${PIPESTATUS[0]}
    if [[ $rc -ne 0 && $rc -ne 1 ]]; then
        echo "ERROR: $cmd_ghidra_analyze_headless --help failed with code $rc"
        cat $pkg_path/$cmd_ghidra_analyze_headless.command_help.txt
        exit $rc
    fi
    $bin_path/$cmd_decompile 2>&1 | tee -a $pkg_path/$cmd_decompile.command_help.txt
    rc=${PIPESTATUS[0]}
    if [[ $rc -ne 0 && $rc -ne 1 ]]; then
        echo "ERROR: $cmd_decompile --help failed with code $rc"
        cat $pkg_path/$cmd_ghidra_analyze_headless.command_help.txt
        exit $rc
    fi
fi