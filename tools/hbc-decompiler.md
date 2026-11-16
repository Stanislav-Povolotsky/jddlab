# hbc-decompiler

Part of hermes-dec. Decompiles React Native Hermes bytecode
(`assets/index.android.bundle`) to pseudo-JavaScript. The output can't be compiled
again, but it has the control flow, function names, API endpoints, keys and other
string literals, which is usually enough to review the app logic.

Upstream: https://github.com/P1sec/hermes-dec

## Usage

```text
hbc-decompiler <index.android.bundle> [<output.js>]
```

Without an output file the code is printed to stdout. For real apps that is a lot
of text, so write it to a file and search the file.

## Example

```json
{"args":["assets/index.android.bundle","bundle.js"],"input_paths":["assets/index.android.bundle"],"output_paths":["bundle.js"]}
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
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest hbc-decompiler <args>
```
