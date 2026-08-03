# zipalign

Align uncompressed data in an Android APK file to 4-byte boundaries.

Part of the Android SDK Build Tools. Available in the jddlab Docker image at
`/usr/local/android-sdk-linux/build-tools/current/zipalign`.

Alignment is required for efficient memory mapping during app loading. It MUST be
performed **before** signing with `apksigner` - running `zipalign` after signing
invalidates v2/v3 signatures.

## Usage

```text
zipalign [-f] [-p] [-v] [-z] <align> <infile.apk> <outfile.apk>
zipalign -c [-p] [-v] <align> <infile.apk>
```

- `<align>`: Alignment in bytes (use **4** for standard APKs).
- `<infile.apk>`: Input APK.
- `<outfile.apk>`: Output APK (when not using `-c`).

## Options

- `-c`: Check alignment only; do not rewrite (exits 0 if already aligned).
- `-f`: Overwrite `<outfile.apk>` if it already exists.
- `-p`: Page-align stored shared object `.so` files to 4096 bytes (recommended for Android 6+).
- `-v`: Verbose output.
- `-z`: Recompress using Zopfli.

## Examples

Align an APK before signing (standard usage):
```json
{
  "args": ["-v", "-p", "4", "rebuilt.apk", "rebuilt_aligned.apk"],
  "input_paths": ["rebuilt.apk"],
  "output_paths": ["rebuilt_aligned.apk"]
}
```

Check if an APK is already aligned:
```json
{
  "args": ["-c", "-v", "4", "app.apk"],
  "input_paths": ["app.apk"]
}
```

## Correct workflow order

```
1. apktool b decompiled/ -o rebuilt.apk
2. zipalign -v -p 4 rebuilt.apk rebuilt_aligned.apk   ← FIRST
3. apksigner sign --ks key.keystore rebuilt_aligned.apk ← SECOND
```

## MCP wrapper arguments

Every MCP wrapper for this command accepts:

- `args`: native command arguments, as an array of strings.
- `workdir`: optional host directory to mount as `/work`.
- `input_paths`: host input files/directories used for mount-root inference and path rewriting.
- `output_paths`: host output files/directories used for mount-root inference and path rewriting.
- `extra_mounts`: additional Docker mounts.
- `timeout_seconds`: command timeout.
- `docker_image`: override the default `stanislavpovolotsky/jddlab:latest` image.
- `interactive`: add Docker `-it`; keep this false for most MCP clients.

The server runs:

```text
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest zipalign <args>
```
