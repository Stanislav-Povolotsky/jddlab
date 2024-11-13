#!/bin/bash
set -e

pkg=jadx
#target_install_path=$PWD/installed
pkg_path=$target_install_path/usr/local/$pkg
bin_path=$target_install_path/usr/local/bin
pkg_info=$pkg_path/$pkg.software_version.txt

mkdir -p $pkg_path $bin_path
python3 helpers/get-release-info.py https://github.com/skylot/jadx -fan '^jadx-[\d.]+.zip$' -o $pkg_info
fname=`head -n 3 $pkg_info | tail -n 1`
url=`head -n 4 $pkg_info | tail -n 1`
echo "File: $fname; Url: $url"

if [[ "$versions_collect_mode" == "0" ]]; then
    # Installation mode
    pushd /tmp
    curl -L -o $fname $url
    unzip $fname -d $pkg_path
    rm $fname
    popd
    ln -s ../$pkg/bin/$pkg $bin_path/$pkg

    # Checking it can be runned
    $bin_path/$pkg --help 2>&1 | tee -a $pkg_path/$pkg.command_help.txt
fi
