# apk-patcher

Patch Android APKs, commonly to inject Frida gadget while touching as little of the package as possible.

## Usage

```text
apk-patcher [options] <apk-or-directory>
```

Run `apk-patcher -h` for the complete version-specific option list.

## Frida gadget version

In jddlab, apk-patcher injects the Frida gadget baked into the image at build time
instead of downloading one from GitHub on every run, so patching works offline and
gives the same result every time. The baked version is recorded in
`/usr/local/jddlab/software-list.txt` and the gadgets live in
`/usr/local/frida-gadgets`.

To use a different gadget:

- `--frida-version <ver>`: inject a specific Frida version. It is taken from the image
  when baked in (the latest 17.x, and 16.1.3 for old Android versions), otherwise
  downloaded from GitHub.
- `--online` (or `JDDLAB_FRIDA_ONLINE=1`): download the latest version from GitHub.
- `JDDLAB_FRIDA_GADGET_DIR=<dir>`: use gadgets from another directory.

## Gadget config

Without `-c`, jddlab adds a gadget config: with `-l <script>` the gadget runs that
script itself on every launch (`script` interaction), otherwise it listens on
127.0.0.1:27042 and waits for a client (`listen`, `on_load: wait`) before the app
continues. A config is required when the app doesn't extract its native libraries
(`extractNativeLibs=false`, the default for modern apps): without one the gadget
doesn't start. Ready-made configs are in the image: `/root/frida/config/onload_wait.config`
and `/root/frida/config/onload_nowait.config`.

`listen` needs the INTERNET permission. `apk-patcher` doesn't add it (its
`-f`/`--fix_manifest` only sets `extractNativeLibs`), so for an app without it use
`-l` or `objection patchapk`, which adds the permission.

Scripts loaded by the gadget itself (`apk-patcher -l`) are plain scripts. Frida 17
gadgets don't give such scripts the `Java` object (`Java.perform` fails silently). For
Java hooks use the frida 16 gadget baked into the image: `-f --frida-version 16.1.3`
(16.x gadgets read their config and script only from extracted native libraries,
which `-f` enables), and start the hooks from `setTimeout(..., 1000)` rather than at
the top level of the script. Alternatively compile the script with
`frida-java-bridge`. Scripts loaded by the `frida` CLI (`frida -l`) have `Java` with
either version. (Tested on Android 11.)

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
