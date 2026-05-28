# ghidra

Ghidra headless analyzer (`analyzeHeadless`) wrapper.

## Usage

Use Ghidra `analyzeHeadless` arguments: project location, project name, imports, scripts, analysis options, and repository URLs. Run `ghidra` with no arguments or help arguments for the complete version-specific syntax.

## Example

```json
{"args":["/work/project","ProjectName","-import","/work/lib.so","-deleteProject"],"input_paths":["lib.so"],"output_paths":["project"]}
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
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest ghidra <args>
```
