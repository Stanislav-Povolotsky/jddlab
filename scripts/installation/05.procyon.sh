#!/bin/bash
set -e

pkg=procyon
PKG=PROCYON
pkg_alt1=procyon-decompiler

#target_install_path=$PWD/installed
pkg_path=$target_install_path/usr/local/$pkg
bin_path=$target_install_path/usr/local/bin
pkg_info=$pkg_path/$pkg.software_version.txt

mkdir -p $pkg_path $bin_path /tmp/$pkg
python3 helpers/get-release-info.py https://github.com/mstrobel/procyon -fan '^procyon-decompiler-[\d.]+.jar$' -o $pkg_info
fname=`head -n 3 $pkg_info | tail -n 1`
url=`head -n 4 $pkg_info | tail -n 1`
echo "File: $fname; Url: $url"

if [[ "$versions_collect_mode" == "0" ]]; then
    # Installation mode
    pushd $pkg_path
    curl -L -o $fname $url
    popd
    
    exec_script=$pkg_path/$pkg
    cp helpers/template-java-runner.sh $exec_script
    sed -i "s/\/template/\/$fname/" $exec_script
    sed -i "s/template/$pkg/g" $exec_script
    sed -i "s/TEMPLATE/$PKG/g" $exec_script
    chmod 0755 $exec_script
    ln -s ../$pkg/$pkg $bin_path/$pkg
    ln -s ../$pkg/$pkg $bin_path/$pkg_alt1
    # Checking it can be runned
    $bin_path/$pkg 2>&1 | tee -a $pkg_path/$pkg.command_help.txt
fi

# Cleaning temp folder
rm -rf /tmp/$pkg
