#!/bin/bash
set -ex

pkg=objection
pip_pkg=objection

#target_install_path=$PWD/installed
pkg_path=$target_install_path/usr/local/$pkg
pkg_info=$pkg_path/$pkg.software_version.txt
mkdir -p $pkg_path /tmp/$pkg

if [[ "$versions_collect_mode" == "0" ]]; then
    # Installation mode
    pip3 install $pip_pkg

    # Extracting Name, Version, and Home-page
    pip_show_output=$(pip3 show $pip_pkg)
    name=$(echo "$pip_show_output" | grep '^Name:' | awk '{print $2}')
    version=$(echo "$pip_show_output" | grep '^Version:' | awk '{print $2}')
    home_page=$(echo "$pip_show_output" | grep '^Home-page:' | awk '{print $2}')
else
    # Only collection version info
    pushd /tmp/$pkg
    curl -o package.json -s https://pypi.org/pypi/$pip_pkg/json
    name=$(cat package.json | jq -r .info.name)
    version=$(cat package.json | jq -r .info.version)
    home_page=$(cat package.json | jq -r .info.home_page)
    popd
fi

# Manual fill
home_page=${home_page:-"https://github.com/sensepost/objection"}

echo "$version"           >$pkg_info
echo "$home_page"         >>$pkg_info
echo "$pip_pkg==$version" >>$pkg_info
echo "https://pypi.org/project/$pip_pkg/$version" >>$pkg_info

if [[ "$versions_collect_mode" == "0" ]]; then
    # Installing old versions of objection
    pipx install \
         "frida-tools==12.3.0" --suffix=@16
    pipx runpip frida-tools@16 install \
        "frida==16.1.3" "setuptools==65.5.1"
    pipx install "objection==1.11.0" --suffix=@16
    pipx runpip objection@16 install \
        "frida==16.1.3" \
        "frida-tools==12.3.0" \
        "setuptools==65.5.1"

    # Installation mode
    ln -s $venv/bin/$pkg $bin_path/$pkg

    # Checking it can be runned
    $bin_path/$pkg --help 2>&1 | tee -a $pkg_path/$pkg.command_help.txt
fi

# Cleaning temp folder
rm -rf /tmp/$pkg
