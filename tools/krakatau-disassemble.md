# krakatau-disassemble

Disassemble Java class files or jars to Krakatau assembly.

## Usage

```text
krakatau-disassemble [-h] [-out OUT] [-r] [-path PATH] [-roundtrip] target
```

## Arguments

- `-h`: show help.
- `-out OUT`: output path.
- `-r`: process recursively.
- `-path PATH`: class path.
- `-roundtrip`: emit output suitable for round-trip assembly.
- `target`: class, jar, or directory target.

## Example

```json
{"args":["-out","asm","input.jar"],"input_paths":["input.jar"],"output_paths":["asm"]}
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
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest krakatau-disassemble <args>
```
