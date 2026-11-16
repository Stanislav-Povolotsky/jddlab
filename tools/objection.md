# objection

Runtime mobile exploration toolkit.

## Usage

```text
objection [OPTIONS] COMMAND [ARGS]...
```

## Main modes

- `patchapk`: patch an APK with Frida gadget.
- `explore`: start an interactive exploration session.
- `run`: run a single objection command.
- `api`: start objection API server in headless mode.
- `signapk`: zipalign and sign an APK with the objection key.

## Frida gadget

`patchapk` injects the Frida gadget baked into the image, without downloading it:
the latest 17.x for `objection`, 16.1.3 for `objection@16` (old Android versions).
`--gadget-version <ver>` uses the baked gadget when that version is baked in and
downloads it otherwise; `JDDLAB_FRIDA_ONLINE=1` restores the original behaviour
(download the latest gadget from GitHub). Without `-a <abi>` the architecture is
read from the connected device with `adb`.

## Examples

```json
{"args":["patchapk","--source","app.apk","-a","arm64-v8a"],"input_paths":["app.apk"],"output_paths":["app.objection.apk"]}
```

`explore` is an interactive REPL. Through MCP run single commands with `run` (the
gadget-injected app must be running; the device is reached through the host ADB
server, see `adb.md`):

```json
{"args":["-n","Gadget","run","android hooking list activities"],"timeout_seconds":120}
```

`run` unloads its agent right after the command, so hooks it installs (for example
`android sslpinning disable`) don't stay active. Keep them with an interactive
`explore` session, or load a script with `frida -U -n Gadget -l <script> -q -t <seconds>`.

`patchapk` adds the INTERNET permission the gadget needs to listen for clients.
`objection@16` uses `-g Gadget` instead of `-n Gadget`.


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
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest objection <args>
```
