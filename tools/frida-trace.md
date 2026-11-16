# frida-trace

Trace function calls (Java methods, native exports) on a device (frida-tools).
frida-trace runs until it is stopped, so from MCP always set `timeout_seconds`: the
container is killed when it expires, and the output collected so far is returned.

Handlers are generated into `./__handlers__` (inside `/work`, i.e. your mounted
directory) and can be edited and reused.

## Usage

```text
frida-trace [-U] (-n <name> | -N <identifier> | -f <identifier>) [-j 'class!method'] [-i 'function'] [-I 'module']
```

- `-j 'com.example.*!*'`: trace Java methods (glob `class!method`).
- `-i 'open*'`: trace native functions; `-I libfoo.so`: all exports of a module.
- `-x`, `-X`: exclude functions/modules.

## Example

```json
{"args":["-U","-n","Gadget","-j","com.example.app.*!*"],"workdir":".","timeout_seconds":60}
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
- `timeout_seconds`: command timeout (frida-trace never ends by itself; the container is killed at the timeout).
- `docker_image`: override the default `stanislavpovolotsky/jddlab:latest` image.
- `interactive`: add Docker `-it`; keep this false for most MCP clients.

The server runs:

```text
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest frida-trace <args>
```
