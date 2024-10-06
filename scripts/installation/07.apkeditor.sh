#!/bin/bash
set -e

pkg=apkeditor
PKG=APKEDITOR
pkg_alt1=APKEditor

#target_install_path=$PWD/installed
pkg_path=$target_install_path/usr/local/$pkg
bin_path=$target_install_path/usr/local/bin
pkg_info=$pkg_path/$pkg.txt

mkdir -p $pkg_path $bin_path
python3 get-release-info.py https://github.com/REAndroid/APKEditor -fan '^APKEditor-[\d.]+.jar$' -o $pkg_info
fname=`head -n 3 $pkg_info | tail -n 1`
url=`head -n 4 $pkg_info | tail -n 1`
echo "File: $fname; Url: $url"

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
# Command returns errorcode 2 on help/version commands
$bin_path/$pkg -h || if [ $? -ne 2 ]; then exit 1; fi
