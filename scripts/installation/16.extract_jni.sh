#!/bin/bash
set -e

pkg=extract_jni
PKG=EXTRACT_JNI

#target_install_path=$PWD/installed
pkg_path=$target_install_path/usr/local/$pkg
bin_path=$target_install_path/usr/local/bin
pkg_info=$pkg_path/$pkg.software_version.txt

mkdir -p $pkg_path $bin_path /tmp/$pkg
python3 helpers/get-release-info.py https://github.com/evilpan/jni_helper -fan '^src.zip$' -o $pkg_info --include-src
fname=`head -n 3 $pkg_info | tail -n 1`
url=`head -n 4 $pkg_info | tail -n 1`
echo "File: $fname; Url: $url"

if [[ "$versions_collect_mode" == "0" ]]; then
    # Installation mode
    pushd /tmp/$pkg
    curl -L -o $fname $url
    unzip $fname
    rm $fname
    pushd evilpan*
    python3 -m pip install -r requirements.txt
    mv *.py *.md *.txt $pkg_path
    popd
    popd
    
    exec_script=$pkg_path/$pkg
    fname=extract_jni.py
    cp helpers/template-python3-runner.sh $exec_script
    sed -i "s/\/template/\/$fname/" $exec_script
    sed -i "s/template/$pkg/g" $exec_script
    sed -i "s/TEMPLATE/$PKG/g" $exec_script
    chmod 0755 $exec_script
    ln -s ../$pkg/$pkg $bin_path/$pkg
    
    # Checking it can be runned
    $bin_path/$pkg --help 2>&1 | tee -a $pkg_path/$pkg.command_help.txt
fi

# Cleaning temp folder
rm -rf /tmp/$pkg
