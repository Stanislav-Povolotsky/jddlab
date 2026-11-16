---
name: native-jni-analysis
description: Analyze an app's native (.so) / JNI code with jddlab - map Java native methods to symbols, extract JNI bindings, and decompile ARM/ARM64 with Ghidra headless. Use when security logic (keys, pinning, root/tamper checks) lives in native libraries.
---

# Native library and JNI analysis with jddlab

Version 1.0, 2026-08.

How to analyze the native (`.so`) side of an Android app: map JNI methods to their
native implementations, decompile ARM/ARM64/x86 code with headless Ghidra, and tie it
back to the Java layer. Every tool runs inside the `stanislavpovolotsky/jddlab` Docker
container through the jddlab MCP server.


## Table of contents

1. [Why native analysis](#1-why-native-analysis)
2. [Toolchain overview](#2-toolchain-overview)
3. [Step 1: extract native libraries & JNI bindings](#3-step-1-extract-native-libraries--jni-bindings)
4. [Step 2: map Java `native` methods to symbols](#4-step-2-map-java-native-methods-to-symbols)
5. [Step 3: decompile with Ghidra (headless)](#5-step-3-decompile-with-ghidra-headless)
6. [Step 4: custom Ghidra scripts](#6-step-4-custom-ghidra-scripts)
7. [Reading the output & common targets](#7-reading-the-output--common-targets)
8. [Troubleshooting](#8-troubleshooting)


## 1. Why native analysis

Apps often keep security logic in native code: string and crypto key storage, TLS
pinning, root/tamper detection, license checks, DRM. When the Java layer only calls
`native` methods, the logic is in `lib/<abi>/*.so` and you have to analyze the machine
code.


## 2. Toolchain overview

| Task | jddlab MCP tool | Native command |
|---|---|---|
| Extract JNI/native artifacts from an APK | `jddlab_extract_jni` | `extract_jni` |
| Decompile a native binary | `jddlab_ghidra_decompile` | `ghidra-decompile` |
| Full Ghidra headless analyzer | `jddlab_ghidra` | `ghidra` |
| Decompile Java to find `native` decls | `jddlab_jadx` | `jadx` |
| Decode APK to reach `lib/` cleanly | `jddlab_apktool` | `apktool d` |

`.so` files are ELF shared objects. There is one per ABI: `arm64-v8a` (most modern
phones), `armeabi-v7a` (older/32-bit), `x86_64`/`x86` (emulators). Analyze the ABI you
run on, usually `arm64-v8a`.


## 3. Step 1: extract native libraries & JNI bindings

`extract_jni` parses an APK and lists its JNI method signatures, which helps match
Java `native` methods to native functions. Its CLI is
`extract_jni <apk> [-o <file.json>]`: with `-o` it writes a JSON file (not a
directory), without `-o` it prints the JSON to stdout.

```json
{
  "tool": "jddlab_extract_jni",
  "args": ["target.apk", "-o", "jni_methods.json"],
  "input_paths": ["target.apk"],
  "output_paths": ["jni_methods.json"]
}
```

> `extract_jni` only reports the JNI method signatures; it doesn't extract the `.so`
> files. Get the binaries with `apktool`/`jadx` (below).

If you just need the raw `.so` files, decode the APK and read `lib/<abi>/`:

```json
{
  "tool": "jddlab_apktool",
  "args": ["d", "target.apk", "-o", "dec", "-f", "-s"],
  "input_paths": ["target.apk"],
  "output_paths": ["dec"]
}
```

(`-s` skips smali for speed; `lib/` is still extracted.)


## 4. Step 2: map Java `native` methods to symbols

There are two JNI binding styles.

a) Static binding (exported symbols). The native function is named
`Java_<pkg>_<Class>_<method>`. Decompile Java with `jddlab_jadx`, find the `native`
declarations, then match them to exports in the `.so` (e.g. `Java_com_example_Crypto_decrypt`).

To list exported symbols, use an interactive jddlab shell (binutils is in the image):

```bash
jddlab            # opens a shell in the container, current dir mounted at /work
nm -D --defined-only dec/lib/arm64-v8a/libnative.so | grep Java_
# or: readelf -Ws dec/lib/arm64-v8a/libnative.so | grep Java_
```

Ghidra's symbol tree (§5) also lists the `Java_...` exports directly, so you can skip
this step if you go straight to decompilation.

b) Dynamic binding (`RegisterNatives`). There are no `Java_...` exports: the app
registers methods at runtime, usually from `JNI_OnLoad`. Start your Ghidra analysis at
`JNI_OnLoad`, find the `RegisterNatives` call, and read the `JNINativeMethod` table
(method name, signature, function pointer) it passes. `extract_jni` (§3) often surfaces
this mapping for you.


## 5. Step 3: decompile with Ghidra (headless)

`ghidra-decompile` runs Ghidra headless and writes decompiled C for a binary. Its CLI
is positional, `ghidra-decompile <input-binary> [<output.c>]`, and the output is a
single `.c` file (`<input>.c` if you omit it). Don't pass `-i`/`-o` flags or a
directory:

```json
{
  "tool": "jddlab_ghidra_decompile",
  "args": ["dec/lib/arm64-v8a/libnative.so", "libnative.decompiled.c"],
  "input_paths": ["dec/lib/arm64-v8a/libnative.so"],
  "output_paths": ["libnative.decompiled.c"],
  "timeout_seconds": 3600
}
```

Ghidra analysis needs a lot of CPU and RAM: give it a large `timeout_seconds` and
enough Docker memory. The decompiled C can be large; grep it for the JNI functions
(`Java_...`) instead of reading it whole. See `tools/ghidra-decompile.md` for details.

For a full project (multiple binaries, scripting, cross-references), use the headless
analyzer directly via `jddlab_ghidra` with a project dir and `-import`.


## 6. Step 4: custom Ghidra scripts

The image bundles a decompile script for headless use, and you can run your own
analysis scripts through the full `ghidra` analyzer. A typical headless call:

```json
{
  "tool": "jddlab_ghidra",
  "args": [
    "/work/ghidra_proj", "proj",
    "-import", "dec/lib/arm64-v8a/libnative.so",
    "-postScript", "MyAnalysis.java",
    "-scriptPath", "/work/scripts"
  ],
  "input_paths": ["dec/lib/arm64-v8a/libnative.so", "scripts"],
  "output_paths": ["ghidra_proj"],
  "timeout_seconds": 3600
}
```

Use post-scripts to auto-locate `RegisterNatives`, dump strings/xrefs, or emit
decompiled C for just the JNI-exported functions. See the bundled
`ghidra/custom-scripts/CustomDecompileScript.java` for a starting template.


## 7. Reading the output & common targets

Once you have decompiled C, focus on what the Java layer delegated to native:

- String/key hiding: look for byte arrays assembled at runtime, XOR/AES loops, and
  `AStrcpy`/`memcpy` into a decrypt buffer. Cross-reference with strings that never
  appear in the Java layer.
- Root/tamper detection: `stat`/`access` on `/system/bin/su`, `getprop`,
  `/proc/self/maps` reads, package-name checks, signature (`GET_SIGNATURES`) verified
  natively.
- TLS pinning in native code: BoringSSL/OpenSSL calls (`SSL_CTX_set_custom_verify`,
  `SSL_get_peer_certificate`), embedded certificate/pubkey hashes.
- Anti-Frida/anti-debug: scans of `/proc/self/maps` for `frida`/`gum`, `ptrace`
  self-attach, thread-name checks.

To defeat a native check, patch the `.so` (flip a branch or return a constant), then
repackage, align, sign and reinstall the APK (see the android-apk-patch and
ssl-unpinning skills).


## 8. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| No `Java_...` symbols in the `.so` | Dynamic binding via `RegisterNatives` | Start at `JNI_OnLoad`; read the `JNINativeMethod` table (§4b) |
| Ghidra times out / OOM | Large or heavily-obfuscated binary | Raise `timeout_seconds`; give Docker more RAM; scope to one function |
| Decompiled C is garbage | Packed/encrypted `.so` or wrong arch | Confirm ABI; check for a native packer that decrypts at load |
| Can't find the right `.so` | Multiple libs / stripped names | Match against Java `native` methods; grep exports for `Java_`/method names |
| Strings absent from binary | Runtime-decrypted in native | Locate the decrypt routine; emulate or hook it (Frida) to dump plaintext |
