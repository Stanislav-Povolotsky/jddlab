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
# automatically by AGP.)

# The app's own helpers are small and each is used once, so R8 would inline them
# all into MainActivity. Keep them as classes, but let R8 rename them and their
# members (com.example.simple.a, b, ...), as in a typical obfuscated app.
-keep,allowobfuscation class com.example.simple.** { *; }
