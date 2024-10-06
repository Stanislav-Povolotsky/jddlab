#!/bin/bash
set -e

pkg=smali
PKG=smali
cmd_smali=smali
cmd_baksmali=baksmali

#target_install_path=$PWD/installed
pkg_path=$target_install_path/usr/local/$pkg
bin_path=$target_install_path/usr/local/bin
pkg_info_smali=$pkg_path/$cmd_smali.txt
pkg_info_baksmali=$pkg_path/$cmd_baksmali.txt

ls -al $bin_path

mkdir -p $pkg_path $bin_path
package_info_prefix=14.smali

cp $package_info_prefix.smali.txt    $pkg_info_smali
fname=`head -n 3 $pkg_info_smali | tail -n 1`
url=`head -n 4 $pkg_info_smali | tail -n 1`
echo "File: $fname; Url: $url"

pushd $pkg_path
curl -L -o $fname $url
popd

exec_script=$pkg_path/$cmd_smali
cp helpers/template-java-runner.sh $exec_script
sed -i "s/\/template/\/$fname/" $exec_script
sed -i "s/template/$cmd_smali/g" $exec_script
sed -i "s/TEMPLATE/SMALI/g" $exec_script
chmod 0755 $exec_script
ln -s ../$pkg/$cmd_smali $bin_path/$cmd_smali
# Checking it can be runned
$bin_path/$cmd_smali

cp $package_info_prefix.baksmali.txt $pkg_info_baksmali
fname=`head -n 3 $pkg_info_baksmali | tail -n 1`
url=`head -n 4 $pkg_info_baksmali | tail -n 1`
echo "File: $fname; Url: $url"

pushd $pkg_path
curl -L -o $fname $url
popd

exec_script=$pkg_path/$cmd_baksmali
cp helpers/template-java-runner.sh $exec_script
sed -i "s/\/template/\/$fname/" $exec_script
sed -i "s/template/$cmd_baksmali/g" $exec_script
sed -i "s/TEMPLATE/BAKSMALI/g" $exec_script
chmod 0755 $exec_script
ln -s ../$pkg/$cmd_baksmali $bin_path/$cmd_baksmali
# Checking it can be runned
$bin_path/$cmd_smali
