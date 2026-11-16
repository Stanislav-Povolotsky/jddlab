#!/bin/bash
set -ex

# Deduplicate Frida gadgets across tools: point android-unpinner's bundled
# gadgets at the shared build-time cache (17.frida-gadgets.sh), so the image does
# not store the same gadgets twice. android-unpinner gets the frida 16.x gadget:
# its unpinning scripts (httptoolkit-unpinner.js, ...) are plain scripts that use
# the global `Java` object, which frida 17 no longer provides to such scripts - with
# a 17.x gadget they fail silently and nothing is unpinned (verified on a device).
#
# objection doesn't store gadgets in the image: its patchapk copies the baked one
# into ~/.objection at runtime (see helpers/patch-objection.py, 98.apply-patches.sh).

# Nothing is installed in version-collection-only builds.
[[ "$versions_collect_mode" == "0" ]] || return 0

cache_dir=$target_install_path/usr/local/frida-gadgets
frida_version=$(cat $cache_dir/VERSION-16)

# android-unpinner is installed into the main venv; its vendored gadgets live at
# .../android_unpinner/vendor/frida/frida-gadget-<ver>-android-<arch>.so
au_frida_dir=$(ls -d $venv/lib/python*/site-packages/android_unpinner/vendor/frida 2>/dev/null | head -n1)

if [ -z "$au_frida_dir" ] || [ ! -d "$au_frida_dir" ]; then
    echo "ERROR: couldn't locate android-unpinner's vendored frida directory under $venv"
    exit 1
fi

for arch in arm arm64 x86 x86_64; do
    # Absolute target path as it will exist in the final image.
    target=/usr/local/frida-gadgets/frida-gadget-$frida_version-android-$arch.so

    # Replace whatever gadget file android-unpinner shipped for this arch with a
    # symlink to the shared cache (keeping the original filename it references).
    for existing in "$au_frida_dir"/frida-gadget-*-android-$arch.so; do
        [ -e "$existing" ] || continue
        rm -f "$existing"
        ln -s "$target" "$existing"
    done
done
