# Android SSL/Certificate Pinning Bypass - jddlab Edition
**Version**: 1.0 | **Last Updated**: 2026-08 | **Difficulty**: Advanced

> How to remove or bypass TLS certificate pinning in Android apps so you can
> intercept HTTPS traffic (Burp/mitmproxy/Charles) using **jddlab**. Covers both
> **static** (patch the APK) and **dynamic** (Frida/objection) approaches. Every
> tool runs inside the `stanislavpovolotsky/jddlab` Docker container via the
> **jddlab MCP server**.
>
> **Authorized testing only.** Use on apps you own or are explicitly permitted to test.

---

## Table of Contents

1. [Choose an Approach](#1-choose-an-approach)
2. [Toolchain Overview](#2-toolchain-overview)
3. [Approach A: Automated Static Unpinning (android-unpinner)](#3-approach-a-automated-static-unpinning-android-unpinner)
4. [Approach B: Frida Gadget Injection (apk-patcher)](#4-approach-b-frida-gadget-injection-apk-patcher)
5. [Approach C: objection patchapk](#5-approach-c-objection-patchapk)
6. [Approach D: Manual smali Patch](#6-approach-d-manual-smali-patch)
7. [Re-sign and Install](#7-re-sign-and-install)
8. [Verify the Bypass](#8-verify-the-bypass)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Choose an Approach

| Approach | Root needed? | Best when |
|---|---|---|
| A. `android-unpinner` | No (patches APK) | Quick, no device root, standard pinning |
| B. `apk-patcher` (Frida gadget) | No | You want a full Frida script (custom hooks) baked in |
| C. `objection patchapk` | No | You want objection's built-in pinning-bypass hooks |
| D. Manual smali patch | No | Custom/native pinning the automated tools miss |

Rooted device? You can skip patching entirely and run `frida`/`objection` against the
running app from the host - but that is outside the container (needs USB/host Frida).

---

## 2. Toolchain Overview

| Task | jddlab MCP tool | Native command |
|---|---|---|
| Automated pinning removal | `jddlab_android_unpinner` | `android-unpinner` |
| Inject Frida gadget | `jddlab_apk_patcher` | `apk-patcher` |
| objection patch/patchapk | `jddlab_objection` | `objection` |
| Decompile to smali | `jddlab_apktool` | `apktool d` |
| Rebuild from smali | `jddlab_apktool` | `apktool b` |
| Analyze (find pinning) | `jddlab_jadx` | `jadx` |
| Align / sign | `jddlab_zipalign` / `jddlab_apksigner` | `zipalign` / `apksigner` |

---

## 3. Approach A: Automated Static Unpinning (android-unpinner)

`android-unpinner` rewrites the APK to disable common pinning implementations and
injects a Frida gadget where needed - no device root required.

```json
{
  "tool": "jddlab_android_unpinner",
  "args": ["all", "target.apk"],
  "input_paths": ["target.apk"],
  "output_paths": ["target.apk"]
}
```

Check `jddlab android-unpinner --help` (or `tools/android-unpinner.md`) for
sub-commands (`patch-apk`, `push-frida`, `run`) and output flags. It typically emits a
patched, signed APK ready to install. If it produces a debug-signed APK you can install
it directly; otherwise re-sign per §7.

---

## 4. Approach B: Frida Gadget Injection (apk-patcher)

Bake a Frida gadget + your own bypass script into the APK. This is the most flexible
route (you control the JS).

```json
{
  "tool": "jddlab_apk_patcher",
  "args": ["./target."],
  "input_paths": ["target.apk"],
  "output_paths": ["target.patched"]
}
```

> `apk-patcher` expects the APK base name **without extension, with the trailing dot**
> (`test.apk` → `./test.`). For split APKs, provide `base.`, `base.config.<lang>.apk`,
> `base.config.<arch>.apk`, `base.config.<dpi>.apk` alongside. See the README
> `apk-patcher` section.

Load a custom pinning-bypass script with `-l`:

```json
{
  "tool": "jddlab_apk_patcher",
  "args": ["-l", "unpin.js", "./target."],
  "input_paths": ["target.apk", "unpin.js"],
  "output_paths": ["target.patched"]
}
```

A minimal `unpin.js` can pull in the community "Universal Android SSL Pinning Bypass"
Frida script. The resulting APK runs the gadget on launch; attach with
`frida -U Gadget` from the host if you want an interactive session.

---

## 5. Approach C: objection patchapk

objection injects a Frida gadget and its own hook set (including pinning bypass):

```json
{
  "tool": "jddlab_objection",
  "args": ["patchapk", "-s", "target.apk"],
  "input_paths": ["target.apk"],
  "output_paths": ["target.objection.apk"]
}
```

Then, against a device (host-side, needs USB/adb + Frida): `objection -g <pkg> explore`
and run `android sslpinning disable`. Note `objection explore` needs an interactive
TTY and a running device, so run it on the host, not headless in the container.

---

## 6. Approach D: Manual smali Patch

When automated tools miss a custom/native implementation, patch by hand.

**Step 1 - decompile:**

```json
{
  "tool": "jddlab_apktool",
  "args": ["d", "target.apk", "-o", "dec", "-f"],
  "input_paths": ["target.apk"],
  "output_paths": ["dec"]
}
```

**Step 2 - locate pinning.** In `jddlab_jadx` output or the smali, search for:

- `checkServerTrusted` / `checkClientTrusted` (custom `X509TrustManager`)
- `CertificatePinner` / `certificatePinner` (OkHttp)
- `TrustManager`, `SSLContext`, `HostnameVerifier`
- `okhttp3` pinning config, or a `network_security_config.xml` with `<pin-set>`

**Step 3 - neuter it.** Make the trust check return without throwing. For a
`checkServerTrusted` smali method, strip the body to a simple return:

```smali
.method public checkServerTrusted([Ljava/security/cert/X509Certificate;Ljava/lang/String;)V
    .locals 0
    return-void
.end method
```

For OkHttp `CertificatePinner`, remove the `.add(...)` pins or make the `check` method
return-void. Also check `res/xml/network_security_config.xml` and remove any
`<pin-set>` / set `<trust-anchors>` to include `user` CAs.

**Step 4 - rebuild:**

```json
{
  "tool": "jddlab_apktool",
  "args": ["b", "dec", "-o", "rebuilt.apk"],
  "input_paths": ["dec"],
  "output_paths": ["rebuilt.apk"]
}
```

---

## 7. Re-sign and Install

Any modified/patched APK must be aligned, signed, and verified before install:

```json
{"tool":"jddlab_zipalign","args":["-v","-p","4","rebuilt.apk","aligned.apk"],"input_paths":["rebuilt.apk"],"output_paths":["aligned.apk"]}
```
```json
{"tool":"jddlab_apksigner","args":["sign","--ks","~/.android/debug.keystore","--ks-key-alias","androiddebugkey","--ks-pass","pass:android","--key-pass","pass:android","aligned.apk"],"input_paths":["aligned.apk"],"output_paths":["aligned.apk"],"extra_mounts":[{"host":"~/.android","container":"/root/.android","mode":"ro"}]}
```
```json
{"tool":"jddlab_apksigner","args":["verify","--print-certs","aligned.apk"],"input_paths":["aligned.apk"]}
```

Install on the host: `adb install -r aligned.apk`. See the **android-apk-patch** skill
for split-APK signing and install-multiple.

---

## 8. Verify the Bypass

1. Configure the device/emulator to route through your proxy (Burp/mitmproxy) and
   install the proxy CA (as a user cert - the patch should now accept it).
2. Launch the app and exercise a network call.
3. You should see decrypted HTTPS in the proxy. If the app shows connection errors but
   no proxy traffic, pinning is still active - move to a different approach or patch the
   remaining implementation.

---

## 9. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Still no proxy traffic after patch | Native pinning (in `.so`) or a missed impl | Hook via Frida (§4), or inspect native libs (see native-jni-analysis skill) |
| App crashes on launch after patch | Integrity/tamper check detected the mod | Patch the signature/integrity check (android-apk-patch skill §2.4) |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | Different signing key than installed app | `adb uninstall <pkg>` then reinstall |
| Frida gadget APK does nothing | Gadget not loaded / wrong arch | Match the device ABI; check `apk-patcher -a <arch>` and gadget logs |
| Proxy shows TLS errors, not requests | Proxy CA not trusted | Ensure the CA is installed and the patch trusts user CAs / `network_security_config` |
