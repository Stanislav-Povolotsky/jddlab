# pyxamstore

Unpacks and repacks the .NET assemblies of Xamarin / .NET MAUI Android apps.
Their C# code lives in .NET DLLs packed into an assembly store, often
LZ4-compressed (`XALZ`):

- V1 (Xamarin, .NET 6/7): `assemblies/assemblies.blob` + `assemblies/assemblies.manifest`
  (+ per-ABI `assemblies.<abi>.blob`);
- V2/V3 (.NET 8+ / MAUI): `lib/<abi>/libassemblies.<abi>.blob.so`.

The extracted DLLs can then be decompiled with `ilspycmd`.

Upstream: https://github.com/AbhiTheModder/pyxamstore (fork of jakev/pyxamstore with V2/V3 support)

## Usage

```text
pyxamstore <assemblies.blob | libassemblies.<abi>.blob.so> -u [-o <out_dir>] [-r <arch>]
pyxamstore <assemblies.blob> <assemblies.json> -p           # V1 repack (writes *.new files to the current dir)
pyxamstore <libassemblies.<abi>.blob.so> <extracted_dir> -p -o <out.so>   # V2/V3 repack
```

- `-u`, `--unpack`: extract assemblies (LZ4 is decompressed automatically).
- `-p`, `--pack`: re-pack assemblies.
- `-o`, `--out-path`: output directory (unpack) or output ELF (pack).
- `-r`, `--arch`: V1 only, which per-ABI blob to unpack: `arm`, `arm64`, `x86`, `x86_64` (default arm64).

For V1 the manifest must sit next to `assemblies.blob`; V1 unpack writes the DLLs to
`out/` and a config `assemblies.json` next to the blob.

## Examples

```json
{"args":["app/lib/arm64-v8a/libassemblies.arm64-v8a.blob.so","-u","-o","dlls"],"input_paths":["app"],"output_paths":["dlls"]}
```

```json
{"args":["app/assemblies/assemblies.blob","-u"],"input_paths":["app"]}
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
docker run --rm -v "<host-mount-root>:/work" stanislavpovolotsky/jddlab:latest pyxamstore <args>
```
