#!/bin/bash
set -e

pkg=apkscan
pip_pkg=$pkg

#target_install_path=$PWD/installed
pkg_path=$target_install_path/usr/local/$pkg
pkg_info=$pkg_path/$pkg.software_version.txt
mkdir -p $pkg_path

pip3 install $pip_pkg

# Extracting Name, Version, and Home-page
pip_show_output=$(pip3 show $pip_pkg)
name=$(echo "$pip_show_output" | grep '^Name:' | awk '{print $2}')
version=$(echo "$pip_show_output" | grep '^Version:' | awk '{print $2}')
home_page=$(echo "$pip_show_output" | grep '^Home-page:' | awk '{print $2}')
echo "$version"            >$pkg_info
echo "$home_page"         >>$pkg_info
echo "$pip_pkg==$version" >>$pkg_info
echo "https://pypi.org/project/$pip_pkg/$version" >>$pkg_info

# Checking it can be runned
$pkg -h