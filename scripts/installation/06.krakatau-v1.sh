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

mkdir -p $pkg_path $bin_path /tmp/$pkg

REPO="Storyyeller/Krakatau"
BRANCH="master"

if [[ "$versions_collect_mode" == "0" ]]; then
    # Installation mode
    pushd $pkg_path
    git clone -b $BRANCH --single-branch "https://github.com/$REPO" .
    $SCRIPT_DIR/helpers/get-git-branch-info.sh local $BRANCH >/tmp/$pkg/info.txt
    rm -rf .git tests
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
    $bin_path/$cmd_disassemble --help 2>&1 | tee -a $pkg_path/$cmd_disassemble.command_help.txt
    $bin_path/$cmd_assemble --help 2>&1 | tee -a $pkg_path/$cmd_assemble.command_help.txt
fi

# Cleaning temp folder
rm -rf /tmp/$pkg
