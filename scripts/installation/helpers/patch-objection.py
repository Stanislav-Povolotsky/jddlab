#!/usr/bin/env python3
"""
jddlab: patch objection's `patchapk` so that it injects the Frida gadget baked into
the image at build time (/usr/local/frida-gadgets, see 17.frida-gadgets.sh) instead
of asking GitHub for the latest gadget and downloading it on every run.

New behaviour of `objection patchapk`:
  * no --gadget-version -> the default baked version (read from <default-version-file>
                           in the gadget dir: VERSION for objection, VERSION-16 for
                           objection@16, whose frida 16.x client needs a 16.x gadget)
  * --gadget-version X  -> the baked gadget if version X is baked, else download X
  * JDDLAB_FRIDA_ONLINE=1 -> original behaviour (download from GitHub)
  * JDDLAB_FRIDA_GADGET_DIR overrides the gadget dir

The anchor must exist exactly once, so if upstream objection changes, the build
fails loudly instead of silently shipping the download-every-run behaviour.

Usage: patch-objection.py <objection/commands/mobile_packages.py> <default-version-file>
"""
import sys
from pathlib import Path

ANCHOR = (
    "    # set the architecture we are interested in\n"
    "    android_gadget.set_architecture(architecture)\n"
)

INSERT = '''
    # jddlab: use the Frida gadget baked into the image instead of downloading it
    # (see scripts/installation/helpers/patch-objection.py)
    import os as _jddlab_os, shutil as _jddlab_shutil
    _jddlab_dir = _jddlab_os.environ.get('JDDLAB_FRIDA_GADGET_DIR', '/usr/local/frida-gadgets')
    _jddlab_version = gadget_version
    if _jddlab_version is None and _jddlab_os.path.isfile(_jddlab_os.path.join(_jddlab_dir, '{default_file}')):
        with open(_jddlab_os.path.join(_jddlab_dir, '{default_file}')) as _jddlab_f:
            _jddlab_version = _jddlab_f.read().strip()
    _jddlab_gadget = _jddlab_os.path.join(_jddlab_dir, 'frida-gadget-{{0}}-android-{{1}}.so'.format(
        _jddlab_version, android_gadget.architectures.get(architecture)))
    if _jddlab_version and _jddlab_os.path.isfile(_jddlab_gadget) and \\
            _jddlab_os.environ.get('JDDLAB_FRIDA_ONLINE', '') in ('', '0', 'false', 'False'):
        click.secho('Using the Frida gadget baked into the jddlab image: {{0}}'.format(_jddlab_version),
                    fg='green', bold=True)
        _jddlab_shutil.copyfile(_jddlab_gadget, android_gadget.get_frida_library_path())
        android_gadget.set_local_version('android_' + architecture, _jddlab_version)
        gadget_version = _jddlab_version
'''


def main():
    if len(sys.argv) != 3:
        raise SystemExit(__doc__.strip().splitlines()[-1])
    path = Path(sys.argv[1])
    src = path.read_text()
    count = src.count(ANCHOR)
    if count != 1:
        raise SystemExit(f"patch-objection: expected exactly 1 anchor in {path}, found {count}")
    src = src.replace(ANCHOR, ANCHOR + INSERT.format(default_file=sys.argv[2]))
    path.write_text(src)
    print(f"patch-objection: patched {path}")


if __name__ == "__main__":
    main()
