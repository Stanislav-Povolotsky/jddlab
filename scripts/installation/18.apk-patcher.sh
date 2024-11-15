#!/bin/bash
set -e

pkg=apk-patcher
PKG=APKPATCHER
cmd=$pkg

#target_install_path=$PWD/installed
pkg_path=$target_install_path/usr/local/$pkg
bin_path=$target_install_path/usr/local/bin
pkg_info=$pkg_path/$pkg.software_version.txt

mkdir -p $pkg_path $bin_path /build /tmp/$pkg

REPO="Foo-Manroot/apk-patcher"
BRANCH="main"

if [[ "$versions_collect_mode" == "0" ]]; then
    # Installation mode
    pushd /build
    git clone -b $BRANCH --single-branch "https://github.com/$REPO" .
    $SCRIPT_DIR/helpers/get-git-branch-info.sh local $BRANCH >/tmp/$pkg/info.txt
    python3 -m pip install -r requirements.txt
    mv apk-patcher.py requirements.txt LICENSE README.md java_libs $pkg_path/
    mkdir -p "$pkg_path/Java/APK patcher/app/build/libs/"
    mv "Java/APK patcher/app/build/libs/app.jar" "$pkg_path/Java/APK patcher/app/build/libs/"
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
    exec_script=$pkg_path/$cmd
    fname=apk-patcher.py
    cp helpers/template-python3-runner.sh $exec_script
    sed -i "s/\/template/\/$fname/" $exec_script
    sed -i "s/template/$pkg/g" $exec_script
    sed -i "s/TEMPLATE/$PKG/g" $exec_script
    chmod 0755 $exec_script
    ln -s ../$pkg/$cmd $bin_path/$cmd

    # Checking it can be runned
    $bin_path/$cmd --help 2>&1 | tee -a $pkg_path/$cmd.command_help.txt
fi

# Cleaning temp folder
rm -rf /tmp/$pkg /build
