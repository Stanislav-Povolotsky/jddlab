# APKEditor / apkeditor

Powerful Android APK editor. The image exposes both `APKEditor` and `apkeditor` aliases.

## Main modes

Run `APKEditor -h` or `apkeditor -h` for the complete version-specific help. Common workflows include:

- Decode/decompile APK-like inputs.
- Build/rebuild decoded projects.
- Merge or split APK sets.
- Refactor package metadata and resources.
- Protect, inspect, or manipulate APK contents.

## Common argument patterns

APKEditor accepts subcommands/modes followed by mode-specific options and input/output paths. Use the exact arguments from `APKEditor -h` in the `args` array.

## Examples

```json
{"args":["-h"]}
```

```json
{"args":["d","-i","app.apk","-o","decoded"],"input_paths":["app.apk"],"output_paths":["decoded"]}
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
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest APKEditor <args>
```
