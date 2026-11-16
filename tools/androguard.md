# androguard

Android reverse engineering toolkit (Python).

## Usage

```text
androguard [OPTIONS] COMMAND [ARGS]...
```

## Main modes

- `axml <apk>`: print the decoded `AndroidManifest.xml`.
- `apkid <apk>`: package name, version code and version name.
- `sign <apk>`: signing scheme versions and certificate fingerprints.
- `arsc`: decode `resources.arsc`.
- `decompile`, `disassemble`, `cg`: decompile, disassemble, build a call graph.
- `analyze`: interactive IPython session (needs `interactive`).
- `trace`, `dtrace`, `dump`: dynamic analysis on a connected device.

Run `androguard --help` or `androguard <command> --help` for options.

## Example

```json
{"args":["axml","app.apk"],"input_paths":["app.apk"]}
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
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest androguard <args>
```
