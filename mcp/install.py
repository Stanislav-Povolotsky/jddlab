#!/usr/bin/env python3
"""Install jddlab MCP connectors into local MCP clients."""

from __future__ import annotations

import argparse
import json
import os
import platform
import shutil
import subprocess
import sys
from pathlib import Path


SERVER_NAME = "jddlab"
REPO_ROOT = Path(__file__).resolve().parents[1]
SERVER_PATH = REPO_ROOT / "mcp" / "server.py"
PYTHON = sys.executable


def server_config() -> dict[str, object]:
    return {"command": PYTHON, "args": [str(SERVER_PATH)]}


def read_json(path: Path, default: dict[str, object]) -> dict[str, object]:
    if not path.exists():
        return default
    return json.loads(path.read_text(encoding="utf-8-sig"))


def write_json(path: Path, data: dict[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def remove_toml_block(text: str, header: str) -> str:
    lines = text.splitlines()
    out: list[str] = []
    skipping = False
    for line in lines:
        stripped = line.strip()
        if stripped == header:
            skipping = True
            continue
        if skipping and stripped.startswith("[") and stripped.endswith("]"):
            skipping = False
        if not skipping:
            out.append(line)
    return "\n".join(out).rstrip() + ("\n" if out else "")


def toml_string(value: str) -> str:
    return json.dumps(value)


def python_command_for_shell() -> str:
    return str(PYTHON)


def claude_desktop_config_path() -> Path:
    system = platform.system()
    if system == "Windows":
        base = os.environ.get("APPDATA")
        if not base:
            raise RuntimeError("APPDATA is not set")
        return Path(base) / "Claude" / "claude_desktop_config.json"
    if system == "Darwin":
        return Path.home() / "Library" / "Application Support" / "Claude" / "claude_desktop_config.json"
    return Path.home() / ".config" / "Claude" / "claude_desktop_config.json"


def vscode_mcp_config_path() -> Path:
    system = platform.system()
    if system == "Windows":
        base = os.environ.get("APPDATA")
        if not base:
            raise RuntimeError("APPDATA is not set")
        return Path(base) / "Code" / "User" / "mcp.json"
    if system == "Darwin":
        return Path.home() / "Library" / "Application Support" / "Code" / "User" / "mcp.json"
    return Path.home() / ".config" / "Code" / "User" / "mcp.json"


def install_claude_desktop(args: argparse.Namespace) -> int:
    path = Path(args.config) if args.config else claude_desktop_config_path()
    data = read_json(path, {"mcpServers": {}})
    servers = data.setdefault("mcpServers", {})
    if not isinstance(servers, dict):
        raise RuntimeError(f"{path} has non-object mcpServers")
    servers[SERVER_NAME] = server_config()
    write_json(path, data)
    print(f"Installed {SERVER_NAME} MCP server into Claude Desktop config: {path}")
    print("Restart Claude Desktop to load the server.")
    return 0


def install_codex(args: argparse.Namespace) -> int:
    path = Path(args.config) if args.config else Path.home() / ".codex" / "config.toml"
    text = path.read_text(encoding="utf-8") if path.exists() else ""
    text = remove_toml_block(text, f"[mcp_servers.{SERVER_NAME}]")
    block = (
        f"\n[mcp_servers.{SERVER_NAME}]\n"
        f"command = {toml_string(PYTHON)}\n"
        f"args = [{toml_string(str(SERVER_PATH))}]\n"
        "startup_timeout_sec = 120\n"
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text.rstrip() + "\n" + block, encoding="utf-8")
    print(f"Installed {SERVER_NAME} MCP server into Codex config: {path}")
    print("Restart Codex to load the server.")
    return 0


def install_vscode(args: argparse.Namespace) -> int:
    path = Path(args.config) if args.config else vscode_mcp_config_path()
    data = read_json(path, {"servers": {}})
    servers = data.setdefault("servers", {})
    if not isinstance(servers, dict):
        raise RuntimeError(f"{path} has non-object servers")
    servers[SERVER_NAME] = {"type": "stdio", **server_config()}
    write_json(path, data)
    print(f"Installed {SERVER_NAME} MCP server into VS Code MCP config: {path}")
    print("In VS Code, run 'MCP: List Servers' or restart VS Code.")
    return 0


def install_claude_cli(args: argparse.Namespace) -> int:
    claude = shutil.which("claude")
    command = [
        "claude",
        "mcp",
        "add",
        "--transport",
        "stdio",
        SERVER_NAME,
        "--",
        PYTHON,
        str(SERVER_PATH),
    ]
    if args.print_only:
        print(" ".join(command))
        return 0
    if not claude:
        print("Claude CLI was not found in PATH. Run this command after installing Claude Code:")
        print(" ".join(command))
        return 1
    completed = subprocess.run(command, check=False)
    return completed.returncode


def remove_claude_desktop(args: argparse.Namespace) -> int:
    path = Path(args.config) if args.config else claude_desktop_config_path()
    data = read_json(path, {"mcpServers": {}})
    servers = data.get("mcpServers", {})
    if isinstance(servers, dict):
        servers.pop(SERVER_NAME, None)
    write_json(path, data)
    print(f"Removed {SERVER_NAME} from Claude Desktop config: {path}")
    return 0


def remove_codex(args: argparse.Namespace) -> int:
    path = Path(args.config) if args.config else Path.home() / ".codex" / "config.toml"
    if path.exists():
        text = remove_toml_block(path.read_text(encoding="utf-8"), f"[mcp_servers.{SERVER_NAME}]")
        path.write_text(text, encoding="utf-8")
    print(f"Removed {SERVER_NAME} from Codex config: {path}")
    return 0


def remove_vscode(args: argparse.Namespace) -> int:
    path = Path(args.config) if args.config else vscode_mcp_config_path()
    data = read_json(path, {"servers": {}})
    servers = data.get("servers", {})
    if isinstance(servers, dict):
        servers.pop(SERVER_NAME, None)
    write_json(path, data)
    print(f"Removed {SERVER_NAME} from VS Code MCP config: {path}")
    return 0


def remove_claude_cli(args: argparse.Namespace) -> int:
    claude = shutil.which("claude")
    command = ["claude", "mcp", "remove", SERVER_NAME]
    if args.print_only:
        print(" ".join(command))
        return 0
    if not claude:
        print("Claude CLI was not found in PATH. Run this command manually if needed:")
        print(" ".join(command))
        return 1
    return subprocess.run(command, check=False).returncode


def doctor(_: argparse.Namespace) -> int:
    failures = 0
    print(f"Python: {sys.version.split()[0]} ({PYTHON})")
    if sys.version_info < (3, 10):
        print("ERROR: Python 3.10 or newer is required.")
        failures += 1
    docker = shutil.which("docker")
    print(f"Docker: {docker or 'not found'}")
    if docker:
        completed = subprocess.run(["docker", "--version"], text=True, capture_output=True, check=False)
        print((completed.stdout or completed.stderr).strip())
        if completed.returncode != 0:
            failures += 1
    else:
        failures += 1
    print(f"MCP server: {SERVER_PATH}")
    if not SERVER_PATH.exists():
        print("ERROR: server.py is missing.")
        failures += 1
    completed = subprocess.run([PYTHON, str(SERVER_PATH), "--list-commands"], text=True, capture_output=True, check=False)
    if completed.returncode == 0:
        print(f"MCP command list: {len(completed.stdout.splitlines())} commands")
    else:
        print("ERROR: MCP server command-list smoke test failed.")
        print(completed.stderr)
        failures += 1
    return 1 if failures else 0


def status(_: argparse.Namespace) -> int:
    print(f"Install root: {REPO_ROOT}")
    print(f"Python: {PYTHON}")
    print(f"Server: {SERVER_PATH}")
    print(f"Claude Desktop config: {safe_path(claude_desktop_config_path)}")
    print(f"Codex config: {Path.home() / '.codex' / 'config.toml'}")
    print(f"VS Code MCP config: {safe_path(vscode_mcp_config_path)}")
    print(f"Claude CLI: {shutil.which('claude') or 'not found'}")
    return 0


def safe_path(fn) -> str:
    try:
        return str(fn())
    except Exception as exc:
        return f"unavailable ({exc})"


INSTALLERS = {
    "claude-cli": install_claude_cli,
    "claude-desktop": install_claude_desktop,
    "codex": install_codex,
    "vscode": install_vscode,
    "copilot": install_vscode,
}

REMOVERS = {
    "claude-cli": remove_claude_cli,
    "claude-desktop": remove_claude_desktop,
    "codex": remove_codex,
    "vscode": remove_vscode,
    "copilot": remove_vscode,
}


def add_client(args: argparse.Namespace) -> int:
    if args.client == "all":
        rc = 0
        for client in ("claude-desktop", "codex", "vscode"):
            rc = INSTALLERS[client](args) or rc
        return rc
    return INSTALLERS[args.client](args)


def remove_client(args: argparse.Namespace) -> int:
    if args.client == "all":
        rc = 0
        for client in ("claude-desktop", "codex", "vscode"):
            rc = REMOVERS[client](args) or rc
        return rc
    return REMOVERS[args.client](args)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Install jddlab MCP connectors.")
    parser.add_argument("--config", help="Override the target client config path.")
    parser.add_argument("--print-only", action="store_true", help="Print external CLI commands instead of running them.")
    subparsers = parser.add_subparsers(dest="command", required=True)
    clients = sorted(set(INSTALLERS) | {"all"})
    add = subparsers.add_parser("add", help="Add jddlab MCP to a client.")
    add.add_argument("client", choices=clients)
    add.set_defaults(func=add_client)
    remove = subparsers.add_parser("remove", help="Remove jddlab MCP from a client.")
    remove.add_argument("client", choices=sorted(set(REMOVERS) | {"all"}))
    remove.set_defaults(func=remove_client)
    subparsers.add_parser("doctor", help="Check local prerequisites.").set_defaults(func=doctor)
    subparsers.add_parser("status", help="Show local MCP installation status.").set_defaults(func=status)
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
