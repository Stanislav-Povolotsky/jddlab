# blutter

B(l)utter reverse engineers Flutter apps. Flutter compiles Dart code ahead of time
into `lib/arm64-v8a/libapp.so`, which Java decompilers can't read. blutter recovers
Dart class and function names, the object pool (strings, constants), an annotated
arm64 disassembly and a Frida script template.

Upstream: https://github.com/worawit/blutter (Android arm64 `libapp.so` only)

## Usage

```text
blutter <dir-with-libapp.so-and-libflutter.so | app.apk> <out_dir> [options]
```

Extract the libraries first, e.g. `unzip app.apk 'lib/arm64-v8a/*' -d app`, then
pass `app/lib/arm64-v8a`.

## Options

- `--rebuild`: force rebuilding the analyzer for this Dart version.
- `--no-analysis`: build/run without code analysis (faster, less output).
- `--dart-version <ver>_android_arm64`: analyze `libapp.so` alone (when `libflutter.so` is missing), e.g. `3.4.2_android_arm64`.

## Output

- `asm/*`: libapp disassembly with symbols.
- `blutter_frida.js`: Frida script template for the app (use it with `frida -U -l`).
- `objs.txt`: nested dump of objects from the object pool.
- `pp.txt`: all Dart objects in the object pool.

## First run per Dart version is slow

blutter detects the app's Dart version and, the first time it sees that version,
downloads the matching Dart SDK sources (needs network) and compiles an analyzer
(several minutes). The result is cached in the `jddlab-cache` docker volume
(`/var/cache/jddlab/blutter`, mounted automatically by the `jddlab` launcher and the
MCP server), so later runs for the same Dart version are fast (about 20 seconds
instead of 6 minutes for a 15 MB `libapp.so`). Use a large `timeout_seconds` (e.g.
3600) for the first run.

## Example

```json
{"args":["app/lib/arm64-v8a","blutter-out"],"input_paths":["app"],"output_paths":["blutter-out"],"timeout_seconds":3600}
```

## MCP wrapper arguments

Every MCP wrapper for this command accepts:

- `args`: native command arguments, as an array of strings.
- `workdir`: optional host directory to mount as `/work`.
- `input_paths`: host input files/directories used for mount-root inference and path rewriting.
- `output_paths`: host output files/directories used for mount-root inference and path rewriting.
- `extra_mounts`: additional Docker mounts such as Android keys or persistent state.
- `timeout_seconds`: command timeout (the first run per Dart version compiles an analyzer: use e.g. 3600).
- `docker_image`: override the default `stanislavpovolotsky/jddlab:latest` image.
- `interactive`: add Docker `-it`; keep this false for most MCP clients.

The server runs:

```text
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest blutter <args>
```
