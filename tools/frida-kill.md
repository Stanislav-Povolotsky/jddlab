# frida-kill

Kill a process on a device (frida-tools).

## Usage

```text
frida-kill [-U | -D <id>] <pid-or-name>
```

## Example

```json
{"args":["-U","Gadget"]}
```

## Devices (ADB)

Device-side commands (`-U`, `-D <id>`) go through ADB. Each MCP call is a separate
container, so jddlab uses the host ADB server when one is running (the MCP server
and the `jddlab` launcher look for it on `127.0.0.1:5037`). Start it on the host with
`adb start-server` and connect the device there (USB, or Wi-Fi with `adb pair` /
`adb connect`); the device then stays connected between calls. Without a host ADB
server every call starts a new ADB server inside the container, which knows no
devices. See README, "How to use ADB and Frida with jddlab".

The Frida version on the device side (gadget or frida-server) must match the CLI.
`frida` here is the latest 17.x, the same as the gadget baked into the image and
injected by `apk-patcher`, `android-unpinner` and `objection`. For frida 16.x
gadgets use `frida@16`, `frida-ps@16` and the other `@16` commands from the jddlab
shell.

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
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest frida-kill <args>
```
