# Native Library & JNI Analysis - jddlab Edition
**Version**: 1.0 | **Last Updated**: 2026-08 | **Difficulty**: Advanced

> How to analyze the native (`.so`) side of an Android app: map JNI methods to their
> native implementations, decompile ARM/ARM64/x86 code with **Ghidra (headless)**, and
> tie it back to the Java layer. Every tool runs inside the
> `stanislavpovolotsky/jddlab` Docker container via the **jddlab MCP server**.

---

## Table of Contents

1. [Why Native Analysis](#1-why-native-analysis)
2. [Toolchain Overview](#2-toolchain-overview)
3. [Step 1: Extract Native Libraries & JNI Bindings](#3-step-1-extract-native-libraries--jni-bindings)
4. [Step 2: Map Java `native` Methods to Symbols](#4-step-2-map-java-native-methods-to-symbols)
5. [Step 3: Decompile with Ghidra (headless)](#5-step-3-decompile-with-ghidra-headless)
6. [Step 4: Custom Ghidra Scripts](#6-step-4-custom-ghidra-scripts)
7. [Reading the Output & Common Targets](#7-reading-the-output--common-targets)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. Why Native Analysis

Apps increasingly move security-critical logic into native code: string/crypto key
storage, TLS pinning, root/tamper detection, license checks, and DRM. When the Java
layer is a thin shell that calls `native` methods, the real logic is in
`lib/<abi>/*.so` and you must analyze the machine code.

---

## 2. Toolchain Overview

| Task | jddlab MCP tool | Native command |
|---|---|---|
| Extract JNI/native artifacts from an APK | `jddlab_extract_jni` | `extract_jni` |
| Decompile a native binary | `jddlab_ghidra_decompile` | `ghidra-decompile` |
| Full Ghidra headless analyzer | `jddlab_ghidra` | `ghidra` |
| Decompile Java to find `native` decls | `jddlab_jadx` | `jadx` |
| Decode APK to reach `lib/` cleanly | `jddlab_apktool` | `apktool d` |

`.so` files are ELF shared objects. There is one per ABI: `arm64-v8a` (most modern
phones), `armeabi-v7a` (older/32-bit), `x86_64`/`x86` (emulators). Analyze the ABI you
run on - usually `arm64-v8a`.

---

## 3. Step 1: Extract Native Libraries & JNI Bindings

`extract_jni` pulls native libraries and their JNI method bindings out of an APK,
which helps correlate Java `native` methods with exported symbols:

```json
{
  "tool": "jddlab_extract_jni",
  "args": ["target.apk", "-o", "jni_out"],
  "input_paths": ["target.apk"],
  "output_paths": ["jni_out"]
}
```

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

---

## 4. Step 2: Map Java `native` Methods to Symbols

Two JNI binding styles - know which you're facing:

**a) Static binding (exported symbols).** The native function is named
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

**b) Dynamic binding (`RegisterNatives`).** No `Java_...` exports - the app registers
methods at runtime, usually from `JNI_OnLoad`. Start your Ghidra analysis at
`JNI_OnLoad`, find the `RegisterNatives` call, and read the `JNINativeMethod` table
(method name, signature, function pointer) it passes. `extract_jni` (§3) often surfaces
this mapping for you.

---

## 5. Step 3: Decompile with Ghidra (headless)

`ghidra-decompile` runs Ghidra headless and emits decompiled C for a binary:

```json
{
  "tool": "jddlab_ghidra_decompile",
  "args": ["-i", "dec/lib/arm64-v8a/libnative.so", "-o", "ghidra_out"],
  "input_paths": ["dec/lib/arm64-v8a/libnative.so"],
  "output_paths": ["ghidra_out"],
  "timeout_seconds": 3600
}
```

Ghidra analysis is CPU/RAM heavy - give it a generous `timeout_seconds` and ensure
Docker has enough memory. See `tools/ghidra-decompile.md` for input/output flags.

For a full project (multiple binaries, scripting, cross-references), use the headless
analyzer directly via `jddlab_ghidra` with a project dir and `-import`.

---

## 6. Step 4: Custom Ghidra Scripts

The image bundles a headless-friendly decompile script; you can run your own analysis
scripts through the full `ghidra` analyzer. A typical headless invocation:

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

---

## 7. Reading the Output & Common Targets

Once you have decompiled C, focus on what the Java layer delegated to native:

- **String/key hiding:** look for byte arrays assembled at runtime, XOR/AES loops, and
  `AStrcpy`/`memcpy` into a decrypt buffer. Cross-reference with strings that never
  appear in the Java layer.
- **Root/tamper detection:** `stat`/`access` on `/system/bin/su`, `getprop`,
  `/proc/self/maps` reads, package-name checks, signature (`GET_SIGNATURES`) verified
  natively.
- **TLS pinning in native:** BoringSSL/OpenSSL calls (`SSL_CTX_set_custom_verify`,
  `SSL_get_peer_certificate`), embedded certificate/pubkey hashes.
- **Anti-Frida/anti-debug:** scans of `/proc/self/maps` for `frida`/`gum`, `ptrace`
  self-attach, thread-name checks.

To defeat a native check you typically patch the `.so` (flip a branch / return
constant) and repackage the APK - align, sign, and reinstall (see the
**android-apk-patch** and **ssl-unpinning** skills).

---

## 8. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| No `Java_...` symbols in the `.so` | Dynamic binding via `RegisterNatives` | Start at `JNI_OnLoad`; read the `JNINativeMethod` table (§4b) |
| Ghidra times out / OOM | Large or heavily-obfuscated binary | Raise `timeout_seconds`; give Docker more RAM; scope to one function |
| Decompiled C is garbage | Packed/encrypted `.so` or wrong arch | Confirm ABI; check for a native packer that decrypts at load |
| Can't find the right `.so` | Multiple libs / stripped names | Match against Java `native` methods; grep exports for `Java_`/method names |
| Strings absent from binary | Runtime-decrypted in native | Locate the decrypt routine; emulate or hook it (Frida) to dump plaintext |
