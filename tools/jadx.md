# jadx

Dex to Java decompiler for `.apk`, `.dex`, `.jar`, `.class`, `.smali`, `.zip`, `.aar`, `.arsc`, `.aab`, `.xapk`, and `.jadx.kts` inputs.

## Main modes

- `jadx [options] <input files>`: decompile inputs.
- `jadx plugins ...`: manage jadx plugins.
- `jadx --help`: print full command help.

## Common arguments

- `-d`, `--output-dir <dir>`: output directory.
- `-ds`, `--output-dir-src <dir>`: source output directory.
- `-dr`, `--output-dir-res <dir>`: resource output directory.
- `-r`, `--no-res`: skip resources.
- `-s`, `--no-src`: skip source decompilation.
- `--single-class <name>`: decompile one class.
- `--single-class-output <file|dir>`: output for a single class.
- `--output-format java|json`: output format.
- `-e`, `--export-gradle`: export as Android Gradle project.
- `-j`, `--threads-count <n>`: thread count.
- `-m`, `--decompilation-mode <mode>`: decompilation mode.
- `--deobf`: enable deobfuscation.
- `--rename-flags <flags>`: rename invalid/printable identifiers.
- `--log-level <level>`: set log level.
- `-P<plugin.option>=<value>`: pass plugin options.
- `--version`: print version.

## Examples

```json
{"args":["app.apk","--deobf","--output-dir","jadx-out"],"input_paths":["app.apk"],"output_paths":["jadx-out"]}
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
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest jadx <args>
```
