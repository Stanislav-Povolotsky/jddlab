# krakatau-assemble

Assemble Krakatau assembly back to class files or jars.

## Usage

```text
krakatau-assemble [-h] [-out OUT] [-r] [-q] target
```

## Arguments

- `-h`: show help.
- `-out OUT`: output path.
- `-r`: process recursively.
- `-q`: quiet output.
- `target`: assembly file or directory.

## Example

```json
{"args":["-out","classes.jar","asm"],"input_paths":["asm"],"output_paths":["classes.jar"]}
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
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest krakatau-assemble <args>
```
