#!/bin/bash
set -e

pkg=krakatau2
PKG=KRAKATAU2
cmd=krak2
cmd_alt1=krakatau2

#target_install_path=$PWD/installed
pkg_path=$target_install_path/usr/local/$pkg
bin_path=$target_install_path/usr/local/bin
pkg_info=$pkg_path/$pkg.txt

mkdir -p $pkg_path $bin_path /build
pushd /build
git clone -b v2 --single-branch https://github.com/Storyyeller/Krakatau
cd Krakatau
last_commit=$(git log -1 --pretty=format:"%h %ad" --date=short)
commit_hash=$(git log -1 --pretty=format:"%h")
remote_path=$(git remote get-url origin)
github_url=$(echo "$remote_path" | sed -e 's/git@github.com:/https:\/\/github.com\//' -e 's/.git$//')
commit_url="${github_url}/commit/${commit_hash}"
echo "$last_commit" > $pkg_info
echo "$commit_url" >> $pkg_info

cargo build --release
mv target/release/krak2 $pkg_path
rm -rf /build
popd

ln -s ../$pkg/$cmd $bin_path/$cmd
ln -s ../$pkg/$cmd $bin_path/$cmd_alt1

# Checking it can be runned
$bin_path/$cmd help