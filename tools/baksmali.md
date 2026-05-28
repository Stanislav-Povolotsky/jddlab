# baksmali

Disassembler for Android DEX bytecode.

## Usage

```text
baksmali [--help] [--version] [<command [<args>]]
```

## Main modes

- `baksmali disassemble`, `baksmali dis`, `baksmali d`: disassemble dex files into smali.
- `baksmali dump`, `baksmali list`, `baksmali deodex`, depending on version.
- `baksmali help <command>`: show command-specific help.

## Arguments

- `--help`, `-h`: show help.
- `--version`, `-v`: print version.

## Example

```json
{"args":["disassemble","classes.dex","-o","smali"],"input_paths":["classes.dex"],"output_paths":["smali"]}
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
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest baksmali <args>
```
