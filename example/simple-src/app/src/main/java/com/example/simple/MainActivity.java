package com.example.simple;

import android.app.Activity;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.widget.TextView;

/**
 * Minimal launcher activity. Kept (referenced from the manifest) so R8 does not
 * rename it, while the helper classes it uses are obfuscated.
 */
public class MainActivity extends Activity {

    private static final String TAG = "jddlab-sample";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        TextView view = new TextView(this);
        view.setPadding(32, 64, 32, 32);
        String info = new SecretManager().describe();
        view.setText(info + "\n\nchecking certificate pinning...");
        setContentView(view);
        Log.i(TAG, info);

        // Re-run the pinning checks every few seconds so a Frida script attached after
        // launch (the common case: the gadget waits, you connect, then hook) still sees
        // a later request go through once pinning is bypassed. Tap the screen to re-run
        // immediately.
        Handler handler = new Handler(Looper.getMainLooper());
        Runnable[] check = new Runnable[1];
        check[0] = () -> {
            new Thread(() -> {
                String pinning = PinningChecks.run();
                for (String line : pinning.split("\n")) {
                    Log.i(TAG, line);
                }
                runOnUiThread(() -> view.setText(info + "\n\n" + pinning));
            }).start();
            handler.postDelayed(check[0], 5000);
        };
        view.setOnClickListener(v -> check[0].run());
        handler.post(check[0]);
    }
}
