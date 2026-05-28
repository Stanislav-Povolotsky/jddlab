# procyon

Procyon Java decompiler.

## Usage

```text
procyon [options] <type names or class/jar files>
```

## Common arguments

- `-jar <file>`: decompile all classes in a jar.
- `-o <dir>`: output directory.
- `-b`, `--bytecode-ast`: output bytecode AST.
- `-r`, `--raw-bytecode`: output raw bytecode.
- `-u`, `--unoptimized`: show unoptimized code.
- `-v`, `--verbose`: verbose output.
- `-?`, `--help`: show help.

## Example

```json
{"args":["-jar","input.jar","-o","src"],"input_paths":["input.jar"],"output_paths":["src"]}
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
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest procyon <args>
```
