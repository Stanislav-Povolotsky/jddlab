---
name: java-deobfuscation
description: Detect and reverse Java/Android obfuscation with jddlab - ProGuard/R8 renaming, string encryption, control-flow flattening and commercial protectors, using java-deobfuscator, simplify and dex2jar. Use when decompiled code is obfuscated or strings are encrypted.
---

# Java and Android deobfuscation with jddlab

Version 1.0, 2026-08.

How to identify and reverse common Java/Android obfuscation (ProGuard/R8, string
encryption, control-flow tricks, commercial protectors) with jddlab tools. Every tool
runs inside the `stanislavpovolotsky/jddlab` Docker container through the jddlab MCP
server, so Docker is the only local requirement.


## Table of contents

1. [Toolchain overview](#1-toolchain-overview)
2. [Step 0: get bytecode into a JAR](#2-step-0-get-bytecode-into-a-jar)
3. [Step 1: detect the obfuscator](#3-step-1-detect-the-obfuscator)
4. [Step 2: transform with java-deobfuscator](#4-step-2-transform-with-java-deobfuscator)
5. [Step 3: string decryption](#5-step-3-string-decryption)
6. [Step 4: Simplify (Android VM deobfuscator)](#6-step-4-simplify-android-vm-deobfuscator)
7. [Step 5: read the result](#7-step-5-read-the-result)
8. [Recompiling back to DEX/APK](#8-recompiling-back-to-dexapk)
9. [Troubleshooting](#9-troubleshooting)


## 1. Toolchain overview

| Task | jddlab MCP tool | Native command |
|---|---|---|
| Detect obfuscator/transformers | `jddlab_java_deobfuscator_detect` | `java-deobfuscator-detect` |
| Deobfuscate with config | `jddlab_java_deobfuscator` | `java-deobfuscator` |
| Android VM-based deobfuscation | `jddlab_simplify` | `simplify` |
| dex2jar string decryption | `jddlab_d2j_decrypt_string` | `d2j-decrypt-string` |
| DEX/APK → JAR | `jddlab_dex2jar` | `dex2jar` |
| JAR → DEX (recompile) | `jddlab_jar2dex` / `jddlab_d2j_jar2dex` | `jar2dex` / `d2j-jar2dex` |
| Read result as Java | `jddlab_jadx` / `jddlab_vineflower` / `jddlab_procyon` | `jadx` / `vineflower` / `procyon` |

`simplify` works on Dalvik bytecode (DEX) and handles virtualized and reflection-based
obfuscation. `java-deobfuscator` works on JVM bytecode (JAR) and knows commercial Java
protectors (Zelix, Allatori, Stringer, DashO, Skidfuscator and others). Use `dex2jar`
to convert between the two.


## 2. Step 0: get bytecode into a JAR

`java-deobfuscator` works on JVM `.jar`/`.class`. Convert an APK/DEX first:

```json
{
  "tool": "jddlab_dex2jar",
  "args": ["target.apk", "-o", "target.jar"],
  "input_paths": ["target.apk"],
  "output_paths": ["target.jar"]
}
```

Keep the original DEX as well: some Android-specific obfuscation (see §6) is easier
to handle with `simplify` directly on the DEX.


## 3. Step 1: detect the obfuscator

Find out which transformers apply before transforming anything. Enabling the wrong
ones wastes time and can corrupt the jar.

```json
{
  "tool": "jddlab_java_deobfuscator_detect",
  "args": ["target.jar"],
  "input_paths": ["target.jar"]
}
```

The output lists the detected obfuscators and the transformers that apply; enable
exactly those in the config in the next step. The `jadx` output also shows typical
signs:

- Meaningless single-letter/`Il1I` class & method names → name obfuscation (usually
  cosmetic; decompilers handle it).
- `((String) someDecrypt(0x1234))` wrappers everywhere → string encryption (§5).
- Huge `switch` on an int with `goto`-like flow → control-flow flattening.
- Classes loaded via `Class.forName` / reflection only → reflection obfuscation.


## 4. Step 2: transform with java-deobfuscator

`java-deobfuscator` is config-driven (YAML). A minimal config:

```yaml
# deobf-config.yml
input: /work/target.jar
output: /work/target-deobf.jar
transformers:
  - com.javadeobfuscator.deobfuscator.transformers.general.SynchronizedTransformer
  # add the transformers reported by the detect step, e.g.:
  # - com.javadeobfuscator.deobfuscator.transformers.stringer.StringEncryptionTransformer
  # - com.javadeobfuscator.deobfuscator.transformers.zelix.StringEncryptionTransformer
```

> Paths inside the YAML are container paths. Since jddlab mounts your working dir as
> `/work`, use `/work/...` in the config, or pass paths on the command line instead.

Run it:

```json
{
  "tool": "jddlab_java_deobfuscator",
  "args": ["--config", "deobf-config.yml"],
  "input_paths": ["deobf-config.yml", "target.jar"],
  "output_paths": ["target-deobf.jar"]
}
```

> The flag is `--config` (two dashes). Many transformers also need the Android
> framework classes on the classpath: add a `path:` section to the YAML pointing at
> `/usr/local/android-sdk-linux/platforms/android-*/android.jar` if a transformer
> complains about missing classes.

Enable one transformer family at a time, re-decompile and check the diff. With
everything enabled at once the run often fails on the first incompatible class.


## 5. Step 3: string decryption

There are two independent approaches; try both.

A) java-deobfuscator string transformer (JVM): add the matching
`*.StringEncryptionTransformer` for the detected protector to the config above.

B) dex2jar string decryption, which works on the DEX side and needs no config:

```json
{
  "tool": "jddlab_d2j_decrypt_string",
  "args": ["target.apk", "-o", "target-decrypted.jar"],
  "input_paths": ["target.apk"],
  "output_paths": ["target-decrypted.jar"]
}
```

`d2j-decrypt-string` can invoke a named decrypt method; consult
`jddlab d2j-decrypt-string --help` (or `tools/d2j-decrypt-string.md`) for the
`--decrypt-method`/`--decrypt-classes` selectors when auto-detection misses.


## 6. Step 4: Simplify (Android VM deobfuscator)

`simplify` executes the app's Dalvik code in a virtual machine and constant-folds the
result. It works well against reflection, string decryption routines and dead-code
padding, on a smali directory or a DEX.

Disassemble to smali first (if needed):

```json
{
  "tool": "jddlab_baksmali",
  "args": ["d", "classes.dex", "-o", "smali_in"],
  "input_paths": ["classes.dex"],
  "output_paths": ["smali_in"]
}
```

Run simplify. The input is a positional argument (`simplify <input> [options]`) and
`-o` is the output; there is no `-i`:

```json
{
  "tool": "jddlab_simplify",
  "args": ["smali_in", "-o", "out.dex"],
  "input_paths": ["smali_in"],
  "output_paths": ["out.dex"],
  "timeout_seconds": 3600
}
```

On large apps simplify is slow and needs a lot of memory: limit it to the obfuscated
classes (pass a smaller smali subtree) and raise `timeout_seconds` / `JAVA_OPTS`.


## 7. Step 5: read the result

Decompile the cleaned artifact and compare against the original:

```json
{
  "tool": "jddlab_jadx",
  "args": ["-d", "deobf_src", "target-deobf.jar"],
  "input_paths": ["target-deobf.jar"],
  "output_paths": ["deobf_src"]
}
```

If jadx output is still messy for some classes, try a second decompiler:
`jddlab_cfr`, `jddlab_vineflower` and `jddlab_procyon` often recover loops, ternaries
and string switches differently.


## 8. Recompiling back to DEX/APK

If you deobfuscated a JAR and want to run it on-device again:

```json
{
  "tool": "jddlab_jar2dex",
  "args": ["target-deobf.jar", "-o", "classes.dex"],
  "input_paths": ["target-deobf.jar"],
  "output_paths": ["classes.dex"]
}
```

Then repackage the APK and re-sign it (align, sign, verify; see the android-apk-patch
skill). Deobfuscation changes the bytecode, so the app must be re-signed, and its own
integrity checks may need patching.


## 9. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `java-deobfuscator` throws on a class | Wrong/too many transformers | Enable one family at a time; start with only the detected ones |
| Strings still encrypted after transform | Protector mismatch | Try `d2j-decrypt-string` (§5B) or `simplify` (§6) instead |
| `simplify` runs out of memory / times out | Whole-app VM execution | Scope to the obfuscated smali subtree; raise `timeout_seconds`, set `JAVA_OPTS=-Xmx6g` |
| Decompiler shows `// Bad`/garbage | Control-flow flattening remains | Run `simplify`, then re-decompile; compare vineflower vs procyon |
| Deobfuscated APK crashes on launch | Integrity/tamper check | Patch the check (see android-apk-patch skill §2.4) |
