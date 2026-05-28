# objection

Runtime mobile exploration toolkit.

## Usage

```text
objection [OPTIONS] COMMAND [ARGS]...
```

## Main modes

- `patchapk`: patch an APK with Frida gadget.
- `explore`: start an interactive exploration session.
- `run`: run a single objection command.
- `api`: start objection API server in headless mode.
- `signapk`: zipalign and sign an APK with the objection key.

## Examples

```json
{"args":["patchapk","--source","app.apk"],"input_paths":["app.apk"],"output_paths":["app.objection.apk"]}
```

```json
{"args":["-g","Gadget","explore","-s","android sslpinning disable"],"extra_mounts":[{"host":"~/.android","container":"/root/.android","mode":"rw"}],"timeout_seconds":3600}
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
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest objection <args>
```
