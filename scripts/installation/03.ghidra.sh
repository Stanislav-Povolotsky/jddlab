#!/bin/bash
set -e

pkg=ghidra
#target_install_path=$PWD/installed
pkg_path=$target_install_path/usr/local/$pkg
bin_path=$target_install_path/usr/local/bin
pkg_info=$pkg_path/$pkg.software_version.txt
cmd_ghidra_analyze_headless=ghidra
cmd_decompile=ghidra-decompile

mkdir -p $pkg_path $bin_path

python3 helpers/get-release-info.py https://github.com/NationalSecurityAgency/ghidra -fan '^ghidra_[\d.]+_PUBLIC_[\d]+.zip$' -o $pkg_info
fname=`head -n 3 $pkg_info | tail -n 1`
url=`head -n 4 $pkg_info | tail -n 1`
echo "File: $fname; Url: $url"

mkdir -p /tmp/ghidra
pushd /tmp/ghidra
curl -L -o $fname $url
unzip $fname
rm $fname
cd ghidra*
rm -rf docs Extensions server 
mv * $pkg_path/
popd
ln -s ../$pkg/support/analyzeHeadless $bin_path/$cmd_ghidra_analyze_headless

chmod +x helpers/ghidra/*.sh
mv helpers/ghidra/* $pkg_path/
ln -s ../$pkg/ghidra-decompile.sh $bin_path/$cmd_decompile

# Checking it can be runned
$bin_path/$cmd_ghidra_analyze_headless 2>&1 | tee -a $pkg_path/$cmd_ghidra_analyze_headless.command_help.txt
$bin_path/$cmd_decompile 2>&1 | tee -a $pkg_path/$cmd_decompile.command_help.txt
