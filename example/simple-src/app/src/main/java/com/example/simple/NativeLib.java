package com.example.simple;

/**
 * JNI bridge. The native methods are implemented in src/main/cpp/native-lib.cpp and
 * bound statically by name (Java_com_example_simple_NativeLib_*), so these names are
 * preserved by R8 (see proguard-rules.pro).
 */
public final class NativeLib {

    static {
        System.loadLibrary("native-lib");
    }

    /** Returns a secret that is stored XOR-encoded inside the native library. */
    public native String getSecretFromNative();

    /** Dummy native "pin" check: true only when {@code value} equals the native secret. */
    public native boolean verifyPin(String value);
}
