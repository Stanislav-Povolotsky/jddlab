# apk-patcher

Patch Android APKs, commonly to inject Frida gadget while touching as little of the package as possible.

## Usage

```text
apk-patcher [options] <apk-or-directory>
```

Run `apk-patcher -h` for the complete version-specific option list.

## Frida gadget version

By default (jddlab patch) apk-patcher injects the Frida gadget **baked into the
image at build time** — it does not reach out to GitHub on every run, so patching
is offline and reproducible. The baked version is recorded in
`/usr/local/jddlab/software-list.txt` and the gadgets live in
`/usr/local/frida-gadgets`.

To use a different gadget:

- `--frida-version <ver>` — download and inject a specific Frida version from GitHub.
- `--online` (or the `JDDLAB_FRIDA_ONLINE=1` env var) — download the latest version from GitHub.
- `JDDLAB_FRIDA_GADGET_DIR=<dir>` — point the cache at a different directory.

## Example

```json
{"args":["app.apk"],"input_paths":["app.apk"],"output_paths":["."]}
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
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest apk-patcher <args>
```
