#!/bin/bash
set -ex

# ilspycmd - command-line .NET decompiler (ILSpy engine), for Xamarin / .NET MAUI
# assemblies extracted with pyxamstore.
#
# ilspycmd is published as a "RID-specific" dotnet tool. We don't need the .NET
# SDK to install it - the NuGet packages are plain zip files:
#  - ilspycmd.linux-x64: a self-contained native (AOT) binary, no .NET runtime needed;
#  - ilspycmd.any:       framework-dependent build, needs the .NET runtime (used on
#                        arm64, where no native package exists; the runtime is
#                        installed into /usr/local/dotnet).

pkg=ilspycmd
cmd=ilspycmd

#target_install_path=$PWD/installed
pkg_path=$target_install_path/usr/local/$pkg
bin_path=$target_install_path/usr/local/bin
pkg_info=$pkg_path/$pkg.software_version.txt
dotnet_path=$target_install_path/usr/local/dotnet

mkdir -p $pkg_path $bin_path /tmp/$pkg

NUGET=https://api.nuget.org/v3-flatcontainer
# Latest stable (non-prerelease) version
version=$(curl -sfL $NUGET/$pkg/index.json | jq -r '[.versions[] | select(test("-") | not)] | last')
if [ -z "$version" ] || [ "$version" == "null" ]; then
    echo "ERROR: couldn't determine the latest $pkg version"
    exit 1
fi

case "$(uname -m)" in
    x86_64) rid=linux-x64 ;;
    *)      rid=any ;;
esac
nupkg_id=$pkg.$rid
nupkg_url=$NUGET/$nupkg_id/$version/$nupkg_id.$version.nupkg

echo "$version"                                          >$pkg_info
echo "https://github.com/icsharpcode/ILSpy"             >>$pkg_info
echo "$nupkg_id.$version.nupkg"                          >>$pkg_info
echo "https://www.nuget.org/packages/$pkg/$version"      >>$pkg_info

if [[ "$versions_collect_mode" == "0" ]]; then
    # Installation mode
    pushd /tmp/$pkg
    curl -fL -o $pkg.nupkg $nupkg_url
    unzip -q $pkg.nupkg 'tools/*' -d nupkg
    tool_dir=$(dirname "$(find nupkg/tools -name DotnetToolSettings.xml | head -n 1)")
    cp -r $tool_dir/. $pkg_path/
    rm -f $pkg_path/*.pdb $pkg_path/*.xml
    popd

    if [[ "$rid" == "any" ]]; then
        # Framework-dependent build: install the matching .NET runtime.
        dotnet_channel=$(jq -r '.runtimeOptions.framework.version' $pkg_path/ilspycmd.runtimeconfig.json | cut -d. -f1,2)
        curl -fsSL -o /tmp/$pkg/dotnet-install.sh https://dot.net/v1/dotnet-install.sh
        bash /tmp/$pkg/dotnet-install.sh --channel $dotnet_channel --runtime dotnet --install-dir $dotnet_path
        # Absolute paths as they will exist in the final image
        cat >$pkg_path/$cmd <<'EOF'
#!/bin/sh
export DOTNET_ROOT=/usr/local/dotnet
exec /usr/local/dotnet/dotnet /usr/local/ilspycmd/ilspycmd.dll "$@"
EOF
        chmod 0755 $pkg_path/$cmd
        # For the build-time check below (the runtime is not at its final path yet)
        check_cmd="$dotnet_path/dotnet $pkg_path/ilspycmd.dll"
    else
        chmod 0755 $pkg_path/$cmd
        check_cmd="$pkg_path/$cmd"
    fi
    ln -s ../$pkg/$cmd $bin_path/$cmd

    # Checking it can be runned
    DOTNET_ROOT=$dotnet_path $check_cmd --help 2>&1 | tee -a $pkg_path/$cmd.command_help.txt
    rc=${PIPESTATUS[0]}
    if [[ $rc -ne 0 ]]; then
        echo "ERROR: $cmd --help failed with code $rc"
        exit $rc
    fi
fi

# Cleaning temp folder
rm -rf /tmp/$pkg
