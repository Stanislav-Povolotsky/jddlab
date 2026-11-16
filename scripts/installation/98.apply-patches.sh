#!/bin/bash
set -ex

cp -r $SCRIPT_DIR/patches/* /

# Nothing is installed in version-collection-only builds.
[[ "$versions_collect_mode" == "0" ]] || return 0

# objection / objection@16 `patchapk`: use the Frida gadgets baked into the image
# (17.frida-gadgets.sh) instead of downloading them. Applied after the static
# patches above, which replace objection@16's mobile_packages.py.
python3 $SCRIPT_DIR/helpers/patch-objection.py \
    $(ls -d $venv/lib/python*/site-packages/objection/commands/mobile_packages.py) VERSION
python3 $SCRIPT_DIR/helpers/patch-objection.py \
    $(ls -d $PIPX_HOME/venvs/objection@16/lib/python*/site-packages/objection/commands/mobile_packages.py) VERSION-16

# objection@16 (1.11) passes an empty '' argument to `apktool decode` when not
# skipping resources, which apktool 3.x rejects (prints its usage): patchapk failed.
objection16_android=$(ls -d $PIPX_HOME/venvs/objection@16/lib/python*/site-packages/objection/utils/patchers/android.py)
grep -q "'-r' if self.skip_resources else ''," $objection16_android
sed -i "s/'-r' if self.skip_resources else '',/*(['-r'] if self.skip_resources else []),/" $objection16_android
