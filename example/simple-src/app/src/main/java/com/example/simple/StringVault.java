package com.example.simple;

/**
 * Runtime string decryption, the way obfuscators hide strings from `strings`/jadx.
 * The plaintext of {@link #HIDDEN_ENDPOINT} never appears in the APK; simplify
 * (`simplify -it com/example/simple ...`) or a Frida hook on {@link #d} recovers it.
 *
 * Each char is XOR-ed with (0x2A + index). R8 renames this class and method.
 */
final class StringVault {

    // "https://admin.internal.example.com/debug?key=dbg-7f3a9c", encoded
    static final String HIDDEN_ENDPOINT =
            "\102\137\130\135\135\025\037\036\123\127\131\134\130\031"
            + "\121\127\116\136\116\123\137\123\156\044\072\042\051\065"
            + "\052\042\146\052\045\046\143\051\053\055\045\066\155\070"
            + "\061\054\153\063\072\076\167\154\072\156\077\146\003";

    private StringVault() {
    }

    static String d(String s) {
        char[] c = s.toCharArray();
        for (int i = 0; i < c.length; i++) {
            c[i] = (char) (c[i] ^ ((0x2A + i) & 0xFF));
        }
        return new String(c);
    }
}
