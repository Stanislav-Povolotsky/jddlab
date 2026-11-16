# jddlab example app

A small Android app for practicing the jddlab tools and
[AI skills](../skills/README.md) on something you built yourself. It contains:

- a native (JNI) library, `libnative-lib.so`, whose secret is stored XOR-encoded and
  decoded at runtime, for the
  [native-jni-analysis](../skills/native-jni-analysis/SKILL.md) skill;
- hardcoded Java "secrets" (a fake AWS key, an API token, an internal endpoint) for
  the [secret-scanning](../skills/secret-scanning/SKILL.md) skill (APKscan);
- a string that is decrypted at runtime (`StringVault`), so the plaintext endpoint
  never appears in the APK, for the
  [java-deobfuscation](../skills/java-deobfuscation/SKILL.md) skill (recover it in
  jadx or with a Frida hook);
- R8 shrinking and obfuscation in the release build: the app's own helper classes
  are renamed to `a`, `b`, `d`, ... and the bundled OkHttp library is obfuscated too,
  for the [java-deobfuscation](../skills/java-deobfuscation/SKILL.md) skill;
- certificate pinning on two live HTTPS requests, pinned to a key the servers don't
  have, so both fail until you bypass pinning. One uses the platform
  `network_security_config.xml` (`example.com`), the other uses OkHttp's
  `CertificatePinner` (`example.org`). The app prints `BLOCKED` or `OK HTTP 200` for
  each on screen and to logcat (`adb logcat -s jddlab-sample:I`), so you can see the
  bypass work without a proxy. For the
  [ssl-unpinning](../skills/ssl-unpinning/SKILL.md) skill;
- a dummy native "pin" check to practice patching with the
  [android-apk-patch](../skills/android-apk-patch/SKILL.md) skill.

> All planted secrets are fake, non-functional placeholders (the AWS key is the
> well-known example key from AWS docs). Never ship real secrets in an APK. The app
> needs the INTERNET permission for the pinning requests; the two hosts are the
> IANA `example.com`/`example.org` reserved domains.

## Layout

```
example/
├── README.md          # this file
├── simple.apk         # the built APK (you build it - see below)
└── simple-src/        # the Android Studio / Gradle project source
    ├── settings.gradle
    ├── build.gradle
    ├── gradle.properties
    └── app/
        ├── build.gradle
        ├── proguard-rules.pro
        └── src/main/
            ├── AndroidManifest.xml
            ├── cpp/                # native-lib.cpp + CMakeLists.txt (JNI)
            ├── res/xml/network_security_config.xml  # platform cert pin (example.com)
            └── java/com/example/simple/
                ├── MainActivity.java   # kept by R8; runs the pinning checks
                ├── NativeLib.java      # native method declarations (kept by R8)
                ├── SecretManager.java  # hardcoded secrets (obfuscated by R8)
                ├── StringVault.java    # runtime-decrypted string (obfuscated)
                └── PinningChecks.java  # the two pinned HTTPS requests (obfuscated)
```

## Building `simple.apk`

The project includes the Gradle wrapper (`gradlew`, pinned to Gradle 8.10.2), so
you don't need a system Gradle. You need the Android SDK, the NDK (for the native
code) and JDK 17 to 21.

### Option A: command line (wrapper)

From `example/simple-src/`, with the Android SDK/NDK installed and
`ANDROID_HOME`/`ANDROID_SDK_ROOT` set:

```bash
./gradlew :app:assembleRelease
cp app/build/outputs/apk/release/app-release.apk ../simple.apk
```

> AGP/Gradle here run on JDK 17 to 21. If your default `java` is newer (JDK 22+),
> point Gradle at a JDK 21, for example the JBR bundled with Android Studio:
> ```bash
> # Linux/macOS
> ./gradlew -Dorg.gradle.java.home="$HOME/android-studio/jbr" :app:assembleRelease
> ```
> ```cmd
> gradlew -Dorg.gradle.java.home="C:\Program Files\Android\Android Studio\jbr" :app:assembleRelease
> ```
> (or set `JAVA_HOME` to a JDK 21 for the session).

### Option B: Android Studio

1. `File → Open` and select `example/simple-src/`.
2. Let it sync and install the NDK/CMake if prompted (Studio uses its own JDK).
3. `Build → Select Build Variant → release`, then `Build → Build APK(s)`.
4. Copy the output `app/build/outputs/apk/release/app-release.apk` to
   `example/simple.apk`.

> The release build is signed with the Android debug keystore
> (`~/.android/debug.keystore`). Android Studio creates it automatically. To create it
> manually:
> ```bash
> keytool -genkeypair -v -keystore ~/.android/debug.keystore \
>   -storepass android -keypass android -alias androiddebugkey \
>   -keyalg RSA -keysize 2048 -validity 10000 \
>   -dname "CN=Android Debug,O=Android,C=US"
> ```

## Try the skills against it

Once `example/simple.apk` exists, from the `example/` directory:

```bash
jddlab jadx -d out simple.apk          # decompile - note the R8-renamed classes
jddlab apkscan -f json -o secrets.json simple.apk   # find the planted secrets
jddlab apktool d -o dec simple.apk     # decode; inspect dec/lib/*/libnative-lib.so
```

Recovering the runtime-decrypted string: in the jadx output, the renamed
`SecretManager` passes an encoded literal to the decode method of the renamed
`StringVault` (search for the `^ ((i + 42) & 255)` XOR loop). Compute it by hand,
run the dex through `jddlab simplify`, or hook the decode method with Frida. The
plaintext (`https://admin.internal.example.com/debug?key=dbg-7f3a9c`) is not in the
APK as a string.

Seeing the pinning bypass: install the APK, open the app, and watch the two pinning
lines in logcat. They read `BLOCKED` until you bypass pinning, then `OK HTTP 200`.
The app re-runs the checks every 5 seconds (or on a tap), so a Frida script attached
after launch takes effect on the next line.

```bash
jddlab adb install -r simple.apk
jddlab adb logcat -s jddlab-sample:I   # both lines BLOCKED
```

`android-unpinner all simple.apk` flips the platform-pinned `example.com` request to
`OK HTTP 200`. Its universal scripts don't catch the R8-renamed OkHttp pinner, so
`example.org` stays BLOCKED until you find the renamed `CertificatePinner` in jadx (by
the `"Certificate pinning failure!"` string) and hook its check with your own Frida
script. See [ssl-unpinning](../skills/ssl-unpinning/SKILL.md) §8.

The matching SKILL.md then walks through recovering the native secret with Ghidra,
deobfuscating the renamed classes and patching the pin check.
