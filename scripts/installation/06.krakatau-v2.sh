#!/bin/bash
set -e

pkg=krakatau2
PKG=KRAKATAU2
cmd=krak2
cmd_alt1=krakatau2

#target_install_path=$PWD/installed
pkg_path=$target_install_path/usr/local/$pkg
bin_path=$target_install_path/usr/local/bin
pkg_info=$pkg_path/$pkg.software_version.txt

mkdir -p $pkg_path $bin_path /tmp/$pkg /build

REPO="Storyyeller/Krakatau"
BRANCH="v2"
REPOFULL="https://github.com/$REPO"

if [[ "$versions_collect_mode" == "0" ]]; then
    # Installation mode
    pushd /build
    git clone -b $BRANCH --single-branch $REPOFULL
    cd Krakatau
    last_commit="commit $(TZ=UTC0 git log -1 --pretty=format:"%h at %ad" --date='format-local:%Y-%m-%d') on $(git branch --show-current) branch"
    commit_hash=$(git log -1 --pretty=format:"%h")
    remote_path=$(git remote get-url origin)
    github_url=$(echo "$remote_path" | sed -e 's/git@github.com:/https:\/\/github.com\//' -e 's/.git$//')
    commit_url="${github_url}/commit/${commit_hash}"
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
    pushd /build
    cargo build --release
    mv target/release/krak2 $pkg_path
    popd

    ln -s ../$pkg/$cmd $bin_path/$cmd
    ln -s ../$pkg/$cmd $bin_path/$cmd_alt1

    # Checking it can be runned
    $bin_path/$cmd help 2>&1 | tee -a $pkg_path/$cmd.command_help.txt
fi

# Cleaning temp folder
rm -rf /tmp/$pkg /build
