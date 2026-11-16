#!/usr/bin/env python3
"""MCP smoke test: drive mcp/server.py over stdio against a jddlab image.

Checks that:
  * the MCP command list, mcp/tools.json and tools/*.md docs are consistent;
  * every MCP command exists in the image;
  * real tool calls work end-to-end through MCP (host path rewriting, output on
    the host, stdout capture), including the newer tools;
  * a timed-out call kills its container.

Usage: python scripts/workflow/mcp-smoke-test.py [--image IMAGE]
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SERVER = REPO / "mcp" / "server.py"
FIXTURES_IN_IMAGE = "/usr/local/jddlab/tests/fixtures"


class McpClient:
    def __init__(self) -> None:
        self.proc = subprocess.Popen(
            [sys.executable, str(SERVER)],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            text=True,
            encoding="utf-8",
        )
        self.next_id = 1

    def request(self, method: str, params: dict | None = None) -> dict:
        message_id = self.next_id
        self.next_id += 1
        message = {"jsonrpc": "2.0", "id": message_id, "method": method, "params": params or {}}
        self.proc.stdin.write(json.dumps(message) + "\n")
        self.proc.stdin.flush()
        response = json.loads(self.proc.stdout.readline())
        if "error" in response:
            raise RuntimeError(f"{method}: {response['error']}")
        return response["result"]

    def call(self, tool: str, arguments: dict) -> dict:
        result = self.request("tools/call", {"name": tool, "arguments": arguments})
        return json.loads(result["content"][0]["text"])

    def close(self) -> None:
        self.proc.stdin.close()
        self.proc.wait(timeout=10)


failures: list[str] = []


def check(name: str, condition: bool, details: str = "") -> None:
    print(f"{'PASS' if condition else 'FAIL'} {name}")
    if not condition:
        failures.append(name)
        if details:
            print("    " + details.strip().replace("\n", "\n    ")[-3000:])


def output_of(result: dict) -> str:
    return (result.get("stdout") or "") + (result.get("stderr") or "")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--image", default="stanislavpovolotsky/jddlab:latest")
    args = parser.parse_args()
    image = args.image

    sys.path.insert(0, str(SERVER.parent))
    import server  # noqa: E402  (the MCP server module itself)

    # --- static consistency -------------------------------------------------
    manifest = json.loads((REPO / "mcp" / "tools.json").read_text(encoding="utf-8"))
    manifest_commands = [tool["command"] for tool in manifest["tools"]]
    check("tools.json lists exactly the server commands",
          sorted(manifest_commands) == sorted(server.COMMANDS),
          f"only in server: {sorted(set(server.COMMANDS) - set(manifest_commands))}, "
          f"only in tools.json: {sorted(set(manifest_commands) - set(server.COMMANDS))}")
    missing_docs = [t["docs"] for t in manifest["tools"] if not (REPO / t["docs"]).is_file()]
    check("every command has a tools/*.md doc", not missing_docs, f"missing: {missing_docs}")
    missing_descriptions = [c for c in server.COMMANDS if c not in server.DESCRIPTIONS]
    check("every command has a description", not missing_descriptions, f"missing: {missing_descriptions}")

    # --- every command exists in the image -----------------------------------
    probe = " ".join(f"command -v {c} >/dev/null || echo MISSING:{c};" for c in server.COMMANDS)
    completed = subprocess.run(["docker", "run", "--rm", image, "sh", "-c", probe],
                               capture_output=True, text=True)
    missing = [line.split(":", 1)[1] for line in completed.stdout.splitlines() if line.startswith("MISSING:")]
    check("every MCP command exists in the image", completed.returncode == 0 and not missing,
          f"missing: {missing}\n{completed.stderr}")

    # --- protocol + real calls -------------------------------------------------
    client = McpClient()
    work = Path(tempfile.mkdtemp(prefix="jddlab-mcp-test-"))
    try:
        info = client.request("initialize", {"protocolVersion": "2024-11-05", "capabilities": {},
                                             "clientInfo": {"name": "mcp-smoke-test", "version": "1"}})
        check("initialize", info["serverInfo"]["name"] == "jddlab-mcp")
        tools = {tool["name"] for tool in client.request("tools/list")["tools"]}
        expected = {server.tool_name_for_command(c) for c in server.COMMANDS} | {"jddlab_run", "jddlab_update"}
        check("tools/list", expected <= tools, f"missing: {sorted(expected - tools)}")

        apk = work / "simple.apk"
        shutil.copy(REPO / "example" / "simple.apk", apk)
        base = {"docker_image": image, "workdir": str(work), "timeout_seconds": 900}

        r = client.call("jddlab_apkid", {**base, "args": [str(apk)], "input_paths": [str(apk)]})
        check("apkid via MCP", r["exit_code"] == 0 and "compiler" in output_of(r), output_of(r))

        out = work / "jadx-out"
        r = client.call("jddlab_jadx", {**base, "args": ["-q", "-d", str(out), str(apk)],
                                        "input_paths": [str(apk)], "output_paths": [str(out)]})
        java = out / "sources" / "com" / "example" / "simple" / "MainActivity.java"
        check("jadx via MCP writes sources on the host",
              r["exit_code"] == 0 and java.is_file() and "class MainActivity" in java.read_text(), output_of(r))

        jar = work / "simple.jar"
        r = client.call("jddlab_d2j_dex2jar", {**base, "args": ["-f", "-o", str(jar), str(apk)],
                                               "input_paths": [str(apk)], "output_paths": [str(jar)]})
        check("dex2jar via MCP", r["exit_code"] == 0 and jar.is_file(), output_of(r))
        cfr_out = work / "cfr-out"
        r = client.call("jddlab_cfr", {**base, "args": [str(jar), "--outputdir", str(cfr_out)],
                                       "input_paths": [str(jar)], "output_paths": [str(cfr_out)]})
        check("cfr via MCP", r["exit_code"] == 0 and (cfr_out / "com/example/simple/MainActivity.java").is_file(),
              output_of(r))

        r = client.call("jddlab_hbc_decompiler", {**base, "args": [f"{FIXTURES_IN_IMAGE}/index.android.bundle"]})
        check("hermes-dec via MCP", r["exit_code"] == 0 and "JDDLAB-SECRET-KEY-1234" in output_of(r), output_of(r))

        r = client.call("jddlab_ilspycmd", {**base, "args": [f"{FIXTURES_IN_IMAGE}/dotnet/Fixture.dll"]})
        check("ilspycmd via MCP", r["exit_code"] == 0 and "class Unsafe" in output_of(r), output_of(r))

        insecure = work / "insecure-src"
        shutil.copytree(REPO / "tests" / "fixtures" / "src" / "mobsfscan", insecure)
        r = client.call("jddlab_mobsfscan", {**base, "args": ["--json", str(insecure)], "input_paths": [str(insecure)]})
        check("mobsfscan via MCP", '"weak_hash"' in r["stdout"], output_of(r))

        r = client.call("jddlab_frida_ps", {**base, "args": []})
        check("frida-ps via MCP", r["exit_code"] == 0 and "PID" in r["stdout"], output_of(r))

        r = client.call("jddlab_adb", {**base, "args": ["version"]})
        check("adb via MCP", r["exit_code"] == 0 and "Android Debug Bridge" in r["stdout"], output_of(r))

        r = client.call("jddlab_run", {**base, "command": "blutter", "args": ["--help"]})
        check("blutter via jddlab_run", "--dart-version" in output_of(r), output_of(r))

        # Timeout: the container must be killed, not just the docker client.
        started = time.time()
        r = client.call("jddlab_adb", {**base, "args": ["wait-for-device"], "timeout_seconds": 5})
        time.sleep(2)
        leftovers = subprocess.run(["docker", "ps", "-q", "--filter", "name=jddlab-mcp-"],
                                   capture_output=True, text=True).stdout.split()
        check("timed-out call is killed", r["exit_code"] == 124 and not leftovers and time.time() - started < 60,
              f"exit_code={r['exit_code']}, leftover containers: {leftovers}")
    finally:
        client.close()
        shutil.rmtree(work, ignore_errors=True)

    print()
    print(f"FAILED: {failures}" if failures else "All MCP checks passed")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
