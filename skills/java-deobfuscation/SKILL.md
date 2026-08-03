# Java & Android Deobfuscation - jddlab Edition
**Version**: 1.0 | **Last Updated**: 2026-08 | **Difficulty**: Advanced

> How to identify and reverse common Java/Android obfuscation (ProGuard/R8, string
> encryption, control-flow tricks, commercial protectors) using **jddlab** tools.
> Every tool runs inside the `stanislavpovolotsky/jddlab` Docker container via the
> **jddlab MCP server** - no local installation required beyond Docker.

---

## Table of Contents

1. [Toolchain Overview](#1-toolchain-overview)
2. [Step 0: Get Bytecode into a JAR](#2-step-0-get-bytecode-into-a-jar)
3. [Step 1: Detect the Obfuscator](#3-step-1-detect-the-obfuscator)
4. [Step 2: Transform with java-deobfuscator](#4-step-2-transform-with-java-deobfuscator)
5. [Step 3: String Decryption](#5-step-3-string-decryption)
6. [Step 4: Simplify (Android VM Deobfuscator)](#6-step-4-simplify-android-vm-deobfuscator)
7. [Step 5: Read the Result](#7-step-5-read-the-result)
8. [Recompiling Back to DEX/APK](#8-recompiling-back-to-dexapk)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Toolchain Overview

| Task | jddlab MCP tool | Native command |
|---|---|---|
| Detect obfuscator/transformers | `jddlab_java_deobfuscator_detect` | `java-deobfuscator-detect` |
| Deobfuscate with config | `jddlab_java_deobfuscator` | `java-deobfuscator` |
| Android VM-based deobfuscation | `jddlab_simplify` | `simplify` |
| dex2jar string decryption | `jddlab_d2j_decrypt_string` | `d2j-decrypt-string` |
| DEX/APK → JAR | `jddlab_dex2jar` | `dex2jar` |
| JAR → DEX (recompile) | `jddlab_jar2dex` / `jddlab_d2j_jar2dex` | `jar2dex` / `d2j-jar2dex` |
| Read result as Java | `jddlab_jadx` / `jddlab_vineflower` / `jddlab_procyon` | `jadx` / `vineflower` / `procyon` |

**Rule of thumb:** `simplify` targets **Dalvik/Android** (DEX) and virtualized/reflection
obfuscation. `java-deobfuscator` targets **JVM bytecode** (JAR) and commercial Java
protectors (Zelix, Allatori, Stringer, DashO, Skidfuscator, etc.). Convert with
`dex2jar` when you need to move between the two worlds.

---

## 2. Step 0: Get Bytecode into a JAR

`java-deobfuscator` works on JVM `.jar`/`.class`. Convert an APK/DEX first:

```json
{
  "tool": "jddlab_dex2jar",
  "args": ["target.apk", "-o", "target.jar"],
  "input_paths": ["target.apk"],
  "output_paths": ["target.jar"]
}
```

Keep the original DEX too - some Android-specific obfuscation (see §6) is easier to
handle with `simplify` directly on the DEX.

---

## 3. Step 1: Detect the Obfuscator

Before transforming, identify which transformers apply. Guessing wastes time and can
corrupt the jar.

```json
{
  "tool": "jddlab_java_deobfuscator_detect",
  "args": ["target.jar"],
  "input_paths": ["target.jar"]
}
```

The output lists detected obfuscators / applicable transformers. Note them - you will
enable exactly those in the config in the next step. Also look at `jadx` output for
tell-tale signs:

- Meaningless single-letter/`Il1I` class & method names → name obfuscation (usually
  cosmetic; decompilers handle it).
- `((String) someDecrypt(0x1234))` wrappers everywhere → string encryption (§5).
- Huge `switch` on an int with `goto`-like flow → control-flow flattening.
- Classes loaded via `Class.forName` / reflection only → reflection obfuscation.

---

## 4. Step 2: Transform with java-deobfuscator

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
  "args": ["-config", "deobf-config.yml"],
  "input_paths": ["deobf-config.yml", "target.jar"],
  "output_paths": ["target-deobf.jar"]
}
```

Iterate: enable one transformer family at a time, re-decompile, and check the diff.
Enabling everything at once often fails on the first incompatible class.

---

## 5. Step 3: String Decryption

Two independent approaches - try both:

**A) java-deobfuscator string transformer** (JVM): add the matching
`*.StringEncryptionTransformer` for the detected protector to the config above.

**B) dex2jar string decryption** (works from the DEX side, no config needed):

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

---

## 6. Step 4: Simplify (Android VM Deobfuscator)

`simplify` executes the app's Dalvik code in a virtual machine and constant-folds the
result - excellent against reflection, string decryption routines, and dead-code
padding on **Android**. It works on a smali directory or a DEX.

Disassemble to smali first (if needed):

```json
{
  "tool": "jddlab_baksmali",
  "args": ["d", "classes.dex", "-o", "smali_in"],
  "input_paths": ["classes.dex"],
  "output_paths": ["smali_in"]
}
```

Run simplify:

```json
{
  "tool": "jddlab_simplify",
  "args": ["-i", "smali_in", "-o", "out.dex"],
  "input_paths": ["smali_in"],
  "output_paths": ["out.dex"],
  "timeout_seconds": 3600
}
```

Simplify can be slow and memory-hungry on large apps - scope it to the obfuscated
classes (pass a smaller smali subtree) and raise `timeout_seconds` / `JAVA_OPTS`.

---

## 7. Step 5: Read the Result

Decompile the cleaned artifact and compare against the original:

```json
{
  "tool": "jddlab_jadx",
  "args": ["-d", "deobf_src", "target-deobf.jar"],
  "input_paths": ["target-deobf.jar"],
  "output_paths": ["deobf_src"]
}
```

If jadx output is still messy on specific classes, cross-check with a second
decompiler - `jddlab_vineflower` and `jddlab_procyon` often recover different
constructs (loops, ternaries, switch-on-string).

---

## 8. Recompiling Back to DEX/APK

If you deobfuscated a JAR and want to run it on-device again:

```json
{
  "tool": "jddlab_jar2dex",
  "args": ["target-deobf.jar", "-o", "classes.dex"],
  "input_paths": ["target-deobf.jar"],
  "output_paths": ["classes.dex"]
}
```

Then rebuild/repackage the APK and re-sign it - see the **android-apk-patch** skill
(align → sign → verify). Note: deobfuscation changes bytecode, so the app must be
re-signed and any self-integrity checks may need patching.

---

## 9. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `java-deobfuscator` throws on a class | Wrong/too many transformers | Enable one family at a time; start with only the detected ones |
| Strings still encrypted after transform | Protector mismatch | Try `d2j-decrypt-string` (§5B) or `simplify` (§6) instead |
| `simplify` runs out of memory / times out | Whole-app VM execution | Scope to the obfuscated smali subtree; raise `timeout_seconds`, set `JAVA_OPTS=-Xmx6g` |
| Decompiler shows `// Bad`/garbage | Control-flow flattening remains | Run `simplify`, then re-decompile; compare vineflower vs procyon |
| Deobfuscated APK crashes on launch | Integrity/tamper check | Patch the check (see android-apk-patch skill §2.4) |
