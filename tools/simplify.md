# simplify

Android virtual machine and deobfuscator.

## Usage

```text
simplify <input> [options]
```

## Common arguments

- `-o <file>`: output DEX.
- `-it <regex>` / `-et <regex>`: only include / exclude classes and methods matching
  the regex (e.g. `-it 'com/example/Crypto'`).
- `-ie`: ignore errors while executing methods (needed when the app uses Android
  framework classes simplify's VM can't load).
- `--max-execution-time <s>`, `--max-call-depth <n>`, `--max-address-visits <n>`: execution limits.
- `-q`, `-v <level>`: quiet / verbose.

Run `simplify -h` for all options.

## Example

```json
{"args":["classes.dex","-o","simplified.dex"],"input_paths":["classes.dex"],"output_paths":["simplified.dex"]}
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
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest simplify <args>
```
