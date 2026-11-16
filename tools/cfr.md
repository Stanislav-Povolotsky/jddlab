# cfr

CFR is a Java decompiler for `.jar` / `.class` files. It handles modern Java
constructs well (lambdas, string switches, records). Convert APK/DEX input to a jar
first (`dex2jar`), or use `jadx` directly.

Upstream: https://www.benf.org/other/cfr/ (Maven Central `org.benf:cfr`)

## Usage

```text
cfr <jar-or-class> [--outputdir <dir>] [options]
```

Without `--outputdir` the decompiled source is printed to stdout.

## Common options

- `--outputdir <dir>`: write `.java` files into a package directory tree.
- `--jarfilter <regex>`: decompile only classes matching the regex.
- `--renamedupmembers true`, `--renameillegalidents true`: make obfuscated code compilable/readable.
- `--decodestringswitch`, `--decodeenumswitch`, `--sugarenums`: control re-sugaring.
- `--comments false`: no CFR header comments.
- `--help`: all options.

## Examples

Decompile a jar into a directory:

```json
{"args":["app.jar","--outputdir","cfr-out"],"input_paths":["app.jar"],"output_paths":["cfr-out"]}
```

Print one class:

```json
{"args":["app.jar","--jarfilter","com\\.example\\.MainActivity"],"input_paths":["app.jar"]}
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
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest cfr <args>
```
