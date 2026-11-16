---
name: android-apk-patch
description: Patch, rebuild, re-sign and install Android APKs with jddlab - edit smali/resources/manifest, decompile with apktool/jadx, handle split APKs, align and sign. Use for APK modding, repackaging, or injecting changes into an app.
---

# Android APK patching and repackaging with jddlab

Version 1.0, 2025-08.

How to modify Android APKs with jddlab: analysis, smali editing, recompilation,
signing and testing. Every tool runs inside the `stanislavpovolotsky/jddlab` Docker
container through the jddlab MCP server, so Docker is the only local requirement.


## Table of contents

1. [jddlab toolchain overview](#1-jddlab-toolchain-overview)
2. [Decompilation & recompilation workflow](#2-decompilation--recompilation-workflow)
3. [Split APK handling (.apks / .apkm / .xapk)](#3-split-apk-handling)
4. [Signing: align then sign](#4-signing-align-then-sign)
5. [Dependency hell: frameworks, AndroidX, OEM resources](#5-dependency-hell)
6. [GApps-dependent APKs: patching & workarounds](#6-gapps-dependent-apks)
7. [Testing: ADB, Redroid, Waydroid](#7-testing)
8. [Advanced patching: Frida, obfuscation, integrity checks](#8-advanced-patching)
9. [Troubleshooting](#9-troubleshooting)
10. [Quick reference cheat sheet](#10-quick-reference-cheat-sheet)


## 1. jddlab toolchain overview

jddlab bundles the tools in one Docker image. Use them through the jddlab MCP server
(`jddlab_*` tools); the server runs Docker, picks the mount root and rewrites paths.

### 1.1 Tool mapping

| Task | jddlab MCP tool | Native command |
|---|---|---|
| Analyze / decompile to Java source | `jddlab_jadx` | `jadx` |
| Decompile APK to smali + resources | `jddlab_apktool` | `apktool d` |
| Rebuild smali + resources to APK | `jddlab_apktool` | `apktool b` |
| Merge a split-APK set into one APK | `jddlab_APKEditor` | `APKEditor m` |
| Align APK (before signing) | `jddlab_zipalign` | `zipalign` |
| Sign APK (v1/v2/v3) | `jddlab_apksigner` | `apksigner sign` |
| Verify signature | `jddlab_apksigner` | `apksigner verify` |
| Decompile to higher-level Java | `jddlab_vineflower` / `jddlab_fernflower` / `jddlab_procyon` | `vineflower` / `fernflower` / `procyon` |
| Disassemble DEX to smali | `jddlab_baksmali` | `baksmali` |
| Assemble smali to DEX | `jddlab_smali` | `smali` |
| Convert DEX/APK → JAR | `jddlab_dex2jar` | `dex2jar` |
| Certificate pinning bypass | `jddlab_android_unpinner` | `android-unpinner` |
| Frida gadget injection | `jddlab_apk_patcher` | `apk-patcher` |
| Runtime exploration (Frida CLI) | `jddlab_objection` | `objection` |
| Deobfuscation | `jddlab_java_deobfuscator` | `java-deobfuscator` |
| Deobfuscation detection | `jddlab_java_deobfuscator_detect` | `java-deobfuscator-detect` |
| Native code analysis | `jddlab_ghidra_decompile` | `ghidra-decompile` |

### 1.2 Tool versions

Old tool versions fail on current apps. The image is rebuilt when tools update, and
has at least:

- Apktool 2.9.0, needed for API 34+ resources (Android 14+);
- smali 3.0.5, needed for DEX format 038+ (Android 13+);
- apksigner from build-tools 35, for v2/v3/v4 signing.

Don't use `jarsigner`: it produces only v1 signatures, and apps targeting Android 11
(API 30) or newer must have a v2 signature.

### 1.3 MCP tool call structure

Every `jddlab_*` MCP tool accepts:

| Field | Type | Purpose |
|---|---|---|
| `args` | `string[]` | Native command arguments, verbatim |
| `input_paths` | `string[]` | Host input files/dirs, used to pick the mount root |
| `output_paths` | `string[]` | Host output files/dirs, used to pick the mount root |
| `workdir` | `string` | Optional explicit host directory to mount as `/work` |
| `extra_mounts` | `object[]` | Additional mounts `{host, container, mode}` |
| `timeout_seconds` | `number` | Override default 3600 s timeout |
| `docker_image` | `string` | Override Docker image |

Paths in `args` that match a file/dir under the inferred mount root are rewritten to
`/work/…` automatically.


## 2. Decompilation & recompilation workflow

### 2.1 Standard single APK workflow

**Step 1: analyze with jadx (read-only)**

```json
{
  "tool": "jddlab_jadx",
  "args": ["-d", "analysis_output", "target.apk"],
  "input_paths": ["target.apk"],
  "output_paths": ["analysis_output"]
}
```

**Step 2: decompile with apktool**

```json
{
  "tool": "jddlab_apktool",
  "args": ["d", "target.apk", "-o", "decompiled", "-f"],
  "input_paths": ["target.apk"],
  "output_paths": ["decompiled"]
}
```

**Step 3: edit smali, resources, manifest**

Edit the files in `decompiled/` on the host. §2.4 has smali patterns.

**Step 4: recompile**

```json
{
  "tool": "jddlab_apktool",
  "args": ["b", "decompiled", "-o", "rebuilt.apk"],
  "input_paths": ["decompiled"],
  "output_paths": ["rebuilt.apk"]
}
```

**Step 5: align (before signing)**

```json
{
  "tool": "jddlab_zipalign",
  "args": ["-v", "-p", "4", "rebuilt.apk", "rebuilt_aligned.apk"],
  "input_paths": ["rebuilt.apk"],
  "output_paths": ["rebuilt_aligned.apk"]
}
```

**Step 6: sign**

```json
{
  "tool": "jddlab_apksigner",
  "args": [
    "sign",
    "--ks", "/root/.android/debug.keystore",
    "--ks-key-alias", "androiddebugkey",
    "--ks-pass", "pass:android",
    "--key-pass", "pass:android",
    "rebuilt_aligned.apk"
  ],
  "input_paths": ["rebuilt_aligned.apk"],
  "output_paths": ["rebuilt_aligned.apk"]
}
```

The debug keystore is built into the image, so no `extra_mounts` are needed. To use
your own host key instead, add `"extra_mounts": [{"host": "~/.android", "container": "/root/.android", "mode": "ro"}]`.

**Step 7: verify**

```json
{
  "tool": "jddlab_apksigner",
  "args": ["verify", "--verbose", "--print-certs", "rebuilt_aligned.apk"],
  "input_paths": ["rebuilt_aligned.apk"]
}
```

**Step 8: install**

With `jddlab_adb` (`["install", "-r", "rebuilt_aligned.apk"]`; it uses the host ADB
server, see §7.1) or on the host:

```bash
adb install -r rebuilt_aligned.apk
```

### 2.2 Important decompilation flags

```json
// Force specific API level (fixes many resource resolution issues)
{"args": ["d", "target.apk", "-o", "out", "-f", "--api", "35"], ...}

// Ignore missing resources (new in apktool 2.11.x)
{"args": ["d", "target.apk", "-o", "out", "-f", "--ignore-missing-resources"], ...}

// Don't decode sources: keep classes.dex as is, decode resources (resource-only mods)
{"args": ["d", "target.apk", "-o", "out", "-f", "-s"], ...}

// Don't decode resources: keep resources.arsc as is, decode smali (code-only mods, faster)
{"args": ["d", "target.apk", "-o", "out", "-f", "-r"], ...}

// For Samsung/Android 15 framework JARs with DEX format 039
{"args": ["d", "framework.jar", "-api", "29", "-o", "out"], ...}
```

### 2.3 Decompiled directory structure

```
decompiled/
├── AndroidManifest.xml        # App manifest (editable XML)
├── apktool.yml                # Apktool metadata (do NOT manually edit version fields)
├── assets/                    # Raw asset files
├── lib/                       # Native libraries (.so) by architecture
│   ├── arm64-v8a/
│   ├── armeabi-v7a/
│   └── x86_64/
├── original/                  # Original META-INF files
├── res/                       # Compiled resources decoded to editable XML
│   ├── values/                # strings, styles, colors, dimensions
│   ├── layout/                # layout XML files
│   └── mipmap-*/              # app icons
├── smali/                     # Disassembled DEX (MAIN CODE)
└── smali_classes2/            # Additional DEX files (multi-dex apps)
```

### 2.4 Smali editing basics

```smali
# 1. Force a boolean method to always return true (premium check bypass)
.method public isPremium()Z
    .registers 2
    const/4 v0, 0x1        # true
    return v0
.end method

# 2. NOP out a method call
# Replace: invoke-virtual {v0}, Lcom/example/Payroll;->show()V
# With:    nop

# 3. Remove a permission check (always fall through)
# Replace: if-eqz v0, :cond_deny
# With:    nop

# 4. Set a string field
const-string v0, "patched_value"
iput-object v0, p0, Lcom/example/app/MainActivity;->mStatus:Ljava/lang/String;

# 5. Common signature check pattern to NOP
# Search smali for: getPackageInfo, GET_SIGNATURES, MessageDigest, equals
# Replace the comparison branch with: nop
```

### 2.5 Resource editing

```xml
<!-- res/values/strings.xml -->
<string name="app_name">My Patched App</string>

<!-- AndroidManifest.xml - add permissions -->
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" />

<!-- AndroidManifest.xml - export a hidden activity -->
<activity android:name=".HiddenActivity" android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.MAIN" />
        <category android:name="android.intent.category.LAUNCHER" />
    </intent-filter>
</activity>
```


## 3. Split APK handling

### 3.1 Understanding split APK formats

| Format | Source | Extension |
|---|---|---|
| Bundletool | Google Play | `.apks` |
| APKMirror | APKMirror | `.apkm` |
| APKPure | APKPure | `.xapk` |

All three are ZIP archives; extract them with any unzip tool on the host.

Split types: `base.apk` (core code), `split_config.arm64_v8a.apk` (ARM64 libs),
`split_config.xxhdpi.apk` (screen density resources), `split_config.en.apk` (language).

### 3.2 Merge → decompile → rebuild workflow

**Step 1: extract the splits on the host**

```bash
mkdir splits && cd splits
unzip ../input.apks   # or .apkm / .xapk
```

**Step 2: merge them into one APK**

```json
{
  "tool": "jddlab_APKEditor",
  "args": ["m", "-i", "splits/base.apk", "splits/split_config.arm64_v8a.apk", "splits/split_config.xxhdpi.apk", "splits/split_config.en.apk", "-o", "merged.apk"],
  "input_paths": ["splits"],
  "output_paths": ["merged.apk"]
}
```

**Step 3: decompile the merged APK**

```json
{
  "tool": "jddlab_apktool",
  "args": ["d", "merged.apk", "-o", "decompiled", "-f"],
  "input_paths": ["merged.apk"],
  "output_paths": ["decompiled"]
}
```

**Step 4: modify, recompile, align, sign** (§2.1, steps 3 to 7).

**Step 5: install the splits**

```bash
# If you only modified the base APK, keep original splits:
adb uninstall com.example.app
adb install-multiple modified_base_aligned.apk \
    splits/split_config.arm64_v8a.apk \
    splits/split_config.xxhdpi.apk \
    splits/split_config.en.apk
```

All splits of an app must be signed with the same key. If you re-signed the base APK,
re-sign every split with the same keystore:

```bash
for apk in splits/*.apk; do
    # align then sign each one via jddlab_zipalign + jddlab_apksigner
    ...
done
adb install-multiple modified_base_aligned.apk splits/*.apk
```

### 3.3 Split APK pitfalls

| Pitfall | Fix |
|---|---|
| Missing native libs after merge | Manually copy missing `.so` files into merged APK `lib/` before decompiling |
| `toc.pb` metadata mismatch | Use `adb install-multiple`, not bundletool, for patched installs |
| `null` resources on base APK decompilation | Merge with APKEditor first, or use `--ignore-missing-resources` |


## 4. Signing: align then sign

### 4.1 APK signature schemes

| Scheme | Since | Notes |
|---|---|---|
| v1 (JAR) | API 1 | Weak (files can be modified). Needed for Android < 7.0. |
| v2 | API 24 (Android 7.0) | Whole-APK signature. Required for apps targeting API 30+. |
| v3 | API 28 (Android 9.0) | v2 + key rotation support |
| v4 | API 30 (Android 11) | Merkle hash tree, computed on demand during install |

v2/v3 sign the whole APK, so any change after signing breaks them: run `zipalign`
before `apksigner`, never after. Don't use `jarsigner` (v1 only, see §1.2).

### 4.2 Available keystores

| Keystore | Location | Alias | Password | Notes |
|---|---|---|---|---|
| Built-in debug key | `/root/.android/debug.keystore` (inside image) | `androiddebugkey` | `android` | Default: built into the image, no `extra_mounts` needed |
| Host debug key | `~/.android/debug.keystore` (host mount) | `androiddebugkey` | `android` | Overrides built-in when mounted via `extra_mounts` |
| Custom | generate with `jddlab_keytool` (see below) | your choice | your choice | For release or reproducible builds |

Create a custom keystore via jddlab (no local JDK needed):

```json
{
  "tool": "jddlab_keytool",
  "args": ["-genkeypair", "-v",
    "-keystore", "my-key.jks",
    "-alias", "myapp",
    "-keyalg", "RSA", "-keysize", "2048",
    "-validity", "10000",
    "-storepass", "changeit",
    "-keypass", "changeit",
    "-dname", "CN=My App, OU=Dev, O=My Org, L=City, ST=State, C=US",
    "-storetype", "PKCS12",
    "-noprompt"],
  "output_paths": ["my-key.jks"]
}
```

### 4.3 Full signing workflow via jddlab

```json
// 1. Align
{
  "tool": "jddlab_zipalign",
  "args": ["-v", "-p", "4", "rebuilt.apk", "rebuilt_aligned.apk"],
  "input_paths": ["rebuilt.apk"],
  "output_paths": ["rebuilt_aligned.apk"]
}
```

```json
// 2a. Sign with built-in debug keystore (no extra_mounts needed)
{
  "tool": "jddlab_apksigner",
  "args": [
    "sign",
    "--ks", "/root/.android/debug.keystore",
    "--ks-key-alias", "androiddebugkey",
    "--ks-pass", "pass:android",
    "--key-pass", "pass:android",
    "--v1-signing-enabled", "true",
    "--v2-signing-enabled", "true",
    "--v3-signing-enabled", "true",
    "rebuilt_aligned.apk"
  ],
  "input_paths": ["rebuilt_aligned.apk"],
  "output_paths": ["rebuilt_aligned.apk"]
}
```

```json
// 2b. Sign with a custom host keystore
{
  "tool": "jddlab_apksigner",
  "args": [
    "sign",
    "--ks", "my-key.jks",
    "--ks-key-alias", "myapp",
    "--ks-pass", "pass:changeit",
    "--key-pass", "pass:changeit",
    "--v1-signing-enabled", "true",
    "--v2-signing-enabled", "true",
    "--v3-signing-enabled", "true",
    "rebuilt_aligned.apk"
  ],
  "input_paths": ["rebuilt_aligned.apk", "my-key.jks"],
  "output_paths": ["rebuilt_aligned.apk"]
}
```

```json
// 3. Verify
{
  "tool": "jddlab_apksigner",
  "args": ["verify", "--verbose", "--print-certs", "rebuilt_aligned.apk"],
  "input_paths": ["rebuilt_aligned.apk"]
}
```

### 4.4 Signature-related failures

| Error | Cause | Fix |
|---|---|---|
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | Different signing key from installed app | `adb uninstall com.example.app` then reinstall |
| `INSTALL_PARSE_FAILED_NO_CERTIFICATES` | APK not signed | Sign with `jddlab_apksigner` |
| App installs but crashes immediately | Runtime self-check via `getPackageInfo(GET_SIGNATURES)` | Patch smali signature check or use Frida bypass script |
| `INSTALL_FAILED_SESSION_INVALID` | Splits signed with different keys | Sign ALL splits with the same keystore |
| Signature broken after zipalign | Used `apksigner` before `zipalign` | Always: zipalign → then sign |


## 5. Dependency hell

### 5.1 Common resource errors

```
error: resource 'com.example:id/material_textinput' not found
error: style attribute 'attr/layout_constraintBaseline_toBaselineOf' not found
ERROR: AAPT2 aapt2(...) exited with code 1
```

### 5.2 Install OEM frameworks via jddlab

For system or OEM apps that reference non-AOSP framework resources, install their
framework files first:

```json
// Install Android framework (usually automatic)
{
  "tool": "jddlab_apktool",
  "args": ["if", "framework-res.apk"],
  "input_paths": ["framework-res.apk"]
}
```

```json
// Samsung example
{
  "tool": "jddlab_apktool",
  "args": ["if", "sec_platform_library.jar"],
  "input_paths": ["sec_platform_library.jar"]
}
```

Pull framework files from a rooted device first:

```bash
adb pull /system/framework/ ./device_frameworks/
```

Then install via the MCP tool above.

### 5.3 Force API level

```json
{"args": ["d", "target.apk", "-o", "out", "-f", "--api", "35"], ...}
// or for legacy:
{"args": ["d", "target.apk", "-o", "out", "-f", "--api", "29"], ...}
```

### 5.4 AAPT2 error reference

| Error | Cause | Fix |
|---|---|---|
| `resource has already been defined` | Duplicate resource | Apktool 2.11.0+ handles most; search for dupes in `res/values/*.xml` |
| `malformed compiled jar` | Samsung DEX 039 format in framework | Use `--api 29` |
| `no resource identifier found for attribute` | Missing library | Install library APK as framework |
| `unmarshalling resource table` | Corrupted `resources.arsc` | Use `--ignore-missing-resources` or merge first with APKEditor |
| `BufferOverflowException` | Resource table > 2 GB | Increase Java heap via `jddlab_run` with `JAVA_OPTS="-Xmx4g"` |


## 6. GApps-dependent APKs

### 6.1 Why GApps patching is hard

- ~100+ dynamic feature module splits
- Runtime signature verification by OS and other GApps
- DroidGuard/Play Integrity attestation baked in
- Automatic updates overwrite patches

Don't try to patch `com.google.android.gms` itself.

### 6.2 Strategy: MicroG

MicroG is an open-source replacement for Google Play Services. Install `GmsCore.apk` from
https://github.com/microg/GmsCore/releases on your test device/emulator alongside your
patched APK.

### 6.3 Strategy: patch individual GApps (YouTube, Maps, etc.)

ReVanced maintains patches for many Google apps: https://github.com/ReVanced/revanced-patches

To patch by hand, find the signature check in the smali:

```json
// Decompile and search
{
  "tool": "jddlab_jadx",
  "args": ["-d", "analysis", "google_app.apk"],
  "input_paths": ["google_app.apk"],
  "output_paths": ["analysis"]
}
```

Grep for: `getPackageInfo`, `GET_SIGNATURES`, `MessageDigest`, `equals`.
Patch the comparison branch to always return valid.

### 6.4 Certificate pinning bypass (automated)

`android-unpinner patch-apks` makes the APK debuggable and re-signs it
(`target.unpinned.apk`, no device needed). The pinning bypass itself is applied at
runtime: `start-app` (or `all`, which also installs the APK) starts the app on a
connected device and injects the Frida gadget with the unpinning scripts. See the
ssl-unpinning skill.

```json
{
  "tool": "jddlab_android_unpinner",
  "args": ["patch-apks", "target.apk"],
  "input_paths": ["target.apk"],
  "output_paths": ["target.unpinned.apk"]
}
```


## 7. Testing

### 7.1 ADB install commands (host, or `jddlab_adb`)

`jddlab_adb` (and `jddlab_frida*`, `jddlab_objection`) use the host ADB server when
one is running, so the device connected on the host (USB or Wi-Fi) is visible in every
MCP call. If `jddlab_adb ["devices"]` lists nothing, ask the user to run
`adb start-server` and connect the device on the host.

```bash
adb install -r app.apk              # Replace existing
adb install -d app.apk              # Allow version downgrade
adb install -g app.apk              # Grant all runtime permissions
adb install-multiple base.apk s1.apk s2.apk   # Split APKs
adb uninstall com.example.app       # Remove app + data
adb shell am start -n com.example.app/.MainActivity
adb logcat -s "AndroidRuntime:E" "*:S"
```

### 7.2 Frida injection via jddlab

Inject a Frida gadget into an APK for dynamic analysis (the gadget baked into the
image, no download). `apk-patcher` takes the APK base name without the extension but
with the trailing dot (`target.apk` -> `./target.`) as a positional argument and writes
`target.patched`. Flags are `-l <script>`,
`-a <arch>`, `-d <dir>`, `-c <config>`, `-f`, `-v` (there is no `-o`):

```json
{
  "tool": "jddlab_apk_patcher",
  "args": ["./target."],
  "input_paths": ["target.apk"],
  "output_paths": ["target.patched"]
}
```

Then re-sign the APK in `target.patched` with `jddlab_zipalign` and `jddlab_apksigner`.

### 7.3 Objection (runtime exploration via Frida)

```json
{
  "tool": "jddlab_objection",
  "args": ["patchapk", "-s", "target.apk", "-a", "arm64-v8a"],
  "input_paths": ["target.apk"],
  "output_paths": ["target.objection.apk"]
}
```

`patchapk` injects the gadget baked into the image and adds the INTERNET permission
the gadget needs to listen; without `-a` it asks the device for its ABI over ADB.
`objection explore` needs an interactive TTY. Through MCP, `objection -n Gadget run
"<command>"` works for one-shot commands (e.g. `android hooking list activities`), but
the agent is unloaded right after, so hooks such as `android sslpinning disable` don't
stay active; for those use `jddlab_frida` with a script and `-t`
(`["-U", "-n", "Gadget", "-l", "hook.js", "-q", "-t", "30"]`).

### 7.4 Redroid (Android in Docker, headless)

Redroid runs a full Android system in Docker without a display, which also works in CI.

```bash
# Prerequisites (Linux host only)
sudo modprobe binder_linux
docker volume create redroid_data

# Start Android 14 container
docker run -d --privileged --name redroid14 -p 5555:5555 \
    -v redroid_data:/data redroid/redroid:14.0.0-latest

# Connect ADB
adb connect localhost:5555

# Install patched APK
adb -s localhost:5555 install rebuilt_aligned.apk
adb -s localhost:5555 shell am start -n com.example.app/.MainActivity

# Mirror screen (optional)
scrcpy -s localhost:5555
```

ARM translation + Magisk (optional):

```bash
git clone https://github.com/abing7k/redroid-script.git
sudo python3 redroid-script/redroid-script.py redroid14 --magisk --libndk
docker restart redroid14
```

Redroid doesn't work on macOS: Docker Desktop has no binder support.

### 7.5 Waydroid (Android in LXC, Linux desktop)

```bash
curl https://repo.waydro.id | sudo bash
sudo apt install waydroid
sudo waydroid init
waydroid session start && waydroid show-full-ui

# Install patched APK
waydroid app install rebuilt_aligned.apk
waydroid app launch com.example.app

# ARM translation (CPU must have SSE 4.2)
git clone https://github.com/casualsnek/waydroid_script.git
sudo python3 waydroid_script/waydroid_script.py -l
```


## 8. Advanced patching

### 8.1 Deobfuscation via jddlab

Detect the obfuscator:

```json
{
  "tool": "jddlab_java_deobfuscator_detect",
  "args": ["target.jar"],
  "input_paths": ["target.jar"]
}
```

Run the deobfuscation. `java-deobfuscator` reads a YAML config (`--config`, two
dashes); the input, output and transformers are set in the YAML, not as CLI flags (the
java-deobfuscation skill has a config example):

```json
{
  "tool": "jddlab_java_deobfuscator",
  "args": ["--config", "deobf-config.yml"],
  "input_paths": ["target.jar", "deobf-config.yml"],
  "output_paths": ["deobf.jar"]
}
```

Convert DEX to JAR first if needed:

```json
{
  "tool": "jddlab_dex2jar",
  "args": ["target.apk", "-o", "target.jar"],
  "input_paths": ["target.apk"],
  "output_paths": ["target.jar"]
}
```

### 8.2 Native code analysis via Ghidra

`ghidra-decompile` takes positional arguments (`<input-binary> [<output.c>]`) and
writes a single `.c` file; there are no `-i`/`-o` flags:

```json
{
  "tool": "jddlab_ghidra_decompile",
  "args": ["lib/arm64-v8a/libnative.so", "libnative.decompiled.c"],
  "input_paths": ["lib/arm64-v8a/libnative.so"],
  "output_paths": ["libnative.decompiled.c"]
}
```

### 8.3 Extract JNI artifacts

`extract_jni <apk> [-o <file.json>]` reports JNI method signatures as JSON (a file with
`-o`, else stdout):

```json
{
  "tool": "jddlab_extract_jni",
  "args": ["target.apk", "-o", "jni_methods.json"],
  "input_paths": ["target.apk"],
  "output_paths": ["jni_methods.json"]
}
```

### 8.4 Smali-Level SSL pinning bypass

Search in jadx output or decompiled smali for:
- `checkServerTrusted` / `checkClientTrusted`
- `OkHttpClient.Builder().certificatePinner`
- `SSLContext`, `TrustManager`, `HostnameVerifier`

Find the `checkServerTrusted` smali method and make it return immediately (replace the
body with `return-void`).

For automated pinning removal use `jddlab_android_unpinner` (see §6.4).

### 8.5 Play Integrity / root detection bypass

Software-only bypass options (2025):

| Tool | How |
|---|---|
| TrickyStore (Magisk) | Spoofs device attestation key |
| Play Integrity Fix | Aims for valid attestation on rooted devices |

Play Integrity checks don't pass on emulators; use a physical device.


## 9. Troubleshooting

### 9.1 Decompilation failures

| Error | Cause | Fix |
|---|---|---|
| `AAPT2 exited with code 1` | Missing resource or framework | Install framework APK; use `--api 35` or `--ignore-missing-resources` |
| `Unsupported DEX format` | Old baksmali / smali | Update the image (`jddlab update`, `stanislavpovolotsky/jddlab:latest`) |
| `java.io.IOException: Was not able to decode XML` | Corrupted/encrypted APK | Try APKEditor merge first, or check if APK is protected |

### 9.2 Recompilation failures

| Error | Cause | Fix |
|---|---|---|
| `brut.androlib.AndrolibException` | AAPT2 compilation error | Check detailed error; usually a resource reference issue |
| `duplicate resource` | Two definitions of same resource ID | Search for duplicate in `res/values/*.xml` |
| `smali: syntax error` | Bad smali edit | Check register count (`.registers N`), type descriptors, opcode spelling |
| Recompiled APK size is wrong | Resource table mismatch | Decompile clean copy; test recompile without modifications first |

### 9.3 Installation failures

| Error | Cause | Fix |
|---|---|---|
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | Signature mismatch | `adb uninstall com.example.app` |
| `INSTALL_PARSE_FAILED_NO_CERTIFICATES` | Not signed | Run `jddlab_zipalign` then `jddlab_apksigner` |
| `INSTALL_FAILED_INVALID_APK` | Malformed APK | Check AAPT2 build log; verify ZIP integrity |
| `INSTALL_FAILED_SESSION_INVALID` | Different keys across splits | Re-sign ALL splits with same keystore |

### 9.4 Runtime crashes

| Symptom | Likely Cause | Fix |
|---|---|---|
| Immediate crash on launch | Register count wrong in smali | Check `.registers N` matches actual usage |
| `ClassNotFoundException` | Smali class name / package mismatch | Verify class descriptor matches directory path |
| `SecurityException: Signature not valid` | App explicitly checks own signature | Patch smali signature check (see §2.4) |
| Works on debug build but not release | ProGuard removed a method you're calling | Check if class/method is kept in `proguard-rules.pro` |


## 10. Quick reference cheat sheet

### Core workflow (MCP tool calls)

```
1. Analyze     → jddlab_jadx       args: ["-d", "out", "target.apk"]
2. Decompile   → jddlab_apktool    args: ["d", "target.apk", "-o", "dec", "-f"]
3. Edit smali / resources on host
4. Rebuild     → jddlab_apktool    args: ["b", "dec", "-o", "rebuilt.apk"]
5. Align       → jddlab_zipalign   args: ["-v", "-p", "4", "rebuilt.apk", "rebuilt_aligned.apk"]
6. Sign        → jddlab_apksigner  args: ["sign", "--ks", "key.keystore", ...]
7. Verify      → jddlab_apksigner  args: ["verify", "--verbose", "rebuilt_aligned.apk"]
8. Install     → jddlab_adb        args: ["install", "-r", "rebuilt_aligned.apk"]
```

### Smali quick patterns

```smali
# Return true
const/4 v0, 0x1
return v0

# Return false
const/4 v0, 0x0
return v0

# Return null
const/4 v0, 0x0
return-object v0

# NOP (remove a branch or call)
nop

# Set string
const-string v0, "value"
```

### Key file paths in decompiled APK

| Path | Content |
|---|---|
| `AndroidManifest.xml` | Permissions, components, min/target SDK |
| `apktool.yml` | Apktool metadata; don't edit the version fields by hand |
| `smali/com/example/app/` | Main app code (DEX 1) |
| `smali_classes2/` | Additional DEX files (multi-dex) |
| `res/values/strings.xml` | String resources |
| `res/values/styles.xml` | Theme/style definitions |
| `assets/` | Raw bundled files |
| `lib/arm64-v8a/` | 64-bit ARM native libraries |

### Common Smali type descriptors

| Java type | Smali |
|---|---|
| `boolean` | `Z` |
| `int` | `I` |
| `long` | `J` |
| `void` | `V` |
| `String` | `Ljava/lang/String;` |
| `Object` | `Ljava/lang/Object;` |
| `String[]` | `[Ljava/lang/String;` |

### Debug keystore

```
Path:     /root/.android/debug.keystore  (built into the image)
Alias:    androiddebugkey
Password: android
```

No `extra_mounts` needed:
```json
"args": ["sign", "--ks", "/root/.android/debug.keystore",
         "--ks-key-alias", "androiddebugkey",
         "--ks-pass", "pass:android", "--key-pass", "pass:android", ...]
```

To use your own host key, add `extra_mounts` and it will override the built-in one:
```json
"extra_mounts": [{"host": "~/.android", "container": "/root/.android", "mode": "ro"}]
```
