# jddlab Reverse Engineering Workflow

Target: {target}

Goal: {goal}

You are using the jddlab MCP server. Prefer the most specific MCP tool for the command, and pass command-line arguments in the `args` array exactly as the native tool expects them.

Workflow:

1. Identify the target type: APK/XAPK/APKS, DEX, JAR, class file, smali tree, native library, or mixed project.
2. Pick a read-only inspection command first when possible:
   - APK resources and smali: `jddlab_apktool` with `["d", "-o", "<out>", "<apk>"]`.
   - Java source recovery from APK/DEX/JAR: `jddlab_jadx`, `jddlab_vineflower`, `jddlab_fernflower`, or `jddlab_procyon`.
   - DEX/JAR conversion: `jddlab_dex2jar`, `jddlab_jar2dex`, `jddlab_dex2smali`, or `jddlab_smali`.
   - Native code: `jddlab_ghidra_decompile`.
   - Certificate pinning or Frida patching: `jddlab_android_unpinner`, `jddlab_apk_patcher`, or `jddlab_objection`.
3. Supply `input_paths` and `output_paths` so the server can infer the Docker mount root and rewrite paths to `/work`.
4. Use `extra_mounts` for ADB keys or persistent Android state, for example `{"host": "~/.android", "container": "/root/.android", "mode": "rw"}`.
5. If a command fails because of an unknown option, run that tool with `["--help"]`, `["-h"]`, or the command-specific help mode documented in `tools`.
