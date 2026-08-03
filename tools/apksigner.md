# apksigner

Sign and verify Android APK files using APK Signature Schemes v1, v2, v3, and v4.

Part of the Android SDK Build Tools. Available in the jddlab Docker image at
`/usr/local/android-sdk-linux/build-tools/current/apksigner`.

## Main modes

- `apksigner sign [options] <apk>`: Sign an APK file.
- `apksigner verify [options] <apk>`: Verify an APK's signature(s).
- `apksigner rotate [options]`: Create a signing certificate lineage for key rotation.
- `apksigner version`: Print tool version.

## Common sign options

- `--ks <file>`: Keystore file (JKS or PKCS#12).
- `--ks-key-alias <alias>`: Alias of the signing key in the keystore.
- `--ks-pass pass:<password>`: Keystore password.
- `--key-pass pass:<password>`: Key password (if different from keystore password).
- `--v1-signing-enabled true|false`: Enable/disable v1 (JAR) signing. Default: true.
- `--v2-signing-enabled true|false`: Enable/disable v2 signing. Default: true.
- `--v3-signing-enabled true|false`: Enable/disable v3 signing. Default: true.
- `--out <file>`: Output APK path (if omitted, signs in-place).
- `--min-sdk-version <int>`: Override minimum SDK version for signing decisions.

## Common verify options

- `--verbose`: Print detailed verification information.
- `--print-certs`: Print certificates used to sign the APK.
- `-v`: Short for `--verbose`.

## Examples

Sign an APK with the debug keystore:
```json
{
  "args": ["sign", "--ks", "/root/.android/debug.keystore", "--ks-key-alias", "androiddebugkey", "--ks-pass", "pass:android", "--key-pass", "pass:android", "app.apk"],
  "input_paths": ["app.apk"],
  "output_paths": ["app.apk"],
  "extra_mounts": [{"host": "~/.android", "container": "/root/.android", "mode": "ro"}]
}
```

Sign with a custom keystore enabling all schemes:
```json
{
  "args": ["sign", "--ks", "release.keystore", "--ks-key-alias", "myapp", "--ks-pass", "pass:changeit", "--key-pass", "pass:changeit", "--v1-signing-enabled", "true", "--v2-signing-enabled", "true", "--v3-signing-enabled", "true", "app_aligned.apk"],
  "input_paths": ["app_aligned.apk", "release.keystore"],
  "output_paths": ["app_aligned.apk"]
}
```

Verify and print certificates:
```json
{
  "args": ["verify", "--verbose", "--print-certs", "app_aligned.apk"],
  "input_paths": ["app_aligned.apk"]
}
```

## CRITICAL: Sign AFTER zipalign

APK signing with v2/v3 schemes covers the entire APK binary. Running `zipalign`
after signing invalidates the signature. Always:
1. Run `zipalign` first.
2. Run `apksigner` second.

## MCP wrapper arguments

Every MCP wrapper for this command accepts:

- `args`: native command arguments, as an array of strings.
- `workdir`: optional host directory to mount as `/work`.
- `input_paths`: host input files/directories used for mount-root inference and path rewriting.
- `output_paths`: host output files/directories used for mount-root inference and path rewriting.
- `extra_mounts`: additional Docker mounts such as Android keystores.
- `timeout_seconds`: command timeout.
- `docker_image`: override the default `stanislavpovolotsky/jddlab:latest` image.
- `interactive`: add Docker `-it`; keep this false for most MCP clients.

The server runs:

```text
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest apksigner <args>
```
