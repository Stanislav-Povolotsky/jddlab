# fernflower

Java bytecode decompiler.

## Usage

```text
fernflower [-<option>=<value>]* [<source>]+ <destination>
```

## Arguments

- `-<option>=<value>`: FernFlower decompiler option.
- `<source>`: one or more class, jar, zip, or directory inputs.
- `<destination>`: output directory.

## Example

```json
{"args":["-dgs=true","input.jar","decompiled"],"input_paths":["input.jar"],"output_paths":["decompiled"]}
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
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest fernflower <args>
```
