#!/usr/bin/env python3
"""MCP server for running jddlab tools through Docker.

The server intentionally has no third-party Python dependencies. It implements
the MCP stdio transport directly and exposes one wrapper tool per jddlab command
plus a generic `jddlab_run` escape hatch.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import threading
from pathlib import Path
from typing import Any


SERVER_NAME = "jddlab-mcp"
SERVER_VERSION = "0.1.0"
DEFAULT_IMAGE = "stanislavpovolotsky/jddlab:latest"
DEFAULT_TIMEOUT_SECONDS = 3600

COMMANDS = [
    "APKEditor",
    "androguard",
    "android-unpinner",
    "apk-patcher",
    "apk-sign",
    "apkeditor",
    "apktool",
    "asm-verify",
    "baksmali",
    "class-version-switch",
    "d2j-apk-sign",
    "d2j-asm-verify",
    "d2j-baksmali",
    "d2j-class-version-switch",
    "d2j-decrypt-string",
    "d2j-dex-recompute-checksum",
    "d2j-dex-weaver",
    "d2j-dex2jar",
    "d2j-dex2smali",
    "d2j-jar-access",
    "d2j-jar-weaver",
    "d2j-jar2dex",
    "d2j-jar2jasmin",
    "d2j-jasmin2jar",
    "d2j-smali",
    "d2j-std-apk",
    "decrypt-string",
    "dex-recompute-checksum",
    "dex-weaver",
    "dex2jar",
    "dex2smali",
    "enjarify",
    "extract_jni",
    "fernflower",
    "ghidra",
    "ghidra-decompile",
    "jadx",
    "jar-access",
    "jar-weaver",
    "jar2dex",
    "jar2jasmin",
    "jasmin2jar",
    "java-deobfuscator",
    "java-deobfuscator-detect",
    "krak2",
    "krakatau-assemble",
    "krakatau-disassemble",
    "krakatau2",
    "objection",
    "procyon",
    "procyon-decompiler",
    "simplify",
    "smali",
    "std-apk",
    "vineflower",
]

DESCRIPTIONS = {
    "APKEditor": "Edit, decode, build, merge, split, protect, refactor, and inspect Android APK files.",
    "apkeditor": "Lower-case APKEditor alias for Android APK editing workflows.",
    "apktool": "Decode and rebuild Android APK resources and smali projects.",
    "jadx": "Decompile Android APK, DEX, JAR, class, and related inputs to Java sources.",
    "fernflower": "Java bytecode decompiler.",
    "vineflower": "Modern FernFlower fork for Java bytecode decompilation.",
    "procyon": "Procyon Java decompiler and bytecode analysis tool.",
    "procyon-decompiler": "Procyon decompiler command alias.",
    "krakatau-disassemble": "Disassemble Java class files to Krakatau assembly.",
    "krakatau-assemble": "Assemble Krakatau assembly back to Java class files or jars.",
    "krakatau2": "Krakatau v2 command-line interface.",
    "krak2": "Krakatau v2 short command alias.",
    "androguard": "Android reverse engineering toolkit for APK, DEX, analysis, and signing commands.",
    "objection": "Runtime mobile exploration and APK patching toolkit.",
    "ghidra": "Ghidra headless analyzer.",
    "ghidra-decompile": "Decompile native binaries with Ghidra.",
    "android-unpinner": "Patch APKs to disable Android certificate pinning.",
    "apk-patcher": "Patch APK files, commonly to inject Frida gadget.",
    "enjarify": "Translate Dalvik bytecode to equivalent Java bytecode.",
    "simplify": "Android virtual machine and deobfuscator.",
    "java-deobfuscator": "Run java-deobfuscator with a YAML config.",
    "java-deobfuscator-detect": "Detect java-deobfuscator transformers for a jar.",
    "smali": "Assemble smali files into DEX bytecode.",
    "baksmali": "Disassemble DEX bytecode into smali files.",
    "extract_jni": "Extract JNI/native library artifacts from Android packages.",
}

DEX2JAR_DESCRIPTIONS = {
    "apk-sign": "Sign APK files with dex2jar/apk signing helpers.",
    "asm-verify": "Verify Java bytecode with ASM.",
    "class-version-switch": "Switch Java class file version values.",
    "decrypt-string": "Run dex2jar string decryption helper.",
    "dex-recompute-checksum": "Recompute DEX checksums.",
    "dex-weaver": "Weave DEX files.",
    "dex2jar": "Convert DEX/APK files to JAR files.",
    "dex2smali": "Convert DEX files to smali text.",
    "jar-access": "Inspect or rewrite JAR/class access flags.",
    "jar-weaver": "Weave Java JAR/class files.",
    "jar2dex": "Convert JAR/class files to DEX.",
    "jar2jasmin": "Convert JAR/class files to Jasmin assembly.",
    "jasmin2jar": "Assemble Jasmin sources to JAR/class files.",
    "std-apk": "Normalize/standardize APK files with dex2jar helpers.",
}

for _name, _description in DEX2JAR_DESCRIPTIONS.items():
    DESCRIPTIONS.setdefault(_name, _description)
    DESCRIPTIONS.setdefault(f"d2j-{_name}", _description)


def tool_name_for_command(command: str) -> str:
    return f"jddlab_{command.replace('-', '_')}"


def repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def load_tool_docs() -> dict[str, str]:
    docs: dict[str, str] = {}
    docs_dir = repo_root() / "tools"
    for command in COMMANDS:
        path = docs_dir / f"{command}.md"
        if command == "apkeditor" and not path.exists():
            path = docs_dir / "APKEditor.md"
        if path.exists():
            docs[command] = path.read_text(encoding="utf-8")
    return docs


def normalize_path(value: str | None) -> Path | None:
    if not value:
        return None
    return Path(value).expanduser().resolve()


def common_path(paths: list[Path]) -> Path:
    if not paths:
        return Path.cwd().resolve()
    existing: list[Path] = []
    for path in paths:
        existing.append(path if path.is_dir() else path.parent)
    try:
        return Path(os.path.commonpath([str(path) for path in existing])).resolve()
    except ValueError:
        return existing[0].resolve()


def to_container_path(path: Path, mount_root: Path) -> str:
    try:
        relative = path.resolve().relative_to(mount_root)
    except ValueError:
        return str(path)
    return "/work" if str(relative) == "." else f"/work/{relative.as_posix()}"


def to_container_arg(arg: str, mount_root: Path, path_map: dict[str, str], base_dir: Path) -> str:
    if arg in path_map:
        return path_map[arg]
    if arg.startswith("-") or arg.startswith("@"):
        return arg
    looks_like_path = any(separator in arg for separator in ("/", "\\")) or Path(arg).suffix != ""
    if not looks_like_path:
        return arg
    maybe_path = Path(arg).expanduser()
    if not maybe_path.is_absolute():
        maybe_path = (base_dir / maybe_path).resolve()
    else:
        maybe_path = maybe_path.resolve()
    if not maybe_path.exists() and arg not in path_map:
        return arg
    return to_container_path(maybe_path, mount_root)


def build_docker_command(
    command: str,
    args: list[str],
    workdir: str | None,
    input_paths: list[str],
    output_paths: list[str],
    extra_mounts: list[dict[str, str]],
    docker_image: str,
    interactive: bool,
) -> tuple[list[str], Path, list[str]]:
    paths = [path for path in (normalize_path(value) for value in [workdir, *input_paths, *output_paths]) if path]
    mount_root = common_path(paths) if paths else Path.cwd().resolve()
    base_dir = normalize_path(workdir) or mount_root
    path_map: dict[str, str] = {}
    for original in [workdir, *input_paths, *output_paths]:
        normalized = normalize_path(original)
        if not original or not normalized:
            continue
        container_path = to_container_path(normalized, mount_root)
        path_map[str(original)] = container_path
        path_map[str(original).rstrip("/\\")] = container_path
        path_map[str(normalized)] = container_path
    container_args = [to_container_arg(str(arg), mount_root, path_map, base_dir) for arg in args]
    docker_cmd = ["docker", "run"]
    if interactive:
        docker_cmd.append("-it")
    docker_cmd.extend(["--rm", "-v", f"{mount_root}:/work"])
    for mount in extra_mounts:
        host = normalize_path(mount.get("host"))
        container = mount.get("container")
        mode = mount.get("mode", "rw")
        if not host or not container:
            raise ValueError("extra_mounts entries require host and container")
        docker_cmd.extend(["-v", f"{host}:{container}:{mode}"])
    docker_cmd.extend([docker_image, command, *container_args])
    return docker_cmd, mount_root, container_args


def run_jddlab(arguments: dict[str, Any], forced_command: str | None = None) -> dict[str, Any]:
    command = forced_command or str(arguments.get("command", ""))
    if command not in COMMANDS:
        raise ValueError(f"Unsupported command: {command}")

    raw_args = arguments.get("args", [])
    if not isinstance(raw_args, list) or not all(isinstance(arg, str) for arg in raw_args):
        raise ValueError("args must be a list of strings")

    input_paths = arguments.get("input_paths", [])
    output_paths = arguments.get("output_paths", [])
    extra_mounts = arguments.get("extra_mounts", [])
    if not isinstance(input_paths, list) or not all(isinstance(path, str) for path in input_paths):
        raise ValueError("input_paths must be a list of strings")
    if not isinstance(output_paths, list) or not all(isinstance(path, str) for path in output_paths):
        raise ValueError("output_paths must be a list of strings")
    if not isinstance(extra_mounts, list) or not all(isinstance(mount, dict) for mount in extra_mounts):
        raise ValueError("extra_mounts must be a list of objects")

    timeout = int(arguments.get("timeout_seconds", DEFAULT_TIMEOUT_SECONDS))
    docker_image = str(arguments.get("docker_image", DEFAULT_IMAGE))
    interactive = bool(arguments.get("interactive", False))
    workdir = arguments.get("workdir")

    docker_cmd, mount_root, container_args = build_docker_command(
        command=command,
        args=raw_args,
        workdir=workdir,
        input_paths=input_paths,
        output_paths=output_paths,
        extra_mounts=extra_mounts,
        docker_image=docker_image,
        interactive=interactive,
    )

    try:
        completed = subprocess.run(
            docker_cmd,
            cwd=str(mount_root),
            text=True,
            capture_output=True,
            timeout=timeout,
            check=False,
        )
        return {
            "command": command,
            "args": container_args,
            "docker_command": docker_cmd,
            "mount_root": str(mount_root),
            "exit_code": completed.returncode,
            "stdout": completed.stdout,
            "stderr": completed.stderr,
        }
    except subprocess.TimeoutExpired as exc:
        return {
            "command": command,
            "args": container_args,
            "docker_command": docker_cmd,
            "mount_root": str(mount_root),
            "exit_code": 124,
            "stdout": exc.stdout or "",
            "stderr": f"Timed out after {timeout} seconds.\n{exc.stderr or ''}",
        }


def tool_schema(command: str | None = None) -> dict[str, Any]:
    properties: dict[str, Any] = {
        "args": {
            "type": "array",
            "items": {"type": "string"},
            "description": "Command arguments exactly as they would be passed after the jddlab command name.",
            "default": [],
        },
        "workdir": {
            "type": "string",
            "description": "Host directory to mount as /work. If omitted, the server infers it from input_paths and output_paths, then falls back to its current directory.",
        },
        "input_paths": {
            "type": "array",
            "items": {"type": "string"},
            "description": "Host input files/directories used to infer the Docker mount root and rewrite path arguments to /work paths.",
            "default": [],
        },
        "output_paths": {
            "type": "array",
            "items": {"type": "string"},
            "description": "Host output files/directories used to infer the Docker mount root and rewrite path arguments to /work paths.",
            "default": [],
        },
        "extra_mounts": {
            "type": "array",
            "description": "Additional Docker mounts, for example {'host': '~/.android', 'container': '/root/.android', 'mode': 'rw'}.",
            "items": {
                "type": "object",
                "properties": {
                    "host": {"type": "string"},
                    "container": {"type": "string"},
                    "mode": {"type": "string", "default": "rw"},
                },
                "required": ["host", "container"],
            },
            "default": [],
        },
        "timeout_seconds": {
            "type": "integer",
            "minimum": 1,
            "default": DEFAULT_TIMEOUT_SECONDS,
            "description": "Maximum runtime for the Docker command.",
        },
        "docker_image": {
            "type": "string",
            "default": DEFAULT_IMAGE,
            "description": "Docker image to run.",
        },
        "interactive": {
            "type": "boolean",
            "default": False,
            "description": "Add -it to docker run. Keep false for most MCP clients because stdio is captured.",
        },
    }
    required: list[str] = []
    if command is None:
        properties["command"] = {
            "type": "string",
            "enum": COMMANDS,
            "description": "jddlab command to run.",
        }
        required.append("command")
    return {"type": "object", "properties": properties, "required": required}


def list_tools(docs: dict[str, str]) -> list[dict[str, Any]]:
    tools = [
        {
            "name": "jddlab_run",
            "description": "Run any supported jddlab command through Docker.",
            "inputSchema": tool_schema(None),
        }
    ]
    for command in COMMANDS:
        description = DESCRIPTIONS.get(command, f"Run `{command}` from the jddlab Docker image.")
        if command in docs:
            doc_name = "APKEditor" if command == "apkeditor" else command
            description = f"{description}\n\nDocumentation: tools/{doc_name}.md"
        tools.append(
            {
                "name": tool_name_for_command(command),
                "description": description,
                "inputSchema": tool_schema(command),
            }
        )
    return tools


def text_content(text: str) -> list[dict[str, str]]:
    return [{"type": "text", "text": text}]


class McpServer:
    def __init__(self) -> None:
        self.docs = load_tool_docs()
        self.tools = list_tools(self.docs)
        self.prompts_text = (Path(__file__).resolve().parent / "prompts.md").read_text(encoding="utf-8")

    def handle(self, message: dict[str, Any]) -> dict[str, Any] | None:
        method = message.get("method")
        message_id = message.get("id")
        try:
            if method == "initialize":
                result = {
                    "protocolVersion": "2024-11-05",
                    "capabilities": {"tools": {}, "prompts": {}},
                    "serverInfo": {"name": SERVER_NAME, "version": SERVER_VERSION},
                }
            elif method == "notifications/initialized":
                return None
            elif method == "tools/list":
                result = {"tools": self.tools}
            elif method == "tools/call":
                params = message.get("params", {})
                result = self.call_tool(str(params.get("name", "")), params.get("arguments", {}) or {})
            elif method == "prompts/list":
                result = {
                    "prompts": [
                        {
                            "name": "jddlab_reverse_engineering_workflow",
                            "description": "Plan a jddlab-based Android or Java reverse engineering workflow.",
                            "arguments": [
                                {"name": "target", "description": "APK, DEX, JAR, class, or native library target.", "required": True},
                                {"name": "goal", "description": "What the user wants to inspect, patch, or recover.", "required": True},
                            ],
                        }
                    ]
                }
            elif method == "prompts/get":
                params = message.get("params", {})
                args = params.get("arguments", {}) or {}
                result = {
                    "description": "jddlab reverse engineering workflow prompt",
                    "messages": [
                        {
                            "role": "user",
                            "content": {
                                "type": "text",
                                "text": self.prompts_text.replace("{target}", str(args.get("target", "<target>"))).replace(
                                    "{goal}", str(args.get("goal", "<goal>"))
                                ),
                            },
                        }
                    ],
                }
            else:
                raise ValueError(f"Unsupported method: {method}")
            return {"jsonrpc": "2.0", "id": message_id, "result": result}
        except Exception as exc:
            return {
                "jsonrpc": "2.0",
                "id": message_id,
                "error": {"code": -32603, "message": str(exc)},
            }

    def call_tool(self, name: str, arguments: dict[str, Any]) -> dict[str, Any]:
        if name == "jddlab_run":
            result = run_jddlab(arguments)
        else:
            command = next((cmd for cmd in COMMANDS if tool_name_for_command(cmd) == name), None)
            if command is None:
                raise ValueError(f"Unknown tool: {name}")
            result = run_jddlab(arguments, forced_command=command)
        return {"content": text_content(json.dumps(result, indent=2, ensure_ascii=False)), "isError": result["exit_code"] != 0}


def read_message() -> dict[str, Any] | None:
    headers: dict[str, str] = {}
    while True:
        line = sys.stdin.buffer.readline()
        if not line:
            return None
        line = line.decode("ascii").strip()
        if not line:
            break
        key, _, value = line.partition(":")
        headers[key.lower()] = value.strip()
    length = int(headers.get("content-length", "0"))
    if length <= 0:
        return None
    body = sys.stdin.buffer.read(length)
    return json.loads(body.decode("utf-8"))


_write_lock = threading.Lock()


def write_message(message: dict[str, Any]) -> None:
    body = json.dumps(message, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    header = f"Content-Length: {len(body)}\r\n\r\n".encode("ascii")
    with _write_lock:
        sys.stdout.buffer.write(header)
        sys.stdout.buffer.write(body)
        sys.stdout.buffer.flush()


def main() -> int:
    parser = argparse.ArgumentParser(description="Run the jddlab MCP stdio server.")
    parser.add_argument("--list-commands", action="store_true", help="Print supported jddlab commands and exit.")
    args = parser.parse_args()
    if args.list_commands:
        print("\n".join(COMMANDS))
        return 0

    server = McpServer()
    while True:
        message = read_message()
        if message is None:
            return 0
        response = server.handle(message)
        if response is not None and "id" in message:
            write_message(response)


if __name__ == "__main__":
    raise SystemExit(main())
