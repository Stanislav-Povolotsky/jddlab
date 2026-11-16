# hbc-file-parser

Part of hermes-dec. Prints the header of a React Native Hermes bytecode (HBC) file,
including the bytecode version.

In React Native APKs the bundle is `assets/index.android.bundle`. It is either
plain (minified) JavaScript or Hermes bytecode; `file` reports
`Hermes JavaScript bytecode, version NN` for the latter. Extract it from the APK
(e.g. `unzip app.apk assets/index.android.bundle`) before running the tools.

Upstream: https://github.com/P1sec/hermes-dec (supports HBC versions up to 99)

## Usage

```text
hbc-file-parser <index.android.bundle>
```

## Example

```json
{"args":["assets/index.android.bundle"],"input_paths":["assets/index.android.bundle"]}
```

See also `hbc-disassembler` and `hbc-decompiler`.

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
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest hbc-file-parser <args>
```
