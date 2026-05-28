# extract_jni

Extract JNI/native library artifacts from Android packages or unpacked APK contents.

## Usage

Run `extract_jni --help` for the exact version-specific argument list. Pass the APK or directory input and any output option accepted by the tool.

## Example

```json
{"args":["app.apk","jni-out"],"input_paths":["app.apk"],"output_paths":["jni-out"]}
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
