# mobsfscan

mobsfscan does static analysis (SAST) of mobile app source code (Java, Kotlin, Swift,
Objective-C, `AndroidManifest.xml`) with MobSF's semgrep/libsast rules: weak crypto,
WebView issues, hardcoded secrets, insecure logging, SSL/TLS misuse and more. Run it
on decompiled sources, e.g. `jadx` output.

Upstream: https://github.com/MobSF/mobsfscan

## Usage

```text
mobsfscan [options] <path> ...
```

## Common options

- `--json`: JSON output (to stdout, or to `-o`).
- `--sarif`, `--sonarqube`, `--html`: other output formats.
- `-o <file>`, `--output <file>`: output file.
- `-c <file>`, `--config <file>`: `.mobsf` config (ignore rules/paths, severity filter).
- `-w`, `--exit-warning`: non-zero exit code on warnings.

The exit code is 1 when there are findings, so check the output, not only the exit
code.

mobsfscan skips test code: files under directories such as `test`/`tests` are not
scanned.

## Example

```json
{"args":["--json","-o","mobsfscan.json","jadx-out/sources"],"input_paths":["jadx-out"],"output_paths":["mobsfscan.json"]}
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
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest mobsfscan <args>
```
