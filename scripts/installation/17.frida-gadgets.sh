#!/bin/bash
set -ex

# Frida gadgets baked into the image at build time. Instead of every tool
# downloading the *latest* gadget from GitHub on each run, we download the
# latest gadget once, at image build time, into a shared cache. apk-patcher and
# android-unpinner are wired to use this cache (see 18.apk-patcher.sh and
# 20.frida-gadget-links.sh). objection keeps its own runtime download logic
# untouched, because objection@16 needs its own frida 16.x gadget for old
# Android devices (see 13.objection.sh).

pkg=frida-gadgets
pkg_path=$target_install_path/usr/local/$pkg
pkg_info=$pkg_path/$pkg.software_version.txt

mkdir -p $pkg_path /tmp/$pkg

# Frida gadget architectures we bake in (frida arch names, matching the release
# asset names and apk-patcher's ABI_MAPPING values).
FRIDA_ARCHS="arm arm64 x86 x86_64"
FRIDA_RELEASE_API="https://api.github.com/repos/frida/frida/releases/latest"

# Resolve the latest Frida version in BOTH build modes, so the
# version-collection-only build reports it correctly too.
curl -sSL -o /tmp/$pkg/release.json "$FRIDA_RELEASE_API"
frida_version=$(jq -r .tag_name /tmp/$pkg/release.json)

if [ -z "$frida_version" ] || [ "$frida_version" == "null" ]; then
    echo "ERROR: couldn't determine the latest Frida version from $FRIDA_RELEASE_API"
    cat /tmp/$pkg/release.json
    exit 1
fi

echo "Latest Frida gadget version: $frida_version"

# software-list.txt entry (4 lines: version, home page, file, download url)
arch_csv=$(echo $FRIDA_ARCHS | tr ' ' ',')
echo "$frida_version"                                              >$pkg_info
echo "https://github.com/frida/frida"                             >>$pkg_info
echo "frida-gadget-$frida_version-android-{$arch_csv}.so"         >>$pkg_info
echo "https://github.com/frida/frida/releases/tag/$frida_version" >>$pkg_info

if [[ "$versions_collect_mode" == "0" ]]; then
    # Installation mode: download + decompress every arch into the shared cache.
    echo "$frida_version" >$pkg_path/VERSION

    for arch in $FRIDA_ARCHS; do
        asset="frida-gadget-$frida_version-android-$arch.so.xz"
        url=$(jq -r --arg a "$asset" '.assets[] | select(.name==$a) | .browser_download_url' /tmp/$pkg/release.json)

        if [ -z "$url" ] || [ "$url" == "null" ]; then
            echo "ERROR: couldn't find asset $asset in Frida release $frida_version"
            exit 1
        fi

        echo "Downloading $asset from $url"
        curl -fSL -o /tmp/$pkg/$asset "$url"
        python3 -c "import lzma,sys; open(sys.argv[2],'wb').write(lzma.open(sys.argv[1]).read())" \
            "/tmp/$pkg/$asset" "$pkg_path/frida-gadget-$frida_version-android-$arch.so"
    done
fi

# Cleaning temp folder
rm -rf /tmp/$pkg
