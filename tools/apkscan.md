# apkscan

Scan for secrets, endpoints, and other sensitive data after decompiling and
deobfuscating Android files (`.apk`, `.xapk`, `.dex`, `.jar`, `.class`, `.smali`,
`.zip`, `.aar`, `.arsc`, `.aab`, `.jadx.kts`).

Upstream: https://github.com/LucasFaudman/apkscan

## Usage

```text
apkscan [options] <FILES_TO_SCAN ...>
```

apkscan decompiles the input itself (default decompiler: JADX) and then runs its
secret-locator rules over the decompiled sources.

## Common arguments

- `-o`, `--output <file>`: output file for the secrets found.
- `-f`, `--format {text,json,yaml}`: output format.
- `-g`, `--groupby {file,locator,both}`: group results by input file or locator.
- `-r`, `--rules [...]`: custom secret-locator rule files or included rule sets
  (e.g. `aws`, `azure`, `gcp`, `cloud`, `endpoints`, `gitleaks`, `high-confidence`).
- `-c`, `--cleanup` / `--no-cleanup`: remove decompiled output after scanning.
- `-d`, `--deobfuscate` / `--no-deobfuscate`: deobfuscate before scanning (default on).
- Decompiler choice: `--jadx`, `--apktool`, `--cfr`, `--procyon`, `--krakatau`,
  `--fernflower` (some require Enjarify).
- `-w`, `--decompiler-working-dir <dir>`: where files are decompiled.
- `-q`, `--quiet`: suppress subprocess output.

Run `jddlab apkscan -h` for the full list, including concurrency/timeout options.

## Examples

Scan an APK and write JSON results:

```json
{"args":["-f","json","-o","secrets.json","app.apk"],"input_paths":["app.apk"],"output_paths":["secrets.json"]}
```

Scan with only high-confidence and cloud rules:

```json
{"args":["-r","high-confidence","cloud","-o","secrets.txt","app.apk"],"input_paths":["app.apk"],"output_paths":["secrets.txt"]}
```

## MCP wrapper arguments

Every MCP wrapper for this command accepts:

- `args`: native command arguments, as an array of strings.
- `workdir`: optional host directory to mount as `/work`.
- `input_paths`: host input files/directories used for mount-root inference and path rewriting.
- `output_paths`: host output files/directories used for mount-root inference and path rewriting.
- `extra_mounts`: additional Docker mounts such as Android keys or persistent state.
- `timeout_seconds`: command timeout (secret scanning of large APKs can be slow).
- `docker_image`: override the default `stanislavpovolotsky/jddlab:latest` image.
- `interactive`: add Docker `-it`; keep this false for most MCP clients.

The server runs:

```text
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest apkscan <args>
```
