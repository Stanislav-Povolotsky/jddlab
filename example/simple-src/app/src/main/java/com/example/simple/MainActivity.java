package com.example.simple;

import android.app.Activity;
import android.os.Bundle;
import android.widget.TextView;

/**
 * Minimal launcher activity. Kept (referenced from the manifest) so R8 does not
 * rename it, while the helper classes it uses are obfuscated.
 */
public class MainActivity extends Activity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        TextView view = new TextView(this);
        view.setPadding(32, 64, 32, 32);
        view.setText(new SecretManager().describe());
        setContentView(view);
    }
}
