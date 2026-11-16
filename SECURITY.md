# Security Policy

## Scope

jddlab is a Docker image and launcher that bundles third-party reverse-engineering
tools. This policy covers the original jddlab code in this repository: the
`jddlab` / `jddlab.cmd` launchers, the `scripts/` build tooling, the `mcp/` server
and the `skills/`. Report vulnerabilities in the bundled third-party tools (Apktool,
jadx, Ghidra, dex2jar and others) to their upstream projects; the links are in
`/usr/local/jddlab/software-list.txt` (`jddlab versions`).

## Reporting a vulnerability

Report security issues privately, not in public GitHub issues:

- Preferred: open a [GitHub private security advisory](https://github.com/Stanislav-Povolotsky/jddlab/security/advisories/new).
- Alternatively, contact the maintainer through the profile on
  https://github.com/Stanislav-Povolotsky.

Please include reproduction steps, the affected component, and the image tag or
launcher commit you were using. You will normally get an initial response within a
few days.

## Security model & things to be aware of

jddlab is used to analyze untrusted and possibly malicious binaries (APKs,
DEX/JARs, native `.so` libraries).

- Run untrusted samples inside the container, not on the host. The container is
  the main isolation layer; do not extract and execute malware on your host.
- `/work` is mounted read-write. The launcher maps your current directory into the
  container as `/work`, so whatever the tools write (or a malicious sample that
  gets code execution) lands on your real filesystem. Run jddlab from a dedicated
  working directory, not from your home directory or the root of a source tree.
- The image ships a default ADB key pair so that wireless debugging from inside the
  container works without setup. The key is the same in every copy of the public
  image, so anyone with network access to a device that authorized it can connect
  to that device. For anything beyond throwaway lab devices, use the host ADB
  server (the launcher and the MCP server pick it up automatically, and it uses your
  own key) or mount your own keys:
  ```
  docker run -it --rm -v "$HOME/.android:/root/.android" -v "$PWD:/work" \
      stanislavpovolotsky/jddlab:latest
  ```
- Some tools use the network. The Frida gadgets are baked into the image, but
  `objection` checks for updates, `blutter` downloads Dart SDK sources the first
  time it sees a Dart version, and `apk-patcher --online` downloads gadgets. Check
  what a tool does before relying on it in an offline environment.
- The MCP server runs Docker commands for the AI client connected to it: the client
  can run any bundled jddlab command against the paths it is given. Connect only
  clients you trust and limit the directories they work with.
- jddlab does not need `--privileged` or the host Docker socket. Don't add them
  unless you know what they expose.

## Supported versions

Only the latest published image (`stanislavpovolotsky/jddlab:latest`) and the
latest launcher/MCP release receive fixes. Run `jddlab update` before reporting
an issue.
