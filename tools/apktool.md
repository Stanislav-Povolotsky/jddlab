# apktool

Reverse engineering tool for Android APK resources and smali projects.

## Main modes

- `apktool` or `apktool --version`: show version and basic help.
- `apktool if|install-framework [options] <framework.apk>`: install a framework APK.
- `apktool d|decode [options] <file_apk>`: decode an APK into a project directory.
- `apktool b|build [options] <app_path>`: rebuild a decoded APK project.

## Arguments

- `-advance`, `--advanced`: print advanced information.
- `-version`, `--version`: print the version.
- `-p`, `--frame-path <dir>`: framework directory for install/decode/build.
- `-t`, `--tag <tag>` / `--frame-tag <tag>`: framework tag.
- `-f`, `--force`: force delete destination directory during decode.
- `-f`, `--force-all`: skip change detection during build.
- `-o`, `--output <dir|file>`: output directory for decode, output APK for build.
- `-r`, `--no-res`: do not decode resources.
- `-s`, `--no-src`: do not decode sources.

## Examples

```json
{"args":["d","-o","decoded","app.apk"],"input_paths":["app.apk"],"output_paths":["decoded"]}
```

```json
{"args":["b","decoded","-o","rebuilt.apk"],"input_paths":["decoded"],"output_paths":["rebuilt.apk"]}
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
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest apktool <args>
```
