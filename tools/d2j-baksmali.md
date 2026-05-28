# d2j-baksmali

Run the `d2j-baksmali` command from the jddlab Docker image.

## Usage

Pass native command-line arguments exactly as the command expects them in the MCP `args` array. Use `input_paths` and `output_paths` so the server can infer the host directory to mount as `/work`.

## Discovering full arguments

Run the command help through MCP:

```json
{"args":["--help"]}
```

If `--help` is not accepted, try `-h`, `help`, or no arguments; several reverse engineering tools use different help conventions.


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
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest d2j-baksmali <args>
```
