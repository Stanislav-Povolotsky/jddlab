# keytool

Java KeyStore management tool for generating key pairs, certificates, and managing
keystores. Part of the JDK (available as `keytool` in the jddlab Docker image).

## Main modes

- `keytool -genkeypair [options]`: Generate a key pair and a self-signed certificate.
- `keytool -list [options]`: List keystore contents.
- `keytool -exportcert [options]`: Export a certificate.
- `keytool -importcert [options]`: Import a certificate.
- `keytool -printcert [options]`: Print certificate details.
- `keytool -delete [options]`: Delete a keystore entry.
- `keytool -help`: Print command summary.

## Common genkeypair options

- `-keystore <file>`: Keystore file to create or update. Use `.jks` (JKS) or `.p12`/`.pfx` (PKCS12).
- `-alias <name>`: Alias name for the new key entry.
- `-keyalg RSA`: Key algorithm. RSA is required for Android APK signing.
- `-keysize 2048`: Key size in bits. 2048 or 4096 for RSA.
- `-validity <days>`: Certificate validity period in days (e.g. `10000` ≈ 27 years).
- `-storepass <password>`: Keystore password.
- `-keypass <password>`: Key password (can match storepass).
- `-dname <dn>`: Distinguished name, e.g. `"CN=Test, OU=Dev, O=Test, L=City, ST=State, C=US"`.
- `-storetype PKCS12`: Force PKCS12 format (recommended over JKS for new keystores).
- `-noprompt`: Do not prompt for confirmation.
- `-v`: Verbose output.

## Common list options

- `-keystore <file>`: Keystore to list.
- `-storepass <password>`: Keystore password.
- `-v`: Verbose (show full certificate chain).
- `-alias <name>`: List only this alias.

## Built-in debug keystore

The jddlab image ships the standard Android debug keystore at
`/root/.android/debug.keystore` - no host files or `extra_mounts` needed:
- **Path**: `/root/.android/debug.keystore`
- **Alias**: `androiddebugkey`
- **Keystore / key password**: `android`
- **Algorithm**: RSA 2048, validity 10000 days
- **Supports**: v1 + v2 + v3 signing schemes

When the user mounts their own `~/.android` via `extra_mounts`, it overrides this
built-in keystore automatically.

## Examples

### Generate a new keystore (output to /work)

```json
{
  "args": ["-genkeypair", "-v",
    "-keystore", "my-release-key.jks",
    "-alias", "myapp",
    "-keyalg", "RSA", "-keysize", "2048",
    "-validity", "10000",
    "-storepass", "changeit",
    "-keypass", "changeit",
    "-dname", "CN=My App, OU=Dev, O=My Org, L=City, ST=State, C=US",
    "-storetype", "PKCS12",
    "-noprompt"],
  "output_paths": ["my-release-key.jks"]
}
```

### List contents of an existing keystore

```json
{
  "args": ["-list", "-v", "-keystore", "my-release-key.jks", "-storepass", "changeit"],
  "input_paths": ["my-release-key.jks"]
}
```

### List the built-in debug keystore (no mount needed)

```json
{
  "args": ["-list", "-v", "-keystore", "/root/.android/debug.keystore", "-storepass", "android"]
}
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
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest keytool <args>
```
