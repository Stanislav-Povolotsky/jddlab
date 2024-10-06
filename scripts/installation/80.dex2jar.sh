#!/bin/bash
set -e

pkg=dex2jar
#target_install_path=$PWD/installed
pkg_path=$target_install_path/usr/local/$pkg
bin_path=$target_install_path/usr/local/bin
pkg_info=$pkg_path/$pkg.txt

mkdir -p $pkg_path $bin_path
python3 get-release-info.py https://github.com/pxb1988/dex2jar -fan '^dex-tools-v[\d.]+.zip$' -o $pkg_info
fname=`head -n 3 $pkg_info | tail -n 1`
url=`head -n 4 $pkg_info | tail -n 1`
echo "File: $fname; Url: $url"

pushd /tmp
mkdir -p /tmp/extracted
curl -L -o $fname $url
unzip $fname -d /tmp/extracted/
mv /tmp/extracted/dex-tools*/* $pkg_path
rm -rf $fname /tmp/extracted/
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
$bin_path/$pkg --help