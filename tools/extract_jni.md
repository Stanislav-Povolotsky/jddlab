# extract_jni

Lists the JNI methods of an APK as JSON: Java `native` method declarations and the
JNI symbols exported by its native libraries. It doesn't extract the `.so` files
(use `apktool d` or `unzip` for that).

## Usage

```text
extract_jni <apk> [-o <file.json>]
```

With `-o` the JSON goes to a file, otherwise to stdout. Run `extract_jni --help` for
all options.

## Example

```json
{"args":["app.apk","-o","jni.json"],"input_paths":["app.apk"],"output_paths":["jni.json"]}
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
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest extract_jni <args>
```
