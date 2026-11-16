package com.example.insecure;

import android.util.Log;
import android.webkit.WebView;
import java.security.MessageDigest;
import java.util.Random;
import javax.crypto.Cipher;

// jddlab smoke-test fixture: intentionally insecure code that mobsfscan must flag.
public class Insecure {
    public byte[] hash(byte[] data) throws Exception {
        return MessageDigest.getInstance("MD5").digest(data);
    }

    public Cipher cipher() throws Exception {
        return Cipher.getInstance("AES/ECB/PKCS5Padding");
    }

    public int token() {
        return new Random().nextInt();
    }

    public void web(WebView view, String password) {
        view.getSettings().setJavaScriptEnabled(true);
        view.getSettings().setAllowFileAccess(true);
        Log.d("Insecure", "password=" + password);
    }
}
