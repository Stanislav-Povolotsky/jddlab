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

mkdir -p $pkg_path $bin_path

smali_ver=2.5.2
mvn dependency:get -Dartifact=org.smali:smali:$smali_ver
mv ~/.m2/repository/org/smali/smali/$smali_ver/smali-$smali_ver.jar $pkg_path/
fname=smali-$smali_ver.jar

exec_script=$pkg_path/$cmd_smali
cp helpers/template-java-runner.sh $exec_script
sed -i "s/\/template/\/$fname/" $exec_script
sed -i "s/template/$cmd_smali/g" $exec_script
sed -i "s/TEMPLATE/SMALI/g" $exec_script
chmod 0755 $exec_script
ln -s ../$pkg/$cmd_smali $bin_path/$cmd_smali
# Checking it can be runned
#$bin_path/$cmd_smali

