---
name: ssl-unpinning
description: Bypass Android TLS/certificate pinning with jddlab to intercept HTTPS - android-unpinner, Frida gadget injection (apk-patcher), objection, or manual smali patches. Use when a proxy (Burp/mitmproxy) shows no traffic because of certificate pinning.
---

# Android SSL/certificate pinning bypass with jddlab

Version 1.0, 2026-08.

How to remove or bypass TLS certificate pinning in Android apps so that you can
intercept HTTPS traffic (Burp, mitmproxy, Charles) with jddlab, either by patching the
APK or at runtime with Frida/objection. Every tool runs inside the
`stanislavpovolotsky/jddlab` Docker container through the jddlab MCP server.

Use this only on apps you own or are explicitly permitted to test.


## Table of contents

1. [Choose an approach](#1-choose-an-approach)
2. [Toolchain overview](#2-toolchain-overview)
3. [Approach A: automated unpinning (android-unpinner)](#3-approach-a-automated-unpinning-android-unpinner)
4. [Approach B: Frida gadget injection (apk-patcher)](#4-approach-b-frida-gadget-injection-apk-patcher)
5. [Approach C: objection patchapk](#5-approach-c-objection-patchapk)
6. [Approach D: manual smali patch](#6-approach-d-manual-smali-patch)
7. [Re-sign and install](#7-re-sign-and-install)
8. [Verify the bypass](#8-verify-the-bypass)
9. [Troubleshooting](#9-troubleshooting)


## 1. Choose an approach

| Approach | Root needed? | Best when |
|---|---|---|
| A. `android-unpinner` | No (debuggable APK + runtime injection) | Quick, standard pinning, device connected |
| B. `apk-patcher` (Frida gadget) | No | You want a full Frida script (custom hooks) baked in |
| C. `objection patchapk` | No | You want objection's built-in pinning-bypass hooks |
| D. Manual smali patch | No | Custom/native pinning the automated tools miss |

On a rooted device with frida-server you can skip patching and attach `frida` /
`objection` to the running app. jddlab reaches the device through the host ADB
server (see §4).


## 2. Toolchain overview

| Task | jddlab MCP tool | Native command |
|---|---|---|
| Automated pinning removal | `jddlab_android_unpinner` | `android-unpinner` |
| Inject Frida gadget | `jddlab_apk_patcher` | `apk-patcher` |
| objection patch/patchapk | `jddlab_objection` | `objection` |
| Decompile to smali | `jddlab_apktool` | `apktool d` |
| Rebuild from smali | `jddlab_apktool` | `apktool b` |
| Analyze (find pinning) | `jddlab_jadx` | `jadx` |
| Align / sign | `jddlab_zipalign` / `jddlab_apksigner` | `zipalign` / `apksigner` |


## 3. Approach A: automated unpinning (android-unpinner)

`android-unpinner` needs no root. `patch-apks` makes the APK debuggable and re-signs
it (writes `target.unpinned.apk`, no device needed); the pinning bypass itself happens
at runtime, when `start-app` (or `all`) starts the app on a connected device and
injects the Frida gadget with its unpinning scripts:

```json
{
  "tool": "jddlab_android_unpinner",
  "args": ["patch-apks", "target.apk"],
  "input_paths": ["target.apk"],
  "output_paths": ["target.unpinned.apk"]
}
```

> `all` patches, installs and starts the app with the hooks in one go; it needs a
> device. Other subcommands: `install`, `push-resources`, `start-app`, `get-apks`,
> `list-packages`, `package-name` (see `jddlab android-unpinner --help` or
> `tools/android-unpinner.md`). The patched APK is debug-signed and installable; if you
> modify it further, re-sign it as in §7.


## 4. Approach B: Frida gadget injection (apk-patcher)

Put a Frida gadget and your own bypass script into the APK. This is the most flexible
route, because you write the JS. `apk-patcher` injects the gadget baked into the image
(no download).

```json
{
  "tool": "jddlab_apk_patcher",
  "args": ["./target."],
  "input_paths": ["target.apk"],
  "output_paths": ["target.patched"]
}
```

> `apk-patcher` expects the APK base name without the extension but with the trailing
> dot (`test.apk` → `./test.`). For split APKs, provide `base.`, `base.config.<lang>.apk`,
> `base.config.<arch>.apk`, `base.config.<dpi>.apk` alongside. See the README
> `apk-patcher` section.

Load a custom pinning-bypass script with `-l`. The gadget then runs it on every
launch, with no client and no INTERNET permission needed:

```json
{
  "tool": "jddlab_apk_patcher",
  "args": ["-f", "--frida-version", "16.1.3", "-l", "unpin.js", "./target."],
  "input_paths": ["target.apk", "unpin.js"],
  "output_paths": ["target.patched"]
}
```

`unpin.js` can be the community "Universal Android SSL Pinning Bypass" Frida script.
Scripts loaded by the gadget itself (`apk-patcher -l`) are plain scripts. Frida 17
gadgets don't give such scripts the `Java` object (`Java.perform` fails silently). For
Java hooks use the frida 16 gadget baked into the image: `-f --frida-version 16.1.3`
(16.x gadgets read their config and script only from extracted native libraries,
which `-f` enables), and start the hooks from `setTimeout(..., 1000)` rather than at
the top level of the script. Alternatively compile the script with
`frida-java-bridge`. Scripts loaded by the `frida` CLI (`frida -l`) have `Java` with
either version. (Tested on Android 11.)

Without `-l` the gadget listens and waits for a client when the app starts (the app
needs the INTERNET permission for that; `objection patchapk` adds it, `apk-patcher`
doesn't). Attach with `frida -U -n Gadget` (interactive, from a `jddlab` shell) or
non-interactively through MCP. The bypass stays active only while the script is
loaded, so keep `-t` as long as you capture traffic:

```json
{
  "tool": "jddlab_frida",
  "args": ["-U", "-n", "Gadget", "-l", "unpin.js", "-q", "-t", "30"],
  "input_paths": ["unpin.js"],
  "timeout_seconds": 120
}
```

Device access (`adb install`, `frida -U`) goes through the host ADB server when one
is running: ask the user to run `adb start-server` and connect the device on the host
(USB, or `adb pair`/`adb connect`). Then `jddlab_adb`, `jddlab_frida*` and
`jddlab_objection` see the device in every call. Without it, each MCP call gets a
fresh ADB server inside the container that knows no devices.


## 5. Approach C: objection patchapk

objection injects the Frida gadget baked into the image; its hooks include a pinning
bypass:

```json
{
  "tool": "jddlab_objection",
  "args": ["patchapk", "-s", "target.apk"],
  "input_paths": ["target.apk"],
  "output_paths": ["target.objection.apk"]
}
```

Install the APK, start the app, and run `android sslpinning disable` in an
interactive session: `objection -n Gadget explore` from a `jddlab` shell, or
`objection -n Gadget explore -s "android sslpinning disable"`. The bypass lasts as
long as the session. `objection ... run "android sslpinning disable"` (the
non-interactive form) unloads its agent right after the command, so it doesn't keep
the bypass; through MCP use `jddlab_frida` with a bypass script and `-t` (§4).


## 6. Approach D: manual smali patch

When the automated tools miss a custom implementation, patch it by hand.

Step 1, decompile:

```json
{
  "tool": "jddlab_apktool",
  "args": ["d", "target.apk", "-o", "dec", "-f"],
  "input_paths": ["target.apk"],
  "output_paths": ["dec"]
}
```

Step 2, find the pinning. In the `jddlab_jadx` output or the smali, search for:

- `checkServerTrusted` / `checkClientTrusted` (custom `X509TrustManager`)
- `CertificatePinner` / `certificatePinner` (OkHttp)
- `TrustManager`, `SSLContext`, `HostnameVerifier`
- `okhttp3` pinning config, or a `network_security_config.xml` with `<pin-set>`

Step 3, disable it. Make the trust check return without throwing. For a
`checkServerTrusted` smali method, reduce the body to a plain return:

```smali
.method public checkServerTrusted([Ljava/security/cert/X509Certificate;Ljava/lang/String;)V
    .locals 0
    return-void
.end method
```

For OkHttp `CertificatePinner`, remove the `.add(...)` pins or make the `check` method
return-void. Also check `res/xml/network_security_config.xml` and remove any
`<pin-set>` / set `<trust-anchors>` to include `user` CAs.

Step 4, rebuild:

```json
{
  "tool": "jddlab_apktool",
  "args": ["b", "dec", "-o", "rebuilt.apk"],
  "input_paths": ["dec"],
  "output_paths": ["rebuilt.apk"]
}
```


## 7. Re-sign and install

A modified APK must be aligned, signed and verified before installing it:

```json
{"tool":"jddlab_zipalign","args":["-v","-p","4","rebuilt.apk","aligned.apk"],"input_paths":["rebuilt.apk"],"output_paths":["aligned.apk"]}
```
```json
{"tool":"jddlab_apksigner","args":["sign","--ks","/root/.android/debug.keystore","--ks-key-alias","androiddebugkey","--ks-pass","pass:android","--key-pass","pass:android","aligned.apk"],"input_paths":["aligned.apk"],"output_paths":["aligned.apk"]}
```
```json
{"tool":"jddlab_apksigner","args":["verify","--print-certs","aligned.apk"],"input_paths":["aligned.apk"]}
```

Install it with `jddlab_adb` (`["install", "-r", "aligned.apk"]`) or `adb` on the host.
The android-apk-patch skill covers split-APK signing and `install-multiple`.


## 8. Verify the bypass

1. Configure the device/emulator to route through your proxy (Burp/mitmproxy) and
   install the proxy CA as a user certificate (the patched app should accept it).
2. Launch the app and exercise a network call.
3. The proxy should show decrypted HTTPS. If the app reports connection errors and
   the proxy shows no traffic, pinning is still active: try another approach or patch
   the remaining implementation.

The [example app](../../example/README.md) is a self-contained target that needs no
proxy to verify a bypass. It makes two pinned HTTPS requests, one via the platform
`network_security_config.xml` and one via OkHttp's `CertificatePinner`, both pinned
to a key the servers don't have, and prints the result of each to logcat
(`adb logcat -s jddlab-sample:I`):

```
pinning[network_security_config] https://example.com/ -> BLOCKED (...)
pinning[okhttp CertificatePinner] https://example.org/ -> BLOCKED (...)
```

A line turns into `OK HTTP 200` once that request's pinning is bypassed. The checks
repeat every 5 seconds, so a Frida script you attach after launch takes effect on the
next line. `android-unpinner all` bypasses the platform-pinned request; its universal
scripts miss the OkHttp pinner because R8 renamed `okhttp3.CertificatePinner`, so find
the renamed class in jadx (search for the `"Certificate pinning failure!"` string) and
hook its `check` method with your own Frida script (§4).


## 9. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Still no proxy traffic after patch | Native pinning (in `.so`) or a missed impl | Hook via Frida (§4), or inspect native libs (see native-jni-analysis skill) |
| App crashes on launch after patch | Integrity/tamper check detected the mod | Patch the signature/integrity check (android-apk-patch skill §2.4) |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | Different signing key than installed app | `adb uninstall <pkg>` then reinstall |
| Frida gadget APK does nothing | Gadget not loaded / wrong arch | Match the device ABI; check `apk-patcher -a <arch>` and gadget logs |
| Proxy shows TLS errors, not requests | Proxy CA not trusted | Ensure the CA is installed and the patch trusts user CAs / `network_security_config` |
