#!/usr/bin/env python3
"""
jddlab: patch a freshly-cloned apk-patcher.py so that, by default, it injects the
Frida gadget baked into the image at build time (offline, reproducible) instead
of downloading the *latest* gadget from GitHub on every single run.

New behaviour:
  * default            -> use the build-time cache (FRIDA_GADGET_CACHE_DIR,
                          default /usr/local/frida-gadgets, override with the
                          JDDLAB_FRIDA_GADGET_DIR environment variable)
  * --frida-version X  -> download version X from GitHub
  * --online           -> download the latest version from GitHub
                          (also enabled via JDDLAB_FRIDA_ONLINE=1)

Each replacement asserts that its anchor exists exactly once, so if upstream
apk-patcher changes the relevant code the build fails loudly instead of silently
shipping the old (download-every-run) behaviour.
"""
import sys
from pathlib import Path


def replace_once(text, old, new, what):
    count = text.count(old)
    if count != 1:
        raise SystemExit(
            f"patch-apk-patcher: expected exactly 1 occurrence of {what}, found {count}"
        )
    return text.replace(old, new)


NEW_ARGS = (
    "    parser.add_argument (\n"
    "            '--frida-version',\n"
    "            dest = \"frida_version\",\n"
    "            type = str,\n"
    "            default = None,\n"
    "            help = (\"Frida gadget version to inject. By default (jddlab) the version baked\\n\"\n"
    "                \"into the image at build time is used (offline). Passing a version\\n\"\n"
    "                \"downloads it from GitHub instead.\")\n"
    "        )\n"
    "\n"
    "    parser.add_argument (\n"
    "            '--online',\n"
    "            action = \"store_true\",\n"
    "            default = (os.environ.get (\"JDDLAB_FRIDA_ONLINE\", \"\") not in (\"\", \"0\", \"false\", \"False\")),\n"
    "            help = (\"Download the latest Frida gadget from GitHub instead of using the\\n\"\n"
    "                \"build-time cache. Also enabled via JDDLAB_FRIDA_ONLINE=1.\")\n"
    "        )\n"
    "\n"
)


NEW_FUNC = r'''
def _load_cached_gadget (arch, frida_version):
    """
    jddlab: return (decompressed gadget bytes, version) from the build-time
    cache, or (None, version) if it isn't available. When `frida_version` is
    None the version baked into the image (cache VERSION file) is used.
    """
    cache_dir = FRIDA_GADGET_CACHE_DIR

    if frida_version is None:
        version_file = cache_dir / "VERSION"
        if not version_file.is_file ():
            return None, None
        frida_version = version_file.read_text ().strip ()

    lib_path = cache_dir / f"frida-gadget-{frida_version}-android-{arch}.so"
    if not lib_path.is_file ():
        return None, frida_version

    logger.info (f"Using cached Frida gadget {lib_path}")
    return lib_path.read_bytes (), frida_version


def _download_gadget (arch, frida_version):
    """
    jddlab: download and decompress the Frida gadget for `arch` from GitHub.
    When `frida_version` is None the latest release is used.
    """
    if frida_version is None:
        assets_url = FRIDA_ASSETS_URL
    else:
        assets_url = f"https://api.github.com/repos/frida/frida/releases/tags/{frida_version}"

    logger.info (f"Requesting {assets_url}")
    r = requests.get (assets_url)
    if r.status_code != 200:
        logger.error (f"Couldn't GET {assets_url} . Response code: {r.status_code} {r.reason}")
        return None, frida_version

    frida_release = r.json ()
    frida_version = frida_release ["tag_name"]

    target = f"frida-gadget-{frida_version}-android-{arch}.so.xz"
    for asset in frida_release ["assets"]:
        if asset ["name"] == target:
            download_url = asset ["browser_download_url"]
            logger.info (f"Located {target} @ {download_url}")

            with requests.get (download_url, stream = True) as dl:
                if dl.status_code != 200:
                    logger.error (f"Couldn't GET {download_url} . Response code: {dl.status_code} {dl.reason}")
                    return None, frida_version

                return decompress (dl.content, format = FORMAT_XZ), frida_version

    logger.error (f"Couldn't find {target} in the Frida release {frida_version}")
    return None, frida_version


def add_native_lib_to_apk (apk_path, out_path, frida_script = None, gadget_config = None, forced_arch = None, forced_dir = None, frida_version = None, online = False):
    """
    Adds the Frida gadget to the APK, generating a copy of it.
    The original APK is not modified.

    jddlab: by default the gadget is taken from the build-time cache
    (FRIDA_GADGET_CACHE_DIR) so builds are offline and reproducible. Passing
    `frida_version`, or `online` (--online / JDDLAB_FRIDA_ONLINE=1), fetches the
    gadget from GitHub instead.
    """
    architectures = [ forced_arch ] if forced_arch else get_arch_from_filename (apk_path)

    # Explicitly requesting a version, or --online, forces a GitHub download.
    use_online = online or (frida_version is not None)

    with (
        zipfile.ZipFile (apk_path, "r") as in_apk,
        zipfile.ZipFile (out_path, "a") as out_apk
    ):

        # First we add all the original files to the new APK
        for filename in in_apk.namelist ():
            copy_to_zip (in_apk, out_apk, filename)

        # Then, the new items
        for arch in architectures:
            logger.info (f"Processing architecture {arch}")

            lib = None
            resolved_version = frida_version

            if not use_online:
                lib, resolved_version = _load_cached_gadget (arch, frida_version)
                if lib is None:
                    logger.warning (
                        f"No cached Frida gadget for {arch} under {FRIDA_GADGET_CACHE_DIR}; "
                        "downloading from GitHub. Use --online to silence this warning."
                    )

            if lib is None:
                lib, resolved_version = _download_gadget (arch, frida_version)

            if lib is None:
                logger.error (f"Couldn't obtain a Frida gadget for architecture {arch}; skipping it")
                continue

            logger.info (f"Using Frida gadget version {resolved_version} for {arch}")

            dirname = forced_dir if forced_dir else ("lib/" + arch_to_dirname (arch))

            if dirname is None:
                # idk, man...
                dirname = arch

            out_apk.writestr (f"{dirname}/libgadget.so", lib)
            if gadget_config:
                out_apk.writestr (f"{dirname}/libgadget.config.so", gadget_config)
            if frida_script:
                out_apk.writestr (f"{dirname}/libgadget.js.so", frida_script)
            logger.debug (f"Added all *.so to {out_path}!{dirname}/")
'''


def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: patch-apk-patcher.py <path-to-apk-patcher.py>")

    path = Path(sys.argv[1])
    src = path.read_text()

    # 1) make `os` available (used by the cache constant and --online default)
    src = replace_once(
        src, "import argparse\n", "import argparse\nimport os\n", "the argparse import"
    )

    # 2) build-time gadget cache constant
    src = replace_once(
        src,
        'FRIDA_ASSETS_URL = "https://api.github.com/repos/frida/frida/releases/latest"\n',
        'FRIDA_ASSETS_URL = "https://api.github.com/repos/frida/frida/releases/latest"\n'
        "\n"
        "# jddlab: Frida gadgets baked into the image at build time.\n"
        "# See scripts/installation/17.frida-gadgets.sh\n"
        'FRIDA_GADGET_CACHE_DIR = Path (os.environ.get ("JDDLAB_FRIDA_GADGET_DIR", "/usr/local/frida-gadgets"))\n',
        "the FRIDA_ASSETS_URL constant",
    )

    # 3) new CLI flags
    src = replace_once(
        src,
        "    args = parser.parse_args ()\n",
        NEW_ARGS + "    args = parser.parse_args ()\n",
        "parser.parse_args()",
    )

    # 4) replace add_native_lib_to_apk with the cache-aware version
    start = "def add_native_lib_to_apk ("
    end = "\n\n\ndef get_full_filelist ("
    i = src.find(start)
    j = src.find(end)
    if i == -1 or j == -1 or j < i:
        raise SystemExit("patch-apk-patcher: couldn't locate add_native_lib_to_apk")
    src = src[:i] + NEW_FUNC.strip("\n") + src[j:]

    # 5) pass the new options through at both call sites
    src = replace_once(
        src,
        "                    forced_arch = args.arch,\n"
        "                    forced_dir = args.dir_lib\n"
        "                )",
        "                    forced_arch = args.arch,\n"
        "                    forced_dir = args.dir_lib,\n"
        "                    frida_version = args.frida_version,\n"
        "                    online = args.online\n"
        "                )",
        "the abi-split call site",
    )
    src = replace_once(
        src,
        "                forced_arch = args.arch,\n"
        "                forced_dir = args.dir_lib\n"
        "            )",
        "                forced_arch = args.arch,\n"
        "                forced_dir = args.dir_lib,\n"
        "                frida_version = args.frida_version,\n"
        "                online = args.online\n"
        "            )",
        "the single-apk call site",
    )

    path.write_text(src)
    print(f"patch-apk-patcher: patched {path}")


if __name__ == "__main__":
    main()
