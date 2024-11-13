#!/bin/bash
set -e

pkg=dex2jar
#target_install_path=$PWD/installed
pkg_path=$target_install_path/usr/local/$pkg
bin_path=$target_install_path/usr/local/bin
pkg_info=$pkg_path/$pkg.software_version.txt

mkdir -p $pkg_path $bin_path /tmp/$pkg
python3 helpers/get-release-info.py https://github.com/pxb1988/dex2jar -fan '^dex-tools-v[\d.]+.zip$' -o $pkg_info
fname=`head -n 3 $pkg_info | tail -n 1`
url=`head -n 4 $pkg_info | tail -n 1`
echo "File: $fname; Url: $url"

if [[ "$versions_collect_mode" == "0" ]]; then
    # Installation mode
    pushd /tmp/$pkg
    mkdir -p /tmp/$pkg/extracted
    curl -L -o $fname $url
    unzip $fname -d /tmp/$pkg/extracted/
    mv /tmp/$pkg/extracted/dex-tools*/* $pkg_path
    popd
    
    pushd $pkg_path
    for filename in d2j-*.sh; do
      cmd="${filename%.sh}"
      ln -s ../$pkg/$filename $bin_path/$cmd
      cmd="${cmd#d2j-}"
      if [ ! -f "$bin_path/$cmd" ]; then
          ln -s ../$pkg/$filename $bin_path/$cmd
      fi
    done
    popd

    # Checking it can be runned
    $bin_path/$pkg --help 2>&1 | tee -a $pkg_path/$pkg.command_help.txt
fi

# Cleaning temp folder
rm -rf /tmp/$pkg
