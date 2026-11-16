# hbc-disassembler

Part of hermes-dec. Disassembles React Native Hermes bytecode
(`assets/index.android.bundle`) into a readable Hermes assembly listing with
function names, string literals and constants.

Upstream: https://github.com/P1sec/hermes-dec

## Usage

```text
hbc-disassembler <index.android.bundle> [<output.hasm>]
```

Without an output file the listing is printed to stdout; for real apps it is very
large, so prefer an output file.

## Example

```json
{"args":["assets/index.android.bundle","bundle.hasm"],"input_paths":["assets/index.android.bundle"],"output_paths":["bundle.hasm"]}
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
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest hbc-disassembler <args>
```
