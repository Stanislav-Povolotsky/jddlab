#!/usr/bin/env python3
"""Bootstrap the jddlab skills from the shared jddlab bundle.

Skills ship inside the SAME release bundle as the MCP server
(``jddlab-mcp-<version>.zip``) and share the same install location
(``~/.jddlab/mcp/current``). This mirrors ``mcp/bootstrap.py``: installed ``jddlab``
launcher scripts may not have a repository checkout next to them, so when the skills
are requested standalone we download (or reuse) that bundle and run the bundled
``skills/install.py`` from it.

If the MCP bundle is already installed, no download happens - the skills are installed
from the existing bundle. The file is intentionally dependency-free (stdlib only).
"""

from __future__ import annotations

import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
import urllib.request
import zipfile
from pathlib import Path


DEFAULT_REPOSITORY = "Stanislav-Povolotsky/jddlab"
# Skills ride in the MCP bundle - same asset, same install home.
ASSET_PREFIX = "jddlab-mcp-"
ASSET_SUFFIX = ".zip"


def request_bytes(url: str) -> bytes:
    request = urllib.request.Request(url, headers={"User-Agent": "jddlab-skills-bootstrap"})
    with urllib.request.urlopen(request, timeout=120) as response:
        return response.read()


def install_root() -> Path:
    # Shared with the MCP bundle on purpose.
    return Path(os.environ.get("JDDLAB_MCP_HOME", Path.home() / ".jddlab" / "mcp")).expanduser()


def current_dir() -> Path:
    return install_root() / "current"


def current_installer() -> Path:
    return current_dir() / "skills" / "install.py"


def bundle_has_skills() -> bool:
    return current_installer().exists()


def find_release_asset(release: dict[str, object]) -> tuple[str, str, str | None]:
    assets = release.get("assets", [])
    if not isinstance(assets, list):
        raise RuntimeError("GitHub release JSON does not contain an assets list")
    zip_asset: dict[str, object] | None = None
    sha_asset_url: str | None = None
    for asset in assets:
        if not isinstance(asset, dict):
            continue
        name = str(asset.get("name", ""))
        if name.startswith(ASSET_PREFIX) and name.endswith(ASSET_SUFFIX):
            zip_asset = asset
        if name.startswith(ASSET_PREFIX) and name.endswith(ASSET_SUFFIX + ".sha256"):
            sha_asset_url = str(asset.get("browser_download_url", ""))
    if not zip_asset:
        raise RuntimeError(f"No {ASSET_PREFIX}*{ASSET_SUFFIX} asset found in the latest release")
    return (
        str(zip_asset.get("name", "")),
        str(zip_asset.get("browser_download_url", "")),
        sha_asset_url,
    )


def verify_sha256(path: Path, sha_url: str | None) -> None:
    if not sha_url:
        print("Warning: no .sha256 asset found for jddlab bundle; skipping checksum verification.")
        return
    expected_text = request_bytes(sha_url).decode("utf-8").strip()
    expected = expected_text.split()[0].lower()
    actual = hashlib.sha256(path.read_bytes()).hexdigest().lower()
    if actual != expected:
        raise RuntimeError(f"Checksum mismatch for {path.name}: expected {expected}, got {actual}")


def copy_bundle_to_install_root(bundle_zip: Path, version: str) -> Path:
    root = install_root()
    releases = root / "releases"
    release_dir = releases / version
    with tempfile.TemporaryDirectory(prefix="jddlab-bundle-") as temp_name:
        temp_dir = Path(temp_name)
        with zipfile.ZipFile(bundle_zip) as zf:
            zf.extractall(temp_dir)
        candidates = [temp_dir / "jddlab-mcp", *[p for p in temp_dir.iterdir() if p.is_dir()]]
        bundle_root = next((p for p in candidates if (p / "skills" / "install.py").exists()), None)
        if not bundle_root:
            raise RuntimeError(
                "Downloaded jddlab bundle does not contain skills/install.py "
                "(the release may predate skills bundling)."
            )
        if release_dir.exists():
            shutil.rmtree(release_dir)
        release_dir.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(bundle_root, release_dir)
    current = current_dir()
    if current.exists():
        shutil.rmtree(current)
    shutil.copytree(release_dir, current)
    return current


def install_or_update(force: bool = False) -> Path:
    if bundle_has_skills() and not force:
        return current_dir()

    root = install_root()
    downloads = root / "downloads"
    downloads.mkdir(parents=True, exist_ok=True)

    local_bundle = os.environ.get("JDDLAB_MCP_BUNDLE")
    if local_bundle:
        bundle_path = Path(local_bundle).expanduser().resolve()
        if not bundle_path.exists():
            raise RuntimeError(f"JDDLAB_MCP_BUNDLE does not exist: {bundle_path}")
        version = bundle_path.stem.removeprefix(ASSET_PREFIX)
        return copy_bundle_to_install_root(bundle_path, version)

    repository = os.environ.get("JDDLAB_GITHUB_REPOSITORY", DEFAULT_REPOSITORY)
    api_url = os.environ.get("JDDLAB_MCP_RELEASE_API", f"https://api.github.com/repos/{repository}/releases/latest")
    release = json.loads(request_bytes(api_url).decode("utf-8"))
    version = str(release.get("tag_name") or "latest")
    asset_name, asset_url, sha_url = find_release_asset(release)
    if not asset_url:
        raise RuntimeError(f"Release asset {asset_name} has no browser_download_url")
    bundle_path = downloads / asset_name
    print(f"Downloading {asset_url}")
    bundle_path.write_bytes(request_bytes(asset_url))
    verify_sha256(bundle_path, sha_url)
    installed = copy_bundle_to_install_root(bundle_path, version)
    print(f"Installed jddlab bundle to {installed}")
    return installed


def main(argv: list[str] | None = None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    if sys.version_info < (3, 10):
        print("Python 3.10 or newer is required to install jddlab skills.", file=sys.stderr)
        return 1

    force_update = False
    if argv and argv[0] == "update":
        force_update = True
        argv = argv[1:]

    install_or_update(force_update)
    if force_update and not argv:
        return 0
    if not argv:
        argv = ["--help"]

    installer = current_installer()
    if not installer.exists():
        print(f"Skills installer was not found: {installer}", file=sys.stderr)
        return 1
    return subprocess.run([sys.executable, str(installer), *argv], check=False).returncode


if __name__ == "__main__":
    raise SystemExit(main())
