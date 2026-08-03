# jddlab example app

A tiny, deliberately "interesting" Android app you can use to practice the jddlab
tools and [AI skills](../skills/README.md) on something you built yourself.

The sample intentionally contains:

- **A native (JNI) library** (`libnative-lib.so`) whose secret is stored **XOR-encoded**
  and decoded at runtime - a target for the
  [native-jni-analysis](../skills/native-jni-analysis/SKILL.md) skill.
- **Hardcoded Java "secrets"** (a fake AWS key, an API token, an internal endpoint) -
  a target for the [secret-scanning](../skills/secret-scanning/SKILL.md) skill (APKscan).
- **R8 code shrinking + obfuscation** on the release build, so most classes are renamed -
  a target for the [java-deobfuscation](../skills/java-deobfuscation/SKILL.md) skill.
- A dummy native "pin" check you can practice patching with the
  [android-apk-patch](../skills/android-apk-patch/SKILL.md) and
  [ssl-unpinning](../skills/ssl-unpinning/SKILL.md) skills.

> All planted secrets are fake, non-functional placeholders (the AWS key is the
> well-known example key from AWS docs). Never ship real secrets in an APK.

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
            └── java/com/example/simple/
                ├── MainActivity.java
                ├── NativeLib.java   # native method declarations (kept by R8)
                └── SecretManager.java  # hardcoded secrets (obfuscated by R8)
```

## Building `simple.apk`

The project ships with a committed Gradle **wrapper** (`gradlew`, pinned to Gradle
8.10.2), so you do not need a system Gradle. You do need the **Android SDK** and
**NDK** (for the native code) and a **JDK 17–21**.

### Option A - command line (wrapper)

From `example/simple-src/`, with the Android SDK/NDK installed and
`ANDROID_HOME`/`ANDROID_SDK_ROOT` set:

```bash
./gradlew :app:assembleRelease
cp app/build/outputs/apk/release/app-release.apk ../simple.apk
```

> **JDK version:** AGP/Gradle here run on JDK 17–21. If your default `java` is newer
> (e.g. JDK 22+), point Gradle at a JDK 21 - for example Android Studio's bundled JBR:
> ```bash
> # Linux/macOS
> ./gradlew -Dorg.gradle.java.home="$HOME/android-studio/jbr" :app:assembleRelease
> ```
> ```cmd
> gradlew -Dorg.gradle.java.home="C:\Program Files\Android\Android Studio\jbr" :app:assembleRelease
> ```
> (or set `JAVA_HOME` to a JDK 21 for the session).

### Option B - Android Studio

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

Then follow the matching SKILL.md to go deeper (recover the native secret with Ghidra,
deobfuscate, patch the pin check, etc.).
