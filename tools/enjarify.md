# enjarify

Translate Dalvik bytecode to equivalent Java bytecode.

## Usage

```text
enjarify [-h] [-o OUTPUT] [-f] [-q] input
```

## Arguments

- `-h`: show help.
- `-o OUTPUT`: output jar path.
- `-f`: overwrite output.
- `-q`: quiet mode.
- `input`: APK or DEX input.

## Example

```json
{"args":["-o","app.jar","app.apk"],"input_paths":["app.apk"],"output_paths":["app.jar"]}
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
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest enjarify <args>
```
