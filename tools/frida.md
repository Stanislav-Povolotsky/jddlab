# frida

Frida CLI (frida-tools, latest 17.x). Injects JavaScript into processes on a
device. From MCP use it non-interactively, in quiet mode `-q` with a script and a
timeout; the REPL needs a terminal.

Upstream: https://frida.re/docs/frida-cli/

## Usage

```text
frida [-U | -D <id> | -H <host>] (-n <name> | -N <identifier> | -p <pid> | -f <identifier>) [-l script.js] [-e code] [-q] [-t <seconds>]
```

- `-U`: the ADB device; `-D <id>`: a specific device; `-H host[:port]`: frida-server over the network.
- `-n <name>` attach by name (a patched app with an embedded gadget is called `Gadget`),
  `-N <identifier>` attach to a running app, `-f <identifier>` spawn an app (needs frida-server/root).
- `-l <script.js>`: load a script; `-e <code>`: evaluate code.
- `-q`: quiet mode, no REPL: run `-l`/`-e` and exit; `-t <seconds>`: how long to
  keep running in quiet mode (collect the script's `console.log` output).
- `--version`.

## Typical workflow with a gadget (no root)

1. Inject the gadget: `objection patchapk` (adds the INTERNET permission the gadget
   needs to listen) or `apk-patcher`, then install the APK with `adb install -r`.
2. Start the app (`adb shell monkey -p <pkg> 1`); the gadget waits for the client.
3. Run a script for N seconds:

```json
{"args":["-U","-n","Gadget","-l","hook.js","-q","-t","30"],"input_paths":["hook.js"],"timeout_seconds":120}
```

Evaluate a snippet:

```json
{"args":["-U","-n","Gadget","-q","-e","console.log(Java.available)"]}
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
- `timeout_seconds`: command timeout (keep it above `-t`).
- `docker_image`: override the default `stanislavpovolotsky/jddlab:latest` image.
- `interactive`: add Docker `-it`; keep this false for most MCP clients.

The server runs:

```text
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest frida <args>
```
