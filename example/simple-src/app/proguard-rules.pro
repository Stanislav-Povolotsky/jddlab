# R8 / ProGuard rules for the jddlab sample.
#
# Keep JNI entry points: the native library binds functions by their fully-qualified
# Java name (Java_com_example_simple_NativeLib_getSecretFromNative), so the class and
# its native method names must NOT be renamed. Everything else is free to be shrunk
# and obfuscated by R8 - which is exactly what makes this a useful deobfuscation
# practice target.
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}

# (The launcher activity is referenced from AndroidManifest.xml and is kept
# automatically by AGP; SecretManager and other helpers are intentionally left to be
# renamed/obfuscated by R8.)
