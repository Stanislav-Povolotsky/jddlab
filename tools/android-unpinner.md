# android-unpinner

Remove certificate pinning from APKs without root.

## Usage

```text
android-unpinner [OPTIONS] COMMAND [ARGS]...
```

## Main modes

Run `android-unpinner --help` for the complete command list. The common workflow is `patch-apk <apk...>`.

## Example

```json
{"args":["patch-apk","test.apk"],"input_paths":["test.apk"],"output_paths":["."]}
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
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest android-unpinner <args>
```
