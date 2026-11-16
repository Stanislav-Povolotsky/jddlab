# krakatau2

Krakatau v2 is a Java bytecode assembler and disassembler, not a decompiler. It converts
`.class`/`.jar` files to an editable text assembly (`.j`) and back, even for
obfuscated code. For Android, convert DEX to a jar first (`d2j-dex2jar`).

## Main modes

- `dis [--out <dir|.zip|.jar|.j>] [-r|--roundtrip] <input.class|.jar>`: disassemble.
  `--roundtrip` produces assembly that reassembles to the identical binary.
- `asm --out <out.jar|.zip|.class> <input.j|.zip>`: assemble.

Run `krakatau2 help` for the complete subcommand list. The short alias `krak2` is also available.

## Examples

Disassemble a jar into a zip of `.j` files:

```json
{"args":["dis","--out","app-asm.zip","app.jar"],"input_paths":["app.jar"],"output_paths":["app-asm.zip"]}
```

Assemble it back:

```json
{"args":["asm","--out","app-patched.jar","app-asm.zip"],"input_paths":["app-asm.zip"],"output_paths":["app-patched.jar"]}
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
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest krakatau2 <args>
```
