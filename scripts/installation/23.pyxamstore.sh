#!/bin/bash
set -ex

# pyxamstore - unpack/repack Xamarin / .NET MAUI assembly stores
# (assemblies.blob V1 and libassemblies.<abi>.blob.so V2/V3). The original
# jakev/pyxamstore only understands V1, so we use the maintained fork.

pkg=pyxamstore
cmd=pyxamstore

#target_install_path=$PWD/installed
pkg_path=$target_install_path/usr/local/$pkg
bin_path=$target_install_path/usr/local/bin
pkg_info=$pkg_path/$pkg.software_version.txt

mkdir -p $pkg_path $bin_path /build /tmp/$pkg

REPO="AbhiTheModder/pyxamstore"
BRANCH="master"

if [[ "$versions_collect_mode" == "0" ]]; then
    # Installation mode
    pushd /build
    git clone -b $BRANCH --single-branch "https://github.com/$REPO" .
    $SCRIPT_DIR/helpers/get-git-branch-info.sh local $BRANCH >/tmp/$pkg/info.txt
    rm -rf .git
    pipx install /build
    popd
else
    $SCRIPT_DIR/helpers/get-git-branch-info.sh remote $BRANCH $REPO >/tmp/$pkg/info.txt
fi

last_commit=`head -n 1 /tmp/$pkg/info.txt | tail -n 1`
commit_url=`head -n 5 /tmp/$pkg/info.txt | tail -n 1`
echo "$last_commit" > $pkg_info
echo "$commit_url" >> $pkg_info

if [[ "$versions_collect_mode" == "0" ]]; then
    # Installation mode
    ln -s $PIPX_BIN_DIR/$cmd $bin_path/$cmd

    # Checking it can be runned
    $PIPX_BIN_DIR/$cmd --help 2>&1 | tee -a $pkg_path/$cmd.command_help.txt
    rc=${PIPESTATUS[0]}
    if [[ $rc -ne 0 && $rc -ne 1 ]]; then
        echo "ERROR: $cmd --help failed with code $rc"
        cat $pkg_path/$cmd.command_help.txt
        exit $rc
    fi
fi

# Cleaning temp folder
rm -rf /tmp/$pkg /build
