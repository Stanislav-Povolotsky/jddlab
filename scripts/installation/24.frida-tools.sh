#!/bin/bash
set -ex

# frida-tools (frida, frida-ps, frida-trace, ...). They are installed into the
# shared venv together with objection, so objection and the frida CLI always use
# the same frida version. This script makes the version explicit in the software
# list and exposes the commands in /usr/local/bin (and therefore to MCP).
# The frida 16.x flavour for old Android devices is installed by 13.objection.sh
# as frida@16, frida-ps@16, ...

pkg=frida-tools
pip_pkg=frida-tools
cmds="frida frida-ps frida-trace frida-ls-devices frida-kill frida-discover frida-compile"

#target_install_path=$PWD/installed
pkg_path=$target_install_path/usr/local/$pkg
bin_path=$target_install_path/usr/local/bin
pkg_info=$pkg_path/$pkg.software_version.txt
mkdir -p $pkg_path $bin_path /tmp/$pkg

if [[ "$versions_collect_mode" == "0" ]]; then
    # Installation mode
    pip3 install $pip_pkg
    version=$(pip3 show $pip_pkg | grep '^Version:' | awk '{print $2}')
    frida_version=$(pip3 show frida | grep '^Version:' | awk '{print $2}')
else
    # Only collection version info
    version=$(curl -sfL https://pypi.org/pypi/$pip_pkg/json | jq -r .info.version)
    frida_version=$(curl -sfL https://pypi.org/pypi/frida/json | jq -r .info.version)
fi

echo "$version (frida $frida_version)"     >$pkg_info
echo "https://github.com/frida/frida-tools" >>$pkg_info
echo "$pip_pkg==$version"                   >>$pkg_info
echo "https://pypi.org/project/$pip_pkg/$version" >>$pkg_info

if [[ "$versions_collect_mode" == "0" ]]; then
    # Installation mode
    for cmd in $cmds; do
        ln -s ../python-venv/bin/$cmd $bin_path/$cmd
    done

    # Checking it can be runned (loads the native frida module)
    $venv/bin/frida --version 2>&1 | tee -a $pkg_path/frida.command_help.txt
    rc=${PIPESTATUS[0]}
    if [[ $rc -ne 0 ]]; then
        echo "ERROR: frida --version failed with code $rc"
        exit $rc
    fi
    $venv/bin/frida --help 2>&1 >>$pkg_path/frida.command_help.txt || true
fi

# Cleaning temp folder
rm -rf /tmp/$pkg
