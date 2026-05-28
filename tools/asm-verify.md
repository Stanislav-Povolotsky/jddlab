# asm-verify

Verify Java bytecode with ASM.

## Usage

This command is provided by the dex2jar tool family. Most dex2jar tools accept `--help` and use this general shape:

```text
asm-verify [options] <file0> [file1 ... fileN]
```

The canonical command may also be available with a `d2j-` prefix. For example, `asm-verify` and `d2j-asm-verify` are aliases when both exist in the image.

## Common argument patterns

- `--help`: show the complete version-specific option list.
- `-f`, `--force`: overwrite an existing output file when supported.
- `-o <file>` or `--output <file>`: output file when supported.
- Input files are usually APK, DEX, JAR, class, Jasmin, or smali files depending on the command.

## Example

```json
{"args":["--help"]}
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
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest asm-verify <args>
```
