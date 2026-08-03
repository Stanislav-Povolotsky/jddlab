package com.example.simple;

/**
 * Holds intentionally-planted "secrets" so the sample is a realistic reverse
 * engineering target:
 *
 *  - Java-side hardcoded credentials  -> found by the secret-scanning skill (APKscan).
 *  - A call into native code          -> the real secret lives in native-lib.cpp and
 *                                        is recovered with the native-jni-analysis skill.
 *
 * This class is package-private and NOT kept, so R8 renames it and its members in the
 * release build - useful for the java-deobfuscation skill.
 *
 * NOTE: all values below are fake, non-functional placeholders (the AWS key is the
 * well-known example key from AWS documentation). Do not put real secrets in an APK.
 */
final class SecretManager {

    private static final String API_BASE_URL = "https://api.internal.example.com/v1";
    private static final String AWS_ACCESS_KEY_ID = "AKIAIOSFODNN7EXAMPLE";
    private static final String API_TOKEN = "sk_live_51H8xExampleTokenDoNotUseInProduction1234567890";

    private final NativeLib nativeLib = new NativeLib();

    String describe() {
        String nativeSecret = nativeLib.getSecretFromNative();
        boolean pinOk = nativeLib.verifyPin(nativeSecret);

        return "jddlab sample app\n\n"
                + "endpoint = " + API_BASE_URL + "\n"
                + "awsKeyId = " + AWS_ACCESS_KEY_ID + "\n"
                + "apiToken = " + API_TOKEN + "\n"
                + "nativeSecret = " + nativeSecret + "\n"
                + "verifyPin(nativeSecret) = " + pinOk;
    }
}
