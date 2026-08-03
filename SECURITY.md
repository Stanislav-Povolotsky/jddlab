# Security Policy

## Scope

jddlab is a Docker image and launcher that bundles third-party reverse-engineering
tools. This policy covers the **original jddlab code** in this repository (the
`jddlab` / `jddlab.cmd` launchers, the `scripts/` build tooling, the `mcp/` server,
and the `skills/`). Vulnerabilities in the **bundled third-party tools** (Apktool,
jadx, Ghidra, dex2jar, etc.) should be reported to their respective upstream
projects - see `/usr/local/jddlab/software-list.txt` (`jddlab versions`) for links.

## Reporting a vulnerability

Please report security issues **privately**, not via public GitHub issues:

- Preferred: open a [GitHub private security advisory](https://github.com/Stanislav-Povolotsky/jddlab/security/advisories/new).
- Alternatively, contact the maintainer through the profile on
  https://github.com/Stanislav-Povolotsky.

Please include reproduction steps, the affected component, and the image tag or
launcher commit you were using. You will normally get an initial response within a
few days.

## Security model & things to be aware of

jddlab is a toolkit for analyzing **untrusted** and potentially malicious binaries
(APKs, DEX/JARs, native `.so` libraries). Keep the following in mind:

- **Run untrusted samples inside the container, not on the host.** The container
  boundary is the primary isolation layer. Do not extract and execute malware on
  your host.
- **`/work` is mounted read-write.** The launcher maps your current directory into
  the container as `/work`. Anything the tools (or a malicious sample that achieves
  code execution) write goes to your real filesystem. Run jddlab from a dedicated
  working directory, not from your home or a source-tree root.
- **Preinstalled ADB keys.** The image ships with a default ADB key pair so that
  wireless debugging works out of the box. This means **anyone with network access
  to a device you have connected can authenticate to it.** For anything beyond
  throwaway lab devices, mount your own keys:
  ```
  docker run -it --rm -v "$HOME/.android:/root/.android" -v "$PWD:/work" \
      stanislavpovolotsky/jddlab:latest
  ```
- **Some tools reach the network.** For example `apk-patcher` downloads Frida
  gadgets and `objection` may fetch releases. Review a tool's behavior before
  running it in an isolated/offline environment.
- **The MCP server executes Docker commands on your behalf.** When you expose the
  MCP server to an AI client, that client can run any bundled jddlab command
  against paths you make available. Only connect it to clients you trust and scope
  the mounted directories.
- **Do not run the container with `--privileged` or the host Docker socket** unless
  you fully understand the consequences; jddlab does not require them.

## Supported versions

Only the latest published image (`stanislavpovolotsky/jddlab:latest`) and the
latest launcher/MCP release receive fixes. Please update (`jddlab update`) before
reporting an issue.
