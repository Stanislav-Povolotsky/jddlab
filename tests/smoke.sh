#!/bin/bash
# jddlab smoke tests - minimal functional checks of every bundled tool.
#
# Runs INSIDE the image (installed at /usr/local/jddlab/tests):
#   docker run --rm <image> bash /usr/local/jddlab/tests/smoke.sh [options] [test...]
#
# Each test runs the tool on a tiny real input (fixtures/) and checks the result
# (decompiled class names, recovered strings, a re-signed APK, ...) - a bit more
# than "--help works", but cheap enough to run on every image build (a few
# minutes on amd64).
#
# Options:
#   --native-only   Run only tests of tools with architecture-specific native code
#                   (meant for the arm64 image, which CI runs under QEMU emulation:
#                   pure Java/Python tools behave the same on every architecture).
#   --emulated      The image runs under QEMU emulation: skip checks that can't work
#                   there (ptrace-based Frida injection).
#   --list          List the tests and exit.
#   --keep          Keep the work directory.
#   test...         Run only the given tests.

set -u

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURES="$TESTS_DIR/fixtures"
APK="$FIXTURES/simple.apk"
WORK="$(mktemp -d /tmp/jddlab-smoke.XXXXXX)"

native_only=0
emulated=0
keep=0
list_only=0
selected=()
for arg in "$@"; do
    case "$arg" in
        --native-only) native_only=1 ;;
        --emulated) emulated=1 ;;
        --keep) keep=1 ;;
        --list) list_only=1 ;;
        -*) echo "Unknown option: $arg" >&2; exit 2 ;;
        *) selected+=("$arg") ;;
    esac
done

# --- helpers ---------------------------------------------------------------

# fail <message>: abort the current test (tests run in a subshell)
fail() { echo "    ASSERT: $*"; exit 1; }
# Per-command timeout, so a pathological input fails the build loudly instead of
# hanging it (every real step finishes in well under a minute).
RUN_TIMEOUT="${JDDLAB_SMOKE_TIMEOUT:-300}"
# run <cmd...>: run a command, logging it and its output; fail on non-zero exit
run() {
    echo "    \$ $*"
    timeout "$RUN_TIMEOUT" "$@" >"$T/out.log" 2>&1
    local rc=$?
    sed 's/^/      /' "$T/out.log" | tail -n 15
    [ $rc -ne 124 ] || fail "'$1' timed out after ${RUN_TIMEOUT}s"
    [ $rc -eq 0 ] || fail "'$1' exited with code $rc"
}
# run_any <cmd...>: like run, but ignore the exit code (tools that exit 1/2 on --help)
run_any() {
    echo "    \$ $*"
    timeout "$RUN_TIMEOUT" "$@" >"$T/out.log" 2>&1
    sed 's/^/      /' "$T/out.log" | tail -n 15
    return 0
}
# expect_file <path>: the file exists and is not empty
expect_file() { [ -s "$1" ] || fail "missing or empty file: $1"; }
# expect_grep <pattern> <file|dir>...: a fixed string occurs in the given files (recursively)
expect_grep() {
    local pattern=$1; shift
    grep -rqF -- "$pattern" "$@" 2>/dev/null || fail "'$pattern' not found in $*"
}
# expect_out <pattern>: a fixed string occurs in the output of the last run/run_any
expect_out() { grep -qF -- "$1" "$T/out.log" || fail "'$1' not found in the output"; }
# expect_zip_entry <zip> <regex>: an entry matching the regex exists in the zip/jar/apk
expect_zip_entry() {
    python3 -c 'import re,sys,zipfile; sys.exit(0 if any(re.search(sys.argv[2], n) for n in zipfile.ZipFile(sys.argv[1]).namelist()) else 1)' "$1" "$2" \
        || fail "no entry matching '$2' in $1"
}

# Shared artifacts produced by one test and used by others are created on demand.
dex_jar() {
    if [ ! -s "$WORK/shared/simple.jar" ]; then
        mkdir -p "$WORK/shared"
        d2j-dex2jar -f -o "$WORK/shared/simple.jar" "$APK" >"$WORK/shared/dex2jar.log" 2>&1
    fi
    echo "$WORK/shared/simple.jar"
}
app_jar() {
    # A jar with only the sample app's own classes (com/example/simple/*). The APK
    # also bundles OkHttp and Kotlin classes (~220 in all) to give jadx, apkscan and
    # the deobfuscation skill realistic input, but feeding every pure-Java decompiler
    # the whole library set is slow and makes fernflower loop forever on some Kotlin
    # bytecode. The decompiler smoke tests only need the app's own MainActivity.
    if [ ! -s "$WORK/shared/app.jar" ]; then
        local jar; jar=$(dex_jar)
        local d="$WORK/shared/app-classes"
        mkdir -p "$d"
        {
            (cd "$d" && unzip -oq "$jar" 'com/example/simple/*') &&
            (cd "$d" && jar cf "$WORK/shared/app.jar" com)
        } >"$WORK/shared/app_jar.log" 2>&1
    fi
    echo "$WORK/shared/app.jar"
}
app_dex() {
    # A dex with only the app's own classes, from app.jar. simplify builds a VM over
    # every class in its input, so the full 221-class dex makes it slow (minutes); it
    # only optimizes the app's MainActivity here anyway.
    if [ ! -s "$WORK/shared/app.dex" ]; then
        local jar; jar=$(app_jar)
        d2j-jar2dex -f -o "$WORK/shared/app.dex" "$jar" >"$WORK/shared/app_dex.log" 2>&1
    fi
    echo "$WORK/shared/app.dex"
}
res_apk() {
    # The sample APK has an empty resource table without a package name, which
    # aapt2 refuses to link ("all packages being linked must have a name"); real
    # apps always have one. Derive an APK with a proper resource table for tools
    # that rebuild resources (apktool b, objection patchapk).
    if [ ! -s "$WORK/shared/simple-res.apk" ]; then
        mkdir -p "$WORK/shared"
        local d="$WORK/shared/simple-res"
        {
            apktool d -q -f -o "$d" "$APK" &&
            sed -i -e 's/^  packageName: *$/  packageName: com.example.simple/' -e 's/^  packageId: 0$/  packageId: 127/' "$d/apktool.yml" &&
            mkdir -p "$d/res/values" &&
            echo '<resources><string name="jddlab_fixture">jddlab</string></resources>' >"$d/res/values/strings.xml" &&
            apktool b -q -o "$WORK/shared/simple-res.unsigned.apk" "$d" &&
            apksigner sign --ks /root/.android/debug.keystore --ks-pass pass:android \
                --out "$WORK/shared/simple-res.apk" "$WORK/shared/simple-res.unsigned.apk"
        } >"$WORK/shared/res_apk.log" 2>&1
    fi
    echo "$WORK/shared/simple-res.apk"
}
native_lib() {
    # The x86_64 build of the sample's JNI library
    if [ ! -s "$WORK/shared/libnative-lib.so" ]; then
        mkdir -p "$WORK/shared"
        unzip -o -q -j "$APK" lib/x86_64/libnative-lib.so -d "$WORK/shared"
    fi
    echo "$WORK/shared/libnative-lib.so"
}

# --- tests ------------------------------------------------------------------
# Every test is a function test_<name>. It runs in its own subshell with $T set
# to a fresh directory, and passes if it returns 0.
# NATIVE_TESTS lists tests of tools with architecture-specific native code.

NATIVE_TESTS="adb adb_forward zipalign apksigner krakatau2 frida apkid pyxamstore ilspycmd ghidra blutter_toolchain mobsfscan hermes_dec"

test_jadx() {
    run jadx -q -d "$T/out" "$APK"
    expect_grep "class MainActivity" "$T/out/sources/com/example/simple/MainActivity.java"
    expect_grep "getSecretFromNative" "$T/out/sources/com/example/simple/NativeLib.java"
}

test_apktool() {
    run apktool d -f -o "$T/decoded" "$APK"
    expect_grep "com/example/simple/MainActivity" "$T/decoded/smali/com/example/simple/MainActivity.smali"
    expect_grep 'package="com.example.simple"' "$T/decoded/AndroidManifest.xml"
    # Full decode + rebuild (aapt2) roundtrip on an APK with a proper resource table
    local apk; apk=$(res_apk)
    expect_file "$apk"
    run apktool d -f -o "$T/decoded-res" "$apk"
    expect_grep "jddlab_fixture" "$T/decoded-res/res/values/strings.xml"
    run apktool b -o "$T/rebuilt.apk" "$T/decoded-res"
    expect_zip_entry "$T/rebuilt.apk" '^resources\.arsc$'
}

test_apkeditor() {
    run apkeditor d -i "$APK" -o "$T/decoded"
    expect_grep "com.example.simple" "$T/decoded/AndroidManifest.xml"
    run apkeditor b -i "$T/decoded" -o "$T/rebuilt.apk"
    expect_zip_entry "$T/rebuilt.apk" '^classes\.dex$'
}

test_zipalign() {
    run zipalign -f -p 4 "$APK" "$T/aligned.apk"
    run zipalign -c -p 4 "$T/aligned.apk"
}

test_apksigner() {
    cp "$APK" "$T/app.apk"
    run apksigner sign --ks /root/.android/debug.keystore --ks-pass pass:android --ks-key-alias androiddebugkey \
        --out "$T/signed.apk" "$T/app.apk"
    run apksigner verify --print-certs "$T/signed.apk"
    expect_out "Android Debug"
}

test_keytool() {
    run keytool -genkeypair -keystore "$T/test.jks" -storepass jddlab-test -alias test \
        -keyalg RSA -keysize 2048 -validity 1 -dname "CN=jddlab smoke test"
    run keytool -list -keystore "$T/test.jks" -storepass jddlab-test
    expect_out "test, "
}

test_smali_baksmali() {
    unzip -q -o "$APK" classes.dex -d "$T"
    run baksmali d -o "$T/smali" "$T/classes.dex"
    expect_file "$T/smali/com/example/simple/MainActivity.smali"
    run smali a -o "$T/rebuilt.dex" "$T/smali"
    expect_file "$T/rebuilt.dex"
}

test_dex2jar() {
    run d2j-dex2jar -f -o "$T/simple.jar" "$APK"
    expect_zip_entry "$T/simple.jar" '^com/example/simple/MainActivity\.class$'
}

test_enjarify() {
    run enjarify -f -o "$T/simple.jar" "$APK"
    expect_zip_entry "$T/simple.jar" '^com/example/simple/MainActivity\.class$'
}

test_cfr() {
    local jar; jar=$(app_jar)
    run cfr "$jar" --outputdir "$T/out"
    expect_grep "class MainActivity" "$T/out/com/example/simple/MainActivity.java"
}

test_procyon() {
    local jar; jar=$(app_jar)
    run procyon -jar "$jar" -o "$T/out"
    expect_grep "class MainActivity" "$T/out/com/example/simple/MainActivity.java"
}

test_fernflower() {
    local jar; jar=$(app_jar)
    mkdir -p "$T/out"
    run fernflower "$jar" "$T/out"
    expect_zip_entry "$T/out/app.jar" '^com/example/simple/MainActivity\.java$'
}

test_vineflower() {
    local jar; jar=$(app_jar)
    run vineflower "$jar" "$T/out"
    expect_grep "class MainActivity" "$T/out"
}

test_krakatau1() {
    local jar; jar=$(app_jar)
    run krakatau-disassemble -out "$T/dis" -r "$jar"
    expect_grep ".class public super com/example/simple/MainActivity" "$T/dis"
    run krakatau-assemble -out "$T/rebuilt.jar" -r "$T/dis"
    expect_zip_entry "$T/rebuilt.jar" 'MainActivity\.class$'
}

test_krakatau2() {
    local jar; jar=$(app_jar)
    run krak2 dis --out "$T/dis.zip" "$jar"
    expect_zip_entry "$T/dis.zip" 'com/example/simple/MainActivity\.j$'
    run krak2 asm --out "$T/rebuilt.jar" "$T/dis.zip"
    expect_zip_entry "$T/rebuilt.jar" 'MainActivity\.class$'
}

test_java_deobfuscator() {
    local jar; jar=$(dex_jar)
    cp "$jar" "$T/simple.jar"
    run java-deobfuscator-detect "$T/simple.jar"
}

test_simplify() {
    # -ie: the sample references Android framework (and OkHttp) classes simplify's VM
    # can't load. Run on a dex of just the app's classes (app_dex), not the full APK:
    # simplify builds a VM over every class, so the bundled library makes it minutes.
    local dex; dex=$(app_dex)
    run simplify -ie -it 'com/example/simple/MainActivity' -o "$T/simplified.dex" "$dex"
    expect_file "$T/simplified.dex"
}

test_androguard() {
    run androguard axml "$APK"
    expect_out 'package="com.example.simple"'
    run androguard sign "$APK"
    expect_out "Is signed v2: True"
}

test_apkid() {
    run apkid "$APK"
    expect_out "compiler"
}

test_apkscan() {
    cp "$APK" "$T/simple.apk"
    run apkscan --jadx -o "$T/report.txt" "$T/simple.apk"
    expect_grep "AKIAIOSFODNN7EXAMPLE" "$T/report.txt"
}

test_extract_jni() {
    run extract_jni "$APK" -o "$T/jni.json"
    expect_grep "getSecretFromNative" "$T/jni.json"
}

test_ghidra() {
    local lib; lib=$(native_lib)
    cp "$lib" "$T/libnative-lib.so"
    run ghidra-decompile "$T/libnative-lib.so" "$T/libnative-lib.c"
    expect_grep "Java_com_example_simple_NativeLib_getSecretFromNative" "$T/libnative-lib.c"
}

test_objection() {
    run objection version
    expect_out "objection: "
    run objection@16 version
    # patchapk must inject the gadget baked into the image, without downloading
    # (objection exits 0 on most errors: check the output APK)
    cp "$(res_apk)" "$T/simple.apk"
    run objection patchapk -s "$T/simple.apk" -a arm64-v8a
    expect_out "baked into the jddlab image: $(cat /usr/local/frida-gadgets/VERSION)"
    grep -q "Downloading" "$T/out.log" && fail "objection downloaded a gadget"
    expect_zip_entry "$T/simple.objection.apk" '^lib/arm64-v8a/libfrida-gadget\.so$'
}

test_objection16() {
    cp "$(res_apk)" "$T/simple.apk"
    run objection@16 patchapk -s "$T/simple.apk" -a arm64-v8a
    expect_out "baked into the jddlab image: $(cat /usr/local/frida-gadgets/VERSION-16)"
    grep -q "Downloading" "$T/out.log" && fail "objection@16 downloaded a gadget"
    expect_zip_entry "$T/simple.objection.apk" '^lib/arm64-v8a/libfrida-gadget\.so$'
}

test_android_unpinner() {
    cp "$APK" "$T/simple.apk"
    # patch-apks makes the APK debuggable and re-signs it (the gadget is pushed at runtime)
    run android-unpinner patch-apks "$T/simple.apk"
    expect_file "$T/simple.unpinned.apk"
    run apksigner verify "$T/simple.unpinned.apk"
    run androguard axml "$T/simple.unpinned.apk"
    expect_out 'android:debuggable="true"'
    # Its unpinning scripts use the global `Java` object, which only frida 16 gadgets
    # provide to plain scripts: the vendored gadgets must be the baked 16.x ones.
    local vendor gadget
    vendor=$(ls -d /usr/local/python-venv/lib/python*/site-packages/android_unpinner/vendor/frida)
    gadget=$(readlink -f "$vendor"/frida-gadget-*-android-arm64.so)
    [ "$gadget" = "/usr/local/frida-gadgets/frida-gadget-$(cat /usr/local/frida-gadgets/VERSION-16)-android-arm64.so" ]         || fail "android-unpinner uses $gadget, not the baked frida 16 gadget"
    # JDWP connects to the `adb forward` port where the ADB server runs (host ADB mode)
    grep -q JDDLAB_ADB_FORWARD_HOST "$vendor"/../../__main__.py || fail "android-unpinner isn't patched for the host ADB server"
}

test_apk_patcher() {
    cp "$APK" "$T/simple.apk"
    run apk-patcher -a arm64-v8a ./simple.
    expect_out "Using cached Frida gadget"
    grep -q "downloading from GitHub" "$T/out.log" && fail "apk-patcher downloaded a gadget"
    # a requested version that is baked in (frida 16.x) is taken from the image too
    mkdir -p "$T/v16" && cp "$APK" "$T/v16/simple.apk"
    (cd "$T/v16" && apk-patcher -a arm64-v8a --frida-version "$(cat /usr/local/frida-gadgets/VERSION-16)" ./simple. >"$T/v16.log" 2>&1) \
        || fail "apk-patcher --frida-version failed"
    grep -q "Using cached Frida gadget" "$T/v16.log" || fail "apk-patcher --frida-version didn't use the baked gadget"
    # The gadget must come with a config: loaded from inside the APK (native libs
    # not extracted) it doesn't start without one. Default: listen and wait.
    expect_gadget_config() {  # <apk> <expected config substring>
        python3 - "$1" "$2" <<'EOF' || fail "no gadget + config '$2' in $1"
import sys, zipfile
names = zipfile.ZipFile(sys.argv[1]).namelist()
config = zipfile.ZipFile(sys.argv[1]).read("lib/arm64-v8a/libgadget.config.so").decode()
print("    gadget config:", config)
sys.exit(0 if "lib/arm64-v8a/libgadget.so" in names and sys.argv[2] in config else 1)
EOF
    }
    expect_gadget_config "$T/simple.patched/simple.apk" '"listen"'
    # -l: the gadget runs the script itself (script interaction)
    mkdir -p "$T/script" && cp "$APK" "$T/script/simple.apk"
    echo 'console.log("jddlab");' >"$T/script/agent.js"
    (cd "$T/script" && apk-patcher -a arm64-v8a -l agent.js ./simple. >"$T/script.log" 2>&1) || fail "apk-patcher -l failed"
    expect_gadget_config "$T/script/simple.patched/simple.apk" '"script"'
    # -c: a custom config is used
    mkdir -p "$T/config" && cp "$APK" "$T/config/simple.apk"
    (cd "$T/config" && apk-patcher -a arm64-v8a -c /root/frida/config/onload_nowait.config ./simple. >"$T/config.log" 2>&1)         || fail "apk-patcher -c failed"
    expect_gadget_config "$T/config/simple.patched/simple.apk" '"resume"'
}

test_frida() {
    run frida --version
    local frida_major gadget_major
    frida_major=$(frida --version | cut -d. -f1)
    gadget_major=$(cut -d. -f1 /usr/local/frida-gadgets/VERSION)
    [ "$frida_major" = "$gadget_major" ] || fail "frida $frida_major.x does not match baked gadget $gadget_major.x"
    # Exercises the native frida module: enumerate local processes
    run frida-ps
    expect_out "PID"
    run frida@16 --version
    expect_out "16."
    if [ $emulated -eq 0 ]; then
        # Real instrumentation, non-interactive (the way MCP runs it): spawn a local
        # process, inject a script, print from inside it. (ptrace-based injection is
        # impossible under QEMU user-mode emulation.)
        run frida -q -t 2 -f /bin/sleep -e 'console.log("frida-smoke-ok arch=" + Process.arch)' 5 </dev/null
        expect_out "frida-smoke-ok arch="
    fi
}

test_adb() {
    run adb version
    expect_out "Android Debug Bridge"
}

test_adb_forward() {
    # JDDLAB_ADB_SERVER: the entrypoint forwards 127.0.0.1:5037 to an external ADB
    # server. Simulate the host server with an ADB server on another port.
    run adb -P 5038 start-server
    run env JDDLAB_ADB_SERVER=127.0.0.1:5038 /usr/local/jddlab/entrypoint.sh adb devices
    expect_out "List of devices attached"
    adb -P 5038 kill-server >/dev/null 2>&1
    pkill -f "TCP-LISTEN:5037" 2>/dev/null
    true
}

test_hermes_dec() {
    local hbc="$FIXTURES/index.android.bundle"
    run hbc-file-parser "$hbc"
    expect_out "SourceHash"
    run hbc-disassembler "$hbc" "$T/out.hasm"
    expect_grep "jddlabCheckLicense" "$T/out.hasm"
    run hbc-decompiler "$hbc" "$T/out.js"
    expect_grep "JDDLAB-SECRET-KEY-1234" "$T/out.js"
}

test_pyxamstore() {
    # Build an LZ4-compressed V1 assembly store (assemblies.blob + manifest) holding
    # the .NET fixture with pyxamstore's own packer, unpack it with the CLI and
    # compare; then repack it with the CLI.
    mkdir -p "$T/store" "$T/in"
    cp "$FIXTURES/dotnet/Fixture.dll" "$T/in/Fixture.dll"
    cat >"$T/store/assemblies.json" <<EOF
{"stores": [{"assemblies.blob": {"header": {"version": 1, "lec": 1, "gec": 1, "store_id": 0}}}],
 "assemblies": [{"name": "Fixture", "store_id": 0, "blob_idx": 0, "file": "$T/in/Fixture.dll", "lz4": true, "lz4_desc_idx": 0}]}
EOF
    cd "$T/store"
    cat >"$T/pack.py" <<'PY'
import json, sys
from pyxamstore.v1 import do_pack, gen_xxhash
config = json.load(open("assemblies.json"))
for assembly in config["assemblies"]:
    h32, h64 = gen_xxhash(assembly["name"])
    assembly["hash32"], assembly["hash64"] = "0x" + h32, "0x" + h64
json.dump(config, open("assemblies.json", "w"))
sys.exit(do_pack("assemblies.json"))
PY
    run /usr/local/python-venvs/venvs/venvs/pyxamstore/bin/python "$T/pack.py"
    mv assemblies.blob.new assemblies.blob
    mv assemblies.manifest.new assemblies.manifest
    head -c 4 assemblies.blob | grep -q XABA || fail "not an assembly store"
    run pyxamstore "$T/store/assemblies.blob" -u
    expect_out "Extracting Fixture"
    cmp -s "$T/store/out/Fixture.dll" "$T/in/Fixture.dll" || fail "extracted assembly differs from the original"
    run pyxamstore assemblies.blob assemblies.json -p
    expect_file "$T/store/assemblies.blob.new"
}

test_ilspycmd() {
    run ilspycmd -p -o "$T/out" "$FIXTURES/dotnet/Fixture.dll"
    expect_grep "class Unsafe" "$T/out"
}

test_blutter_toolchain() {
    # A real blutter run needs a Flutter app and compiles a Dart VM (minutes),
    # so only check that blutter starts and its build toolchain works.
    run_any blutter --help
    expect_out "--dart-version"
    run pkg-config --exists capstone icu-uc
    cat >"$T/t.cpp" <<'EOF'
#include <format>
#include <capstone/capstone.h>
int main() { csh h; return cs_open(CS_ARCH_ARM64, CS_MODE_ARM, &h) == CS_ERR_OK && std::format("{}", 1) == "1" ? 0 : 1; }
EOF
    run g++ -std=c++20 -o "$T/t" "$T/t.cpp" -lcapstone
    run "$T/t"
    run cmake --version
    run ninja --version
}

test_quark() {
    run quark -a "$APK" -s
    expect_out "Total Score"
}

test_mobsfscan() {
    # The fixture has known-insecure code; also catches a missing semgrep, which
    # mobsfscan only reports in the "errors" section of its report.
    # (Copied: mobsfscan skips paths with a "tests" directory, like $FIXTURES.)
    cp -r "$FIXTURES/src/mobsfscan" "$T/src"
    run_any mobsfscan --json -o "$T/report.json" "$T/src"
    expect_file "$T/report.json"
    python3 - "$T/report.json" <<'PY' || fail "unexpected mobsfscan report"
import json, sys
report = json.load(open(sys.argv[1]))
print("    errors:", report.get("errors"), "results:", sorted(report.get("results", {})))
sys.exit(0 if not report.get("errors") and {"weak_hash", "aes_ecb_mode"} <= set(report.get("results", {})) else 1)
PY
}

# --- runner -----------------------------------------------------------------

all_tests=$(declare -F | awk '{print $3}' | grep '^test_' | sed 's/^test_//')
if [ ${#selected[@]} -gt 0 ]; then
    tests="${selected[*]}"
elif [ $native_only -eq 1 ]; then
    tests="$NATIVE_TESTS"
else
    tests="$all_tests"
fi

if [ $list_only -eq 1 ]; then
    for t in $all_tests; do
        case " $NATIVE_TESTS " in *" $t "*) echo "$t (native)" ;; *) echo "$t" ;; esac
    done
    exit 0
fi

echo "jddlab smoke tests: $(cat /usr/local/jddlab/version.txt 2>/dev/null) on $(uname -m)"
passed=(); failed=()
start_all=$(date +%s)
for t in $tests; do
    if ! declare -F "test_$t" >/dev/null; then
        echo "Unknown test: $t" >&2; failed+=("$t"); continue
    fi
    T="$WORK/$t"; mkdir -p "$T"
    echo "=== $t"
    start=$(date +%s)
    ( cd "$T" && set +e && "test_$t" )
    rc=$?
    secs=$(( $(date +%s) - start ))
    if [ $rc -eq 0 ]; then
        echo "--- PASS $t (${secs}s)"; passed+=("$t")
    else
        echo "--- FAIL $t (${secs}s)"; failed+=("$t")
    fi
done

echo
echo "Passed: ${#passed[@]}, failed: ${#failed[@]}, total time: $(( $(date +%s) - start_all ))s"
[ ${#failed[@]} -eq 0 ] || echo "FAILED: ${failed[*]}"
[ $keep -eq 1 ] && echo "Work directory: $WORK" || rm -rf "$WORK"
[ ${#failed[@]} -eq 0 ]
