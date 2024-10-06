#!/bin/bash
set -e

pkg=krakatau
PKG=KRAKATAU
cmd_disassemble=krakatau-disassemble
cmd_assemble=krakatau-assemble

#target_install_path=$PWD/installed
pkg_path=$target_install_path/usr/local/$pkg
bin_path=$target_install_path/usr/local/bin
pkg_info=$pkg_path/$pkg.software_version.txt

mkdir -p $pkg_path $bin_path
pushd $pkg_path
git clone -b master --single-branch https://github.com/Storyyeller/Krakatau .
last_commit="commit $(git log -1 --pretty=format:"%h at %ad" --date=short) on $(git branch --show-current) branch"
commit_hash=$(git log -1 --pretty=format:"%h")
remote_path=$(git remote get-url origin)
github_url=$(echo "$remote_path" | sed -e 's/git@github.com:/https:\/\/github.com\//' -e 's/.git$//')
commit_url="${github_url}/commit/${commit_hash}"
echo "$last_commit" > $pkg_info
echo "$commit_url" >> $pkg_info
rm -rf .git tests
popd

exec_script=$pkg_path/$cmd_disassemble
fname=disassemble.py
cp helpers/template-python3-runner.sh $exec_script
sed -i "s/\/template/\/$fname/" $exec_script
sed -i "s/template/$pkg/g" $exec_script
sed -i "s/TEMPLATE/$PKG/g" $exec_script
chmod 0755 $exec_script
ln -s ../$pkg/$cmd_disassemble $bin_path/$cmd_disassemble

exec_script=$pkg_path/$cmd_assemble
fname=assemble.py
cp helpers/template-python3-runner.sh $exec_script
sed -i "s/\/template/\/$fname/" $exec_script
sed -i "s/template/$pkg/g" $exec_script
sed -i "s/TEMPLATE/$PKG/g" $exec_script
chmod 0755 $exec_script
ln -s ../$pkg/$cmd_assemble $bin_path/$cmd_assemble

# Checking it can be runned
$bin_path/$cmd_disassemble --help