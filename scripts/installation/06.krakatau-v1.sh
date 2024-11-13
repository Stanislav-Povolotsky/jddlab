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
REPOFULL="https://github.com/$REPO"

if [[ "$versions_collect_mode" == "0" ]]; then
    # Installation mode
    pushd $pkg_path
    git clone -b $BRANCH --single-branch $REPOFULL .
    last_commit="commit $(TZ=UTC0 git log -1 --pretty=format:"%h at %ad" --date='format-local:%Y-%m-%d') on $(git branch --show-current) branch"
    commit_hash=$(git log -1 --pretty=format:"%h")
    remote_path=$(git remote get-url origin)
    github_url=$(echo "$remote_path" | sed -e 's/git@github.com:/https:\/\/github.com\//' -e 's/.git$//')
    commit_url="$REPOFULL/commit/${commit_hash}"
    rm -rf .git tests
    popd
else
    last_commit_data=$(curl -s "https://api.github.com/repos/$REPO/commits/$BRANCH")
    full_commit_hash=$(echo "$last_commit_data" | jq -r '.sha')
    commit_hash=${full_commit_hash:0:7}
    commit_date_utc=$(echo "$last_commit_data" | jq -r '.commit.committer.date')
    commit_date=$(date -d "$commit_date_utc" +%Y-%m-%d)
    remote_path="$REPOFULL"
    last_commit="commit $commit_hash at $commit_date on $BRANCH branch"
    commit_url="$REPOFULL/commit/${commit_hash}"
fi
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
