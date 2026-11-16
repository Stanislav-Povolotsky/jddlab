# quark

Quark-Engine analyzes Android malware behaviour. It scores an APK/DEX against a set of
behaviour rules (sending SMS, reading contacts, loading code dynamically, ...) and
explains which methods implement them. The rule set (quark-rules) is baked into the
image (`/root/.quark-engine/quark-rules/rules`).

Upstream: https://github.com/quark-engine/quark-engine

## Usage

```text
quark -a <apk-or-dex> [options]
```

## Common options

- `-s`, `--summary [rule]`: summary report (all rules, or one rule/label).
- `-d`, `--detail [rule]`: detailed report.
- `-o <file>`, `--output <file>`: JSON report.
- `-r <dir>`, `--rule <dir>`: custom rules directory.
- `-t <0-100>`, `--threshold`: only report behaviours with at least this confidence.
- `-l <labels>`, `--label`: summary by rule label (e.g. `network`, `sms`).
- `-w`, `--webreport <file>`: HTML report.
- `--help`: all options.

## Examples

```json
{"args":["-a","app.apk","-s"],"input_paths":["app.apk"],"timeout_seconds":1800}
```

```json
{"args":["-a","app.apk","-s","-o","quark-report.json"],"input_paths":["app.apk"],"output_paths":["quark-report.json"],"timeout_seconds":1800}
```

## MCP wrapper arguments

Every MCP wrapper for this command accepts:

- `args`: native command arguments, as an array of strings.
- `workdir`: optional host directory to mount as `/work`.
- `input_paths`: host input files/directories used for mount-root inference and path rewriting.
- `output_paths`: host output files/directories used for mount-root inference and path rewriting.
- `extra_mounts`: additional Docker mounts such as Android keys or persistent state.
- `timeout_seconds`: command timeout (large APKs can take minutes).
- `docker_image`: override the default `stanislavpovolotsky/jddlab:latest` image.
- `interactive`: add Docker `-it`; keep this false for most MCP clients.

The server runs:

```text
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest quark <args>
```
