package com.gathin.tvhome;

import android.app.Activity;
import android.app.ActivityManager;
import android.app.AlertDialog;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

/** All role changes stay in the vendor's system settings and require the owner's choice. */
public final class UnifiedSetupActivity extends Activity {
    private LinearLayout content;

    @Override protected void onCreate(Bundle state) {
        super.onCreate(state);
        ScrollView scroll = new ScrollView(this);
        content = new LinearLayout(this);
        content.setOrientation(LinearLayout.VERTICAL);
        int pad = Math.round(28 * getResources().getDisplayMetrics().density);
        content.setPadding(pad, pad, pad, pad);
        content.setBackgroundColor(0xff111c29);
        scroll.addView(content);
        setContentView(scroll);
        text("CleanYourTV Unified · Setup", 28);
        PackageManager pm = getPackageManager();
        ActivityManager am = (ActivityManager) getSystemService(ACTIVITY_SERVICE);
        text(Build.MANUFACTURER + " · " + Build.MODEL + " · Android " + Build.VERSION.RELEASE, 18);
        text(UnifiedCompatibility.summary(Build.VERSION.SDK_INT,
                pm.hasSystemFeature(PackageManager.FEATURE_LEANBACK)
                        || pm.hasSystemFeature(PackageManager.FEATURE_TELEVISION),
                resolves(Settings.ACTION_HOME_SETTINGS), resolves(Settings.ACTION_DREAM_SETTINGS),
                new Intent(Intent.ACTION_OPEN_DOCUMENT).setType("image/*").resolveActivity(pm) != null,
                am != null && am.isLowRamDevice()), 17);
        text("1. Add photos. Gallery and screensaver share one private library. "
                + "Photos in the older Concept B app stay there; upload your originals again.\n"
                + "2. Choose this screensaver in system settings. Some TVs hide this option.\n"
                + "3. Try Home before choosing it as default. Keep your stock launcher enabled.", 18);
        button("Open photo gallery / QR upload", () -> startActivity(new Intent(this, AmbientPhotoActivity.class)));
        button("Choose screensaver…", () -> openSettings(Settings.ACTION_DREAM_SETTINGS));
        button("Choose default Home…", () -> new AlertDialog.Builder(this)
                .setTitle("Choose your Home in system settings")
                .setMessage("Keep the manufacturer's launcher enabled. To roll back, choose it again "
                        + "in these settings. Installing Unified does not select it automatically.")
                .setNegativeButton("Cancel", null)
                .setPositiveButton("Open Home settings", (d, w) -> openSettings(Settings.ACTION_HOME_SETTINGS)).show());
        boolean regional = getSharedPreferences("unified", MODE_PRIVATE).getBoolean("bruneiOverlay", false);
        button(regional ? "Disable Brunei weather & prayer overlay" : "Enable Brunei weather & prayer overlay…", () -> {
            if (regional) { setRegional(false); return; }
            new AlertDialog.Builder(this).setTitle("Brunei-Muara overlay")
                    .setMessage("Optional preserved Concept B feature: Brunei time and 2026 PDI prayer "
                            + "table only. Weather contacts Open-Meteo for Bandar Seri Begawan. "
                            + "No GPS or personal location is sent. Other regions use photos only.")
                    .setNegativeButton("Cancel", null)
                    .setPositiveButton("Enable", (d, w) -> setRegional(true)).show();
        });
        button("Privacy, licences & recovery", () -> new AlertDialog.Builder(this)
                .setTitle("Privacy & recovery")
                .setMessage("No accounts, ads or analytics. Photos stay in this app's private storage. "
                        + "QR upload uses a random code, trusted LAN only and unencrypted HTTP. "
                        + "It stops when closed or after 10 minutes. Never forward its port.\n\n"
                        + "Recovery: open Android Settings and select your previous Home and screensaver. "
                        + "The two older packages are not changed. Clearing Unified data removes its photos.\n\n"
                        + "CleanYourTV © 2026 Gathin — MIT. Outfit — SIL OFL 1.1. "
                        + "AndroidX and ZXing — Apache 2.0. Full notices: unified/NOTICE.md and packaged assets.")
                .setPositiveButton("OK", null).show());
        button("Finish setup / Open Home", () -> {
            getSharedPreferences("unified", MODE_PRIVATE).edit().putBoolean("onboarded", true).apply();
            finish();
        }).requestFocus();
    }

    private void setRegional(boolean enabled) {
        getSharedPreferences("unified", MODE_PRIVATE).edit().putBoolean("bruneiOverlay", enabled).apply();
        recreate();
    }

    private boolean resolves(String action) {
        return new Intent(action).resolveActivity(getPackageManager()) != null;
    }

    private void openSettings(String action) {
        try { startActivity(new Intent(action)); }
        catch (ActivityNotFoundException | SecurityException unavailable) {
            try { startActivity(new Intent(Settings.ACTION_SETTINGS)); }
            catch (ActivityNotFoundException | SecurityException blocked) {
                Toast.makeText(this, "Use the Settings button on your TV remote.", Toast.LENGTH_LONG).show();
            }
        }
    }

    private void text(String value, int size) {
        TextView label = new TextView(this);
        label.setText(value); label.setTextSize(size); label.setTextColor(0xffedf4fa);
        label.setPadding(0, 8, 0, 8);
        content.addView(label);
    }

    private Button button(String label, Runnable action) {
        Button button = new Button(this);
        button.setText(label); button.setAllCaps(false);
        button.setOnClickListener(v -> action.run());
        content.addView(button, new LinearLayout.LayoutParams(-1, -2));
        return button;
    }
}
