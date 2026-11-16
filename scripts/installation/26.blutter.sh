#!/bin/bash
set -ex

# blutter - Flutter (Dart AOT) reverse engineering: recovers class/function names,
# object pool and a Frida script template from an arm64 libapp.so.
#
# blutter has no generic binary: on first use for a given Dart version it fetches
# that Dart SDK and compiles a matching analyzer (needs network, a C++20 compiler,
# cmake, ninja, libcapstone and libicu - installed in the runtime image by
# scripts/run/root/scripts/run/prepare.sh). The compiled analyzers are stored in
# the persistent cache /var/cache/jddlab/blutter (a docker volume mounted by the
# jddlab launcher and the MCP server), so only the first run per Dart version is slow.

pkg=blutter
PKG=BLUTTER
cmd=blutter

#target_install_path=$PWD/installed
pkg_path=$target_install_path/usr/local/$pkg
bin_path=$target_install_path/usr/local/bin
pkg_info=$pkg_path/$pkg.software_version.txt
cache_dir=/var/cache/jddlab/blutter

mkdir -p $pkg_path $bin_path /tmp/$pkg

REPO="worawit/blutter"
BRANCH="main"

if [[ "$versions_collect_mode" == "0" ]]; then
    # Installation mode
    pushd $pkg_path
    git clone -b $BRANCH --single-branch "https://github.com/$REPO" .
    $SCRIPT_DIR/helpers/get-git-branch-info.sh local $BRANCH >/tmp/$pkg/info.txt
    rm -rf .git .vscode
    popd
    python3 -m pip install pyelftools requests
else
    $SCRIPT_DIR/helpers/get-git-branch-info.sh remote $BRANCH $REPO >/tmp/$pkg/info.txt
fi

last_commit=`head -n 1 /tmp/$pkg/info.txt | tail -n 1`
commit_url=`head -n 5 /tmp/$pkg/info.txt | tail -n 1`
echo "$last_commit" > $pkg_info
echo "$commit_url" >> $pkg_info

if [[ "$versions_collect_mode" == "0" ]]; then
    # Installation mode
    # Everything blutter generates goes to the persistent cache (see above).
    for dir in bin build dartsdk packages; do
        rm -rf $pkg_path/$dir
        ln -s $cache_dir/$dir $pkg_path/$dir
    done
    mkdir -p ${target_install_path}${cache_dir}
    chmod 1777 ${target_install_path}/var/cache/jddlab ${target_install_path}${cache_dir}

    # Not "$pkg_path/blutter": that is blutter's C++ source directory
    exec_script=$pkg_path/jddlab-$cmd
    fname=blutter.py
    cp helpers/template-python3-runner.sh $exec_script
    sed -i "s/\/template/\/$fname/" $exec_script
    sed -i "s/template/$pkg/g" $exec_script
    sed -i "s/TEMPLATE/$PKG/g" $exec_script
    # blutter.py creates bin/, build/, ... with os.makedirs: make sure the cache
    # subdirectories exist (the cache volume may be empty or freshly created).
    sed -i "s|^PYTHONCMD=python3|mkdir -p $cache_dir/bin $cache_dir/build $cache_dir/dartsdk $cache_dir/packages 2>/dev/null\nPYTHONCMD=python3|" $exec_script
    chmod 0755 $exec_script
    ln -s ../$pkg/jddlab-$cmd $bin_path/$cmd

    # Checking it can be runned
    $bin_path/$cmd --help 2>&1 | tee -a $pkg_path/$cmd.command_help.txt
    rc=${PIPESTATUS[0]}
    if [[ $rc -ne 0 && $rc -ne 1 ]]; then
        echo "ERROR: $cmd --help failed with code $rc"
        cat $pkg_path/$cmd.command_help.txt
        exit $rc
    fi
fi

# Cleaning temp folder
rm -rf /tmp/$pkg
