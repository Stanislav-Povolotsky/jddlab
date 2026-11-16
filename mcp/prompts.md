# jddlab Reverse Engineering Workflow

Target: {target}

Goal: {goal}

You are using the jddlab MCP server. Prefer the most specific MCP tool for the command, and pass command-line arguments in the `args` array exactly as the native tool expects them.

Workflow:

1. Identify the target type: APK/XAPK/APKS, DEX, JAR, class file, smali tree, native library, or mixed project.
   For an unknown APK run `jddlab_apkid` first (packers, protectors, obfuscators, compiler), and check which
   framework holds the app logic:
   - `assets/index.android.bundle` -> React Native (Hermes bytecode or plain JS);
   - `lib/<abi>/libapp.so` + `libflutter.so` -> Flutter;
   - `assemblies/assemblies.blob` or `lib/<abi>/libassemblies.<abi>.blob.so` -> Xamarin / .NET MAUI.
2. Pick a read-only inspection command first when possible:
   - APK resources and smali: `jddlab_apktool` with `["d", "-o", "<out>", "<apk>"]`.
   - Java source recovery from APK/DEX/JAR: `jddlab_jadx`, then `jddlab_cfr`, `jddlab_vineflower`, `jddlab_fernflower`, or `jddlab_procyon` (on a jar) as second opinions.
   - DEX/JAR conversion: `jddlab_dex2jar`, `jddlab_jar2dex`, `jddlab_dex2smali`, or `jddlab_smali`.
   - Native code: `jddlab_ghidra_decompile`.
   - React Native Hermes bytecode: `jddlab_hbc_file_parser`, `jddlab_hbc_decompiler`, `jddlab_hbc_disassembler`.
   - Flutter: `jddlab_blutter` on the extracted `lib/arm64-v8a` directory (first run per Dart version takes minutes: use a large `timeout_seconds`).
   - Xamarin / .NET MAUI: `jddlab_pyxamstore` to extract the DLLs, then `jddlab_ilspycmd` to decompile them to C#.
   - Security review of decompiled sources: `jddlab_mobsfscan`; secrets: `jddlab_apkscan`; malware behaviour: `jddlab_quark`.
   - Certificate pinning or Frida patching: `jddlab_android_unpinner`, `jddlab_apk_patcher`, or `jddlab_objection`.
   - Dynamic analysis on a device: `jddlab_adb`, `jddlab_frida_ps`, `jddlab_frida` (non-interactive: `-q` with `-l`/`-e` and `-t <seconds>`), `jddlab_frida_trace` (always with `timeout_seconds`). These use the host ADB server when it is running, so device connections persist between calls; if `adb devices` shows nothing, ask the user to run `adb start-server` and connect the device on the host.
3. Supply `input_paths` and `output_paths` so the server can infer the Docker mount root and rewrite paths to `/work`.
4. Use `extra_mounts` for ADB keys or persistent Android state, for example `{"host": "~/.android", "container": "/root/.android", "mode": "rw"}`.
5. If a command fails because of an unknown option, run that tool with `["--help"]`, `["-h"]`, or the command-specific help mode documented in `tools`.
