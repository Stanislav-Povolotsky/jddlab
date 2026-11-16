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
import platform
import socket
import subprocess
import sys
import threading
import uuid
from pathlib import Path
from typing import Any


SERVER_NAME = "jddlab-mcp"
SERVER_VERSION = "0.2.0"
DEFAULT_IMAGE = "stanislavpovolotsky/jddlab:latest"
DEFAULT_TIMEOUT_SECONDS = 3600
# Persistent docker volume for tool caches (e.g. blutter's per-Dart-version builds)
CACHE_VOLUME = "jddlab-cache:/var/cache/jddlab"
ADB_SERVER_PORT = 5037

COMMANDS = [
    "APKEditor",
    "adb",
    "androguard",
    "android-unpinner",
    "apk-patcher",
    "apk-sign",
    "apkeditor",
    "apkid",
    "apkscan",
    "apktool",
    "asm-verify",
    "baksmali",
    "blutter",
    "cfr",
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
    "frida",
    "frida-compile",
    "frida-kill",
    "frida-ps",
    "frida-trace",
    "ghidra",
    "ghidra-decompile",
    "hbc-decompiler",
    "hbc-disassembler",
    "hbc-file-parser",
    "ilspycmd",
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
    "mobsfscan",
    "objection",
    "procyon",
    "procyon-decompiler",
    "pyxamstore",
    "quark",
    "simplify",
    "smali",
    "std-apk",
    "vineflower",
    "apksigner",
    "zipalign",
    "keytool",
]

DESCRIPTIONS = {
    "APKEditor": "Edit, decode, build, merge, split, protect, refactor, and inspect Android APK files.",
    "apkeditor": "Lower-case APKEditor alias for Android APK editing workflows.",
    "apkscan": "Scan decompiled/deobfuscated Android files for secrets, endpoints, and other sensitive data.",
    "apktool": "Decode and rebuild Android APK resources and smali projects.",
    "jadx": "Decompile Android APK, DEX, JAR, class, and related inputs to Java sources.",
    "fernflower": "Java bytecode decompiler.",
    "vineflower": "Modern FernFlower fork for Java bytecode decompilation.",
    "procyon": "Procyon Java decompiler and bytecode analysis tool.",
    "procyon-decompiler": "Procyon decompiler command alias.",
    "cfr": "CFR Java decompiler: JAR/class files to Java sources (strong on modern Java constructs).",
    "krakatau-disassemble": "Disassemble Java class files to Krakatau assembly.",
    "krakatau-assemble": "Assemble Krakatau assembly back to Java class files or jars.",
    "krakatau2": "Krakatau v2 Java bytecode assembler/disassembler (dis/asm subcommands).",
    "krak2": "Krakatau v2 short command alias.",
    "apkid": "Identify packers, protectors, obfuscators and compilers used to build an APK/DEX. Run first on an unknown APK.",
    "hbc-file-parser": "Print the header of a React Native Hermes bytecode file (assets/index.android.bundle).",
    "hbc-disassembler": "Disassemble React Native Hermes bytecode (index.android.bundle) to Hermes assembly.",
    "hbc-decompiler": "Decompile React Native Hermes bytecode (index.android.bundle) to pseudo-JavaScript.",
    "blutter": "Flutter reverse engineering: recover Dart classes, functions, object pool and a Frida script from an arm64 libapp.so (first run per Dart version compiles an analyzer and is slow).",
    "pyxamstore": "Unpack/repack Xamarin and .NET MAUI assembly stores (assemblies.blob, libassemblies.<abi>.blob.so) to .NET DLLs.",
    "ilspycmd": "ILSpy command-line .NET decompiler: DLL/EXE (e.g. Xamarin/MAUI assemblies) to C# sources.",
    "mobsfscan": "Static analysis (SAST) of Android/iOS source code, e.g. jadx output, for insecure code patterns.",
    "quark": "Quark-Engine: score Android malware behaviour of an APK/DEX with a built-in rule set.",
    "adb": "Android Debug Bridge. Uses the host ADB server (and its USB/Wi-Fi devices) when one is running.",
    "frida": "Frida CLI. Non-interactive use: -q (quiet) with -l script.js / -e code and -t <seconds>.",
    "frida-ps": "List processes/applications on a device (-U for the ADB device, -a apps, -i installed).",
    "frida-trace": "Trace function calls on a device (use a timeout; handlers are written to ./__handlers__).",
    "frida-kill": "Kill a process on a device.",
    "frida-compile": "Compile a Frida TypeScript/ES module agent into a single script.",
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
    "d2j-smali": "dex2jar's smali assembler: smali files to DEX.",
    "d2j-baksmali": "dex2jar's baksmali disassembler: DEX to smali files.",
    "extract_jni": "Extract JNI/native library artifacts from Android packages.",
    "apksigner": "Sign and verify Android APK files using v1/v2/v3/v4 signing schemes (Android SDK Build Tools).",
    "zipalign": "Align uncompressed data in an Android APK to 4-byte boundaries (Android SDK Build Tools).",
    "keytool": "Java KeyStore management tool: generate RSA key pairs and self-signed certificates for APK signing keystores.",
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


def host_adb_server_running() -> bool:
    try:
        with socket.create_connection(("127.0.0.1", ADB_SERVER_PORT), timeout=0.3):
            return True
    except OSError:
        return False


def adb_docker_args() -> list[str]:
    """Docker arguments that connect the container to the host ADB server.

    Every MCP call is a separate `docker run --rm`, so an ADB server started inside
    the container (and its `adb connect`) is lost after each call. Using the host
    ADB server keeps devices (USB or Wi-Fi) connected across calls, which is what
    makes adb/frida/objection usable through MCP. Controlled by environment
    variables of the MCP server process:
      JDDLAB_ADB=auto (default: use the host server if it is running) | host | container
      JDDLAB_ADB_SERVER=<host>:<port>  an explicit ADB server to use
    """
    mode = os.environ.get("JDDLAB_ADB", "auto").strip().lower()
    explicit = os.environ.get("JDDLAB_ADB_SERVER", "").strip()
    is_linux = platform.system() == "Linux"
    if mode in ("container", "off", "none", "0"):
        return []
    if explicit:
        args = ["-e", f"JDDLAB_ADB_SERVER={explicit}"]
        return args + (["--add-host=host.docker.internal:host-gateway"] if is_linux else [])
    if mode != "host" and not host_adb_server_running():
        return []
    if is_linux:
        # Native Docker: the host server listens on the host's loopback only, which
        # the container can reach with host networking.
        return ["--network=host"]
    # Docker Desktop (Windows/macOS) proxies host.docker.internal to the host's loopback.
    return ["-e", f"JDDLAB_ADB_SERVER=host.docker.internal:{ADB_SERVER_PORT}"]


def build_docker_command(
    command: str,
    args: list[str],
    workdir: str | None,
    input_paths: list[str],
    output_paths: list[str],
    extra_mounts: list[dict[str, str]],
    docker_image: str,
    interactive: bool,
    container_name: str | None = None,
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
    if container_name:
        docker_cmd.extend(["--name", container_name])
    docker_cmd.extend(["--rm", "-v", f"{mount_root}:/work", "-v", CACHE_VOLUME])
    docker_cmd.extend(adb_docker_args())
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
    # Named, so that the container can be killed on timeout: killing the `docker`
    # client alone leaves the container (e.g. a frida-trace session) running.
    container_name = f"jddlab-mcp-{uuid.uuid4().hex[:12]}"

    docker_cmd, mount_root, container_args = build_docker_command(
        command=command,
        args=raw_args,
        workdir=workdir,
        input_paths=input_paths,
        output_paths=output_paths,
        extra_mounts=extra_mounts,
        docker_image=docker_image,
        interactive=interactive,
        container_name=container_name,
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
        subprocess.run(["docker", "rm", "-f", container_name], capture_output=True, check=False)
        return {
            "command": command,
            "args": container_args,
            "docker_command": docker_cmd,
            "mount_root": str(mount_root),
            "exit_code": 124,
            "stdout": exc.stdout or "",
            "stderr": f"Timed out after {timeout} seconds.\n{exc.stderr or ''}",
        }


def run_jddlab_update(arguments: dict[str, Any]) -> dict[str, Any]:
    docker_image = str(arguments.get("docker_image", DEFAULT_IMAGE))
    timeout = int(arguments.get("timeout_seconds", 600))
    docker_cmd = ["docker", "pull", docker_image]
    try:
        completed = subprocess.run(
            docker_cmd,
            text=True,
            capture_output=True,
            timeout=timeout,
            check=False,
        )
        return {
            "command": "docker pull",
            "docker_image": docker_image,
            "exit_code": completed.returncode,
            "stdout": completed.stdout,
            "stderr": completed.stderr,
        }
    except subprocess.TimeoutExpired as exc:
        return {
            "command": "docker pull",
            "docker_image": docker_image,
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
        },
        {
            "name": "jddlab_update",
            "description": (
                "Pull the latest jddlab Docker image from Docker Hub "
                "(`docker pull stanislavpovolotsky/jddlab:latest`). "
                "Run this to update the local image to the newest version."
            ),
            "inputSchema": {
                "type": "object",
                "properties": {
                    "docker_image": {
                        "type": "string",
                        "default": DEFAULT_IMAGE,
                        "description": "Image to pull. Defaults to the standard jddlab image.",
                    },
                    "timeout_seconds": {
                        "type": "integer",
                        "minimum": 1,
                        "default": 1800,
                        "description": "Maximum time to wait for the pull (seconds).",
                    },
                },
                "required": [],
            },
        },
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
                    "capabilities": {"tools": {}, "prompts": {}, "resources": {}},
                    "serverInfo": {"name": SERVER_NAME, "version": SERVER_VERSION},
                }
            elif method == "notifications/initialized":
                return None
            elif method == "tools/list":
                result = {"tools": self.tools}
            elif method == "resources/list":
                result = {"resources": []}
            elif method == "resources/templates/list":
                result = {"resourceTemplates": []}
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
        elif name == "jddlab_update":
            result = run_jddlab_update(arguments)
        else:
            command = next((cmd for cmd in COMMANDS if tool_name_for_command(cmd) == name), None)
            if command is None:
                raise ValueError(f"Unknown tool: {name}")
            result = run_jddlab(arguments, forced_command=command)
        return {"content": text_content(json.dumps(result, indent=2, ensure_ascii=False)), "isError": result["exit_code"] != 0}


def read_message() -> dict[str, Any] | None:
    # MCP's stdio transport is newline-delimited JSON: each message is a single
    # line beginning with '{' (or '[') and terminated by '\n'. Detect that and
    # parse it directly; fall back to LSP-style Content-Length header framing for
    # any client that still uses it.
    line = sys.stdin.buffer.readline()
    while line in (b"\n", b"\r\n"):  # skip stray blank lines between messages
        line = sys.stdin.buffer.readline()
    if not line:
        return None
    if line.lstrip()[:1] in (b"{", b"["):
        return json.loads(line.decode("utf-8"))

    headers: dict[str, str] = {}
    while True:
        text = line.decode("ascii").strip()
        if not text:
            break
        key, _, value = text.partition(":")
        headers[key.lower()] = value.strip()
        line = sys.stdin.buffer.readline()
        if not line:
            return None
    length = int(headers.get("content-length", "0"))
    if length <= 0:
        return None
    body = sys.stdin.buffer.read(length)
    return json.loads(body.decode("utf-8"))


_write_lock = threading.Lock()


def write_message(message: dict[str, Any]) -> None:
    # Newline-delimited JSON per the MCP stdio transport. json.dumps produces no
    # embedded newlines, so a single trailing '\n' frames the message.
    body = json.dumps(message, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    with _write_lock:
        sys.stdout.buffer.write(body)
        sys.stdout.buffer.write(b"\n")
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
