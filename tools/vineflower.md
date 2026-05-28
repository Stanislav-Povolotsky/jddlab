# vineflower

Modern FernFlower fork for Java bytecode decompilation.

## Usage

Use Vineflower options followed by one or more Java bytecode inputs and an output directory. Run `vineflower --help` for the complete version-specific option list.

## Example

```json
{"args":["input.jar","decompiled"],"input_paths":["input.jar"],"output_paths":["decompiled"]}
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
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest vineflower <args>
```
