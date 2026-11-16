package com.example.simple;

import java.net.URL;

import javax.net.ssl.HttpsURLConnection;

import okhttp3.CertificatePinner;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

/**
 * Two HTTPS requests that are pinned to a public key the servers don't have, so both
 * fail with a pinning error until pinning is bypassed (android-unpinner, objection
 * `android sslpinning disable`, or a Frida script). No proxy is needed to see the
 * difference: "BLOCKED" turns into "OK HTTP 200".
 *
 *  - network_security_config.xml pins example.com (platform TrustManager, applies
 *    to HttpsURLConnection);
 *  - OkHttp's CertificatePinner pins example.org.
 *
 * Results go to the screen and to logcat (tag "jddlab-sample").
 */
final class PinningChecks {

    // SHA-256 of nothing in particular (32 zero bytes): no server has this key.
    private static final String BOGUS_PIN = "sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

    private PinningChecks() {
    }

    static String run() {
        return "pinning[network_security_config] https://example.com/ -> " + platformCheck() + "\n"
                + "pinning[okhttp CertificatePinner] https://example.org/ -> " + okHttpCheck();
    }

    private static String platformCheck() {
        HttpsURLConnection conn = null;
        try {
            conn = (HttpsURLConnection) new URL("https://example.com/").openConnection();
            conn.setConnectTimeout(10000);
            conn.setReadTimeout(10000);
            return "OK HTTP " + conn.getResponseCode();
        } catch (Exception e) {
            return blocked(e);
        } finally {
            if (conn != null) {
                conn.disconnect();
            }
        }
    }

    private static String okHttpCheck() {
        OkHttpClient client = new OkHttpClient.Builder()
                .certificatePinner(new CertificatePinner.Builder()
                        .add("example.org", BOGUS_PIN)
                        .build())
                .build();
        Request request = new Request.Builder().url("https://example.org/").build();
        try (Response response = client.newCall(request).execute()) {
            return "OK HTTP " + response.code();
        } catch (Exception e) {
            return blocked(e);
        }
    }

    private static String blocked(Exception e) {
        String msg = String.valueOf(e.getMessage());
        int nl = msg.indexOf('\n');
        return "BLOCKED (" + e.getClass().getSimpleName() + ": " + (nl < 0 ? msg : msg.substring(0, nl)) + ")";
    }
}
