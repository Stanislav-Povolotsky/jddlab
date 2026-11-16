# adb

Android Debug Bridge (Android SDK platform-tools; Ubuntu `adb` package on arm64).

## Host ADB server (recommended)

Each jddlab run / MCP call is a fresh container. When an ADB server is running on
the host (`adb start-server`, default port 5037), jddlab connects the container
to it automatically, so:

- devices attached to the host over USB are visible (Docker Desktop can't pass USB
  devices into a container otherwise);
- `adb connect` / `adb pair` done on the host (or with this tool) persist between
  calls;
- your own ADB key (`~/.android/adbkey` on the host) is used.

Without a host ADB server the container starts a private server that forgets
everything when the call ends. That works in an interactive `jddlab` shell but not for
one-shot MCP calls. Control: `JDDLAB_ADB=auto|host|container`,
`JDDLAB_ADB_SERVER=host:port` (environment of the launcher / MCP server).

Ports opened with `adb forward` / `adb reverse` belong to the machine that runs the
ADB server. With the host ADB server that is the host: from the container connect to
`$JDDLAB_ADB_FORWARD_HOST` (set by the image entrypoint; `host.docker.internal` on
Docker Desktop) instead of `127.0.0.1`. android-unpinner does this already.

## Common commands

- `devices -l`: list devices.
- `pair <ip:port> <code>` / `connect <ip:port>`: wireless debugging.
- `install -r <apk>`: install (or replace) an APK.
- `shell <cmd>`: run a command on the device, e.g. `pm list packages -3`,
  `monkey -p <pkg> 1` (start an app), `am force-stop <pkg>`.
- `pull <remote> <local>` / `push <local> <remote>`.
- `logcat -d`: dump the log. Always pass `-d` from MCP: plain `logcat` never ends.

## Examples

```json
{"args":["devices","-l"]}
```

```json
{"args":["install","-r","app.patched.apk"],"input_paths":["app.patched.apk"]}
```

```json
{"args":["shell","monkey","-p","com.example.app","1"]}
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
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest adb <args>
```
