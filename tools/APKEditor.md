# APKEditor / apkeditor

Android APK editor. The image has both `APKEditor` and `apkeditor` commands.

## Main modes

- `d` / `decode`: decode binary resources (and DEX) to readable json/xml/smali.
- `b` / `build`: build an APK from a decoded directory.
- `m` / `merge`: merge split APKs (a directory, or XAPK/APKM/APKS) into one APK.
- `x` / `refactor`: rename obfuscated resource names.
- `p` / `protect`: obfuscate the APK's resource files.
- `info`: print information about an APK.

The command comes first, followed by its options; `-i` is the input and `-o` the
output. Run `APKEditor -h` or `APKEditor <command> -h` for the full help.

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
