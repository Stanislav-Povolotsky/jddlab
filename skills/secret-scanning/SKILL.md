# Android Secret & Endpoint Scanning - jddlab Edition
**Version**: 1.0 | **Last Updated**: 2026-08 | **Difficulty**: Intermediate

> How to find hardcoded secrets (API keys, tokens, credentials), endpoints, and other
> sensitive data inside Android apps using **jddlab**. Centered on **APKscan**, which
> decompiles + deobfuscates + scans in one pass, with manual follow-up techniques.
> Every tool runs inside the `stanislavpovolotsky/jddlab` Docker container via the
> **jddlab MCP server**.

---

## Table of Contents

1. [Toolchain Overview](#1-toolchain-overview)
2. [Quick Scan with APKscan](#2-quick-scan-with-apkscan)
3. [Tuning Rules & Output](#3-tuning-rules--output)
4. [Scanning Obfuscated Apps](#4-scanning-obfuscated-apps)
5. [Manual Follow-up (jadx grep, resources, native)](#5-manual-follow-up)
6. [Triage: Which Findings Matter](#6-triage-which-findings-matter)
7. [Troubleshooting](#7-troubleshooting)

---

## 1. Toolchain Overview

| Task | jddlab MCP tool | Native command |
|---|---|---|
| Decompile + deobfuscate + scan for secrets | `jddlab_apkscan` | `apkscan` |
| Decompile to Java for manual grep | `jddlab_jadx` | `jadx` |
| Decode resources / assets / manifest | `jddlab_apktool` | `apktool d` |
| Inspect/extract APK entries | `jddlab_apkeditor` | `APKEditor` |
| Deobfuscate before scanning | `jddlab_java_deobfuscator` / `jddlab_simplify` | see java-deobfuscation skill |

APKscan accepts `.apk`, `.xapk`, `.dex`, `.jar`, `.class`, `.smali`, `.zip`, `.aar`,
`.arsc`, `.aab`. It runs a decompiler itself (JADX by default), so you can point it
straight at an APK.

---

## 2. Quick Scan with APKscan

```json
{
  "tool": "jddlab_apkscan",
  "args": ["-f", "json", "-o", "secrets.json", "target.apk"],
  "input_paths": ["target.apk"],
  "output_paths": ["secrets.json"],
  "timeout_seconds": 1800
}
```

- `-f {text,json,yaml}` - output format (`json` is best for further processing).
- `-o <file>` - write results to a file.
- `-g {file,locator,both}` - group findings by input file, by rule, or both.

Large APKs take a while (decompilation dominates). Raise `timeout_seconds`.

---

## 3. Tuning Rules & Output

APKscan ships several built-in **locator sets**. Select them with `-r`/`--rules`:

`aws`, `azure`, `gcp`, `cloud`, `endpoints`, `generic`, `gitleaks`, `nuclei-regexes`,
`high-confidence`, `curated`, `default`, `all_secret_locators`.

Scan for cloud creds + endpoints only, high signal:

```json
{
  "tool": "jddlab_apkscan",
  "args": ["-r", "high-confidence", "cloud", "endpoints", "-f", "json", "-o", "secrets.json", "target.apk"],
  "input_paths": ["target.apk"],
  "output_paths": ["secrets.json"]
}
```

Provide your own rules (SecretLocator JSON, secret-patterns-db YAML, or Gitleaks TOML)
by passing their file paths to `-r`:

```json
{
  "tool": "jddlab_apkscan",
  "args": ["-r", "my-rules.yaml", "-o", "secrets.txt", "target.apk"],
  "input_paths": ["target.apk", "my-rules.yaml"],
  "output_paths": ["secrets.txt"]
}
```

Use `-c`/`--cleanup` to delete the (large) decompiled output after scanning, or
`-w <dir>` to keep it somewhere you can inspect (see §5).

---

## 4. Scanning Obfuscated Apps

Obfuscation hides secrets from a plain scan. APKscan can deobfuscate first
(`-d`/`--deobfuscate` is on by default) and can use alternate decompilers:

```json
{
  "tool": "jddlab_apkscan",
  "args": ["--deobfuscate", "--fernflower", "-w", "decompiled", "-f", "json", "-o", "secrets.json", "target.apk"],
  "input_paths": ["target.apk"],
  "output_paths": ["secrets.json", "decompiled"],
  "timeout_seconds": 3600
}
```

If strings are encrypted at runtime, a static scan will miss them. Decrypt first using
the **java-deobfuscation** skill (`d2j-decrypt-string` / `simplify`), then scan the
cleaned JAR/DEX with APKscan.

---

## 5. Manual Follow-up

APKscan is pattern-based; always confirm and hunt beyond it.

**Keep the decompiled sources** (`-w decompiled`) and grep for high-value markers on the
host:

```
grep -rEn "api[_-]?key|secret|token|password|bearer|BEGIN (RSA|EC|PRIVATE)" decompiled/
grep -rEn "https?://[a-zA-Z0-9._~:/?#@!$&'()*+,;=%-]+" decompiled/   # endpoints
```

**Do not forget non-code locations** - decode resources and check them too:

```json
{
  "tool": "jddlab_apktool",
  "args": ["d", "target.apk", "-o", "dec", "-f"],
  "input_paths": ["target.apk"],
  "output_paths": ["dec"]
}
```

Then inspect: `dec/res/values/strings.xml`, `dec/assets/`, `dec/res/raw/`,
`AndroidManifest.xml` (`<meta-data>` API keys, e.g. Google Maps), `.properties`/`.json`
config files, and any bundled `.env`. Secrets baked into native libraries need the
**native-jni-analysis** skill.

---

## 6. Triage: Which Findings Matter

| Finding | Risk | Notes |
|---|---|---|
| Cloud provider keys (AWS/Azure/GCP) | High | Often live; validate scope, not just presence |
| Backend endpoints / internal hosts | Medium-High | Expands attack surface; feed to further testing |
| Private keys / keystores in assets | High | Signing/enc keys; check what they protect |
| 3rd-party service tokens (maps, analytics, push) | Low-Medium | Frequently client-side by design; confirm impact |
| Base64/hex blobs flagged as "secret" | Varies | Many false positives; decode and verify |

Deduplicate across `smali`/`java`/resource copies of the same string, and verify a
finding is reachable (not dead test data) before reporting it.

---

## 7. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Scan finds nothing on an obfuscated app | Strings encrypted at runtime | Decrypt first (java-deobfuscation skill), then re-scan |
| Times out on a large/split APK | Decompilation is slow | Raise `timeout_seconds`; scan `base.apk` only, or a merged APK |
| Too many false positives | Broad rule set | Use `-r high-confidence` (and specific sets) instead of `default` |
| Want to inspect what was scanned | Output cleaned up | Pass `-w <dir>` and drop `--cleanup` |
| xapk/aab not scanned fully | Packaging | APKscan unpacks xapks by default; for `.aab`, merge/convert first with APKEditor |
