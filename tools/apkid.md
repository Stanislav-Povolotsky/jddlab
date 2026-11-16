# apkid

APKiD identifies how an APK/DEX was built and protected: compilers (dx, d8, r8,
dexlib), packers (Jiagu, Bangcle, ...), protectors and obfuscators (DexGuard,
DexProtector, ...), anti-VM and anti-debug checks. Run it first on an unknown APK to
choose the next tools: a packer, for example, means the DEX you see is only a stub.

Upstream: https://github.com/rednaga/APKiD

## Usage

```text
apkid [options] <file-or-dir> ...
```

## Common options

- `-j`, `--json`: JSON output.
- `-o <dir>`, `--output-dir <dir>`: write one JSON result per input file.
- `-r`, `--recursive`: scan directories recursively.
- `-t <seconds>`, `--timeout <seconds>`: per-file scan timeout.
- `--scan-depth <n>`: how deep to scan nested archives.
- `-v`, `--verbose`: log debug messages.

## Examples

```json
{"args":["app.apk"],"input_paths":["app.apk"]}
```

```json
{"args":["-j","app.apk"],"input_paths":["app.apk"]}
```

## MCP wrapper arguments

Every MCP wrapper for this command accepts:

- `args`: native command arguments, as an array of strings.
- `workdir`: optional host directory to mount as `/work`.
- `input_paths`: host input files/directories used for mount-root inference and path rewriting.
- `output_paths`: host output files/directories used for mount-root inference and path rewriting.
- `extra_mounts`: additional Docker mounts such as Android keys or persistent state.
- `timeout_seconds`: command timeout.
- `docker_image`: override the default `stanislavpovolotsky/jddlab:latest` image.
- `interactive`: add Docker `-it`; keep this false for most MCP clients.

The server runs:

```text
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest apkid <args>
```
