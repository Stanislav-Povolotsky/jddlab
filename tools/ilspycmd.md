# ilspycmd

ILSpy command-line .NET decompiler: decompiles .NET assemblies (`.dll`/`.exe`) to
C#. Use it on the DLLs extracted from Xamarin / .NET MAUI apps with `pyxamstore`.

Upstream: https://github.com/icsharpcode/ILSpy

## Usage

```text
ilspycmd [options] <assembly>
```

Without `-o` the decompiled code is printed to stdout.

## Common options

- `-o <dir>`: output directory.
- `-p`: decompile into a compilable project (one `.cs` file per type); use with `-o`.
- `-t <type>`: decompile only this fully qualified type name.
- `-l <c|i|s|d|e>`: list types (classes, interfaces, structs, delegates, enums).
- `-il`: show IL instead of C#.
- `-r <dir>`: reference directory for resolving dependencies (e.g. the other extracted DLLs).
- `-lv <version>`: C# language version.
- `--help`: all options.

## Examples

List the classes of an app assembly:

```json
{"args":["-l","c","dlls/MyApp.dll"],"input_paths":["dlls"]}
```

Decompile it into a project:

```json
{"args":["-p","-o","myapp-src","-r","dlls","dlls/MyApp.dll"],"input_paths":["dlls"],"output_paths":["myapp-src"]}
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
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest ilspycmd <args>
```
