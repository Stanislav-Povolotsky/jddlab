#include <jni.h>
#include <string>

// The demo "native secret" is stored XOR-encoded so it does NOT show up in plaintext
// when you run `strings` on the compiled .so; it is decoded at runtime. This mimics
// real apps that hide keys/pins in native code and is the practice target for the
// native-jni-analysis skill.
//
// enc[i] ^ 0x5A  ==  "n4t1v3-k3y"
static std::string decodeSecret() {
    static const unsigned char enc[] = {
        0x34, 0x6E, 0x2E, 0x6B, 0x2C, 0x69, 0x77, 0x31, 0x69, 0x23
    };
    const unsigned char key = 0x5A;
    std::string out;
    out.reserve(sizeof(enc));
    for (unsigned char c : enc) {
        out.push_back(static_cast<char>(c ^ key));
    }
    return out;
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_example_simple_NativeLib_getSecretFromNative(JNIEnv *env, jobject /* this */) {
    const std::string secret = decodeSecret();
    return env->NewStringUTF(secret.c_str());
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_example_simple_NativeLib_verifyPin(JNIEnv *env, jobject /* this */, jstring value) {
    if (value == nullptr) {
        return JNI_FALSE;
    }
    const char *chars = env->GetStringUTFChars(value, nullptr);
    const bool ok = (chars != nullptr) && (decodeSecret() == chars);
    if (chars != nullptr) {
        env->ReleaseStringUTFChars(value, chars);
    }
    return ok ? JNI_TRUE : JNI_FALSE;
}
