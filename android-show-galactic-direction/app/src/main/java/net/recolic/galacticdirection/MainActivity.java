// created by Gemini 4 Hydrogen
package net.recolic.galacticdirection;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.graphics.Typeface;
import android.hardware.GeomagneticField;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.os.Bundle;
import android.text.SpannableStringBuilder;
import android.text.Spanned;
import android.text.style.ForegroundColorSpan;
import android.text.style.RelativeSizeSpan;
import android.view.MotionEvent;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.TimeZone;

public class MainActivity extends Activity implements SensorEventListener, LocationListener {
    private static final int REQ_LOCATION = 1;
    private SensorManager sensors;
    private LocationManager locations;
    private TextView view;

    private boolean usingRotationVector;
    private final float[] rotMatrix = new float[9];
    private final float[] accel = new float[3];
    private final float[] mag = new float[3];
    private boolean hasAccel, hasMag, hasPointing;
    private final double[] smoothEnu = new double[3];

    private int sensorAccuracy = SensorManager.SENSOR_STATUS_UNRELIABLE;
    private float reportedHeadingErrRad = -1f;
    private double magNormUt = -1.0;
    private Location location;
    private long lastPaintMs;
    private boolean frozen;
    private Button freezeBtn;
    private final SimpleDateFormat utcFmt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US);

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        utcFmt.setTimeZone(TimeZone.getTimeZone("UTC"));

        view = new TextView(this);
        view.setTextColor(0xFFD8E4F8);
        view.setBackgroundColor(0xFF080C14);
        view.setTypeface(Typeface.MONOSPACE);
        view.setTextSize(16);
        view.setPadding(40, 56, 40, 56);

        ScrollView scroll = new ScrollView(this);
        scroll.setBackgroundColor(0xFF080C14);
        scroll.addView(view);

        freezeBtn = new Button(this);
        freezeBtn.setText("Stop Refresh");
        freezeBtn.setAllCaps(false);
        freezeBtn.setTextSize(18);
        freezeBtn.setTextColor(0xFFE8F0FF);
        freezeBtn.setBackgroundColor(0xFF1A2639);
        freezeBtn.setPadding(32, 36, 32, 36);
        freezeBtn.setOnTouchListener((v, e) -> {
            if (frozen) return false;
            int action = e.getActionMasked();
            if (action == MotionEvent.ACTION_DOWN) {
                v.getParent().requestDisallowInterceptTouchEvent(true);
                freezeBtn.setText("release to stop");
                return true;
            }
            if (action == MotionEvent.ACTION_MOVE) return true;
            if (action == MotionEvent.ACTION_UP || action == MotionEvent.ACTION_CANCEL) {
                frozen = true;
                freezeBtn.setText("resume refresh");
                return true;
            }
            return false;
        });
        freezeBtn.setOnClickListener(v -> {
            if (!frozen) return;
            frozen = false;
            freezeBtn.setText("Stop Refresh");
            paint();
        });

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(0xFF080C14);
        root.addView(scroll, new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f));
        LinearLayout.LayoutParams btnLp = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        btnLp.setMargins(40, 16, 40, 40);
        root.addView(freezeBtn, btnLp);
        setContentView(root);

        sensors = (SensorManager) getSystemService(SENSOR_SERVICE);
        locations = (LocationManager) getSystemService(Context.LOCATION_SERVICE);
        view.setText("Initializing sensors & GPS...");

        if (checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(new String[]{Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION}, REQ_LOCATION);
        } else {
            startLocation();
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        Sensor rv = sensors.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR);
        Sensor m = sensors.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD);
        if (rv != null) {
            usingRotationVector = true;
            sensors.registerListener(this, rv, SensorManager.SENSOR_DELAY_UI);
            if (m != null) sensors.registerListener(this, m, SensorManager.SENSOR_DELAY_UI);
        } else {
            usingRotationVector = false;
            Sensor a = sensors.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
            if (a != null) sensors.registerListener(this, a, SensorManager.SENSOR_DELAY_UI);
            if (m != null) sensors.registerListener(this, m, SensorManager.SENSOR_DELAY_UI);
        }
        if (checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED || checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
            startLocation();
        }
    }

    @Override
    protected void onPause() {
        super.onPause();
        sensors.unregisterListener(this);
        if (locations != null) locations.removeUpdates(this);
    }

    @Override
    public void onRequestPermissionsResult(int code, String[] perms, int[] results) {
        if (code == REQ_LOCATION && results.length > 0 && results[0] == PackageManager.PERMISSION_GRANTED) {
            startLocation();
        } else {
            view.setText("Location permission denied.\nGPS coordinates are required to compute Local Sidereal Time and Galactic direction.");
        }
    }

    private void startLocation() {
        boolean fine = checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED;
        boolean coarse = checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED;
        if (!fine && !coarse) return;
        try {
            Location gpsLast = locations.getLastKnownLocation(LocationManager.GPS_PROVIDER);
            Location netLast = locations.getLastKnownLocation(LocationManager.NETWORK_PROVIDER);
            Location best = pickBetter(gpsLast, netLast);
            if (best != null) location = best;
            if (locations.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                locations.requestLocationUpdates(LocationManager.GPS_PROVIDER, 2000, 1, this);
            }
            if (locations.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
                locations.requestLocationUpdates(LocationManager.NETWORK_PROVIDER, 5000, 10, this);
            }
            paint();
        } catch (Exception e) {
            view.setText("Location provider error: " + e.getMessage());
        }
    }

    private static Location pickBetter(Location a, Location b) {
        if (a == null) return b;
        if (b == null) return a;
        return a.getTime() >= b.getTime() ? a : b;
    }

    @Override
    public void onLocationChanged(Location next) {
        if (location == null || LocationManager.GPS_PROVIDER.equals(next.getProvider()) || !LocationManager.GPS_PROVIDER.equals(location.getProvider()) || (next.getTime() - location.getTime() > 30000)) {
            location = next;
            paint();
        }
    }

    @Override
    public void onAccuracyChanged(Sensor sensor, int accuracy) {
        if (usingRotationVector && sensor.getType() == Sensor.TYPE_ROTATION_VECTOR) {
            sensorAccuracy = accuracy;
        } else if (!usingRotationVector && sensor.getType() == Sensor.TYPE_MAGNETIC_FIELD) {
            sensorAccuracy = accuracy;
        }
    }

    @Override
    public void onSensorChanged(SensorEvent event) {
        if (event.sensor.getType() == Sensor.TYPE_MAGNETIC_FIELD) {
            float mx = event.values[0], my = event.values[1], mz = event.values[2];
            magNormUt = Math.sqrt(mx * mx + my * my + mz * mz);
        }
        if (usingRotationVector && event.sensor.getType() == Sensor.TYPE_ROTATION_VECTOR) {
            SensorManager.getRotationMatrixFromVector(rotMatrix, event.values);
            reportedHeadingErrRad = event.values.length >= 5 ? event.values[4] : -1f;
            sensorAccuracy = event.accuracy;
            updateSmoothEnu(rotMatrix[1], rotMatrix[4], rotMatrix[7]);
        } else if (!usingRotationVector) {
            if (event.sensor.getType() == Sensor.TYPE_ACCELEROMETER) {
                System.arraycopy(event.values, 0, accel, 0, 3);
                hasAccel = true;
            } else if (event.sensor.getType() == Sensor.TYPE_MAGNETIC_FIELD) {
                System.arraycopy(event.values, 0, mag, 0, 3);
                hasMag = true;
                sensorAccuracy = event.accuracy;
            }
            if (hasAccel && hasMag && SensorManager.getRotationMatrix(rotMatrix, null, accel, mag)) {
                updateSmoothEnu(rotMatrix[1], rotMatrix[4], rotMatrix[7]);
            }
        }
        long now = System.currentTimeMillis();
        if (now - lastPaintMs >= 100) {
            lastPaintMs = now;
            paint();
        }
    }

    private void updateSmoothEnu(double e, double n, double u) {
        double alpha = hasPointing ? 0.15 : 1.0;
        smoothEnu[0] = smoothEnu[0] * (1.0 - alpha) + e * alpha;
        smoothEnu[1] = smoothEnu[1] * (1.0 - alpha) + n * alpha;
        smoothEnu[2] = smoothEnu[2] * (1.0 - alpha) + u * alpha;
        double norm = Math.sqrt(smoothEnu[0] * smoothEnu[0] + smoothEnu[1] * smoothEnu[1] + smoothEnu[2] * smoothEnu[2]);
        if (norm > 1e-6) {
            smoothEnu[0] /= norm;
            smoothEnu[1] /= norm;
            smoothEnu[2] /= norm;
            hasPointing = true;
        }
    }

    private void paint() {
        if (frozen) return;
        if (!hasPointing) { view.setText("Waiting for orientation sensors..."); return; }
        if (location == null) { view.setText("Waiting for GPS fix...\n(Step outside or enable Location)"); return; }

        long nowMs = System.currentTimeMillis();
        double altM = location.hasAltitude() ? location.getAltitude() : 0.0;
        GeomagneticField gmf = new GeomagneticField((float) location.getLatitude(), (float) location.getLongitude(), (float) altM, nowMs);
        double declDeg = gmf.getDeclination();
        AstroMath.Result res = AstroMath.compute(smoothEnu[0], smoothEnu[1], smoothEnu[2], declDeg, location.getLatitude(), location.getLongitude(), nowMs);

        double gpsAccM = location.hasAccuracy() ? location.getAccuracy() : 100.0;
        double fixAgeSec = Math.max(0.0, (nowMs - location.getTime()) / 1000.0);
        double azErrDeg = estimateAzimuthErrorDeg();
        double sensorErrDeg = estimateSensorErrorDeg(res.altDeg, azErrDeg);
        double gpsAngleErrDeg = Math.toDegrees(gpsAccM / 6371000.0);
        double totalErrDeg = Math.sqrt(sensorErrDeg * sensorErrDeg + gpsAngleErrDeg * gpsAngleErrDeg + 0.5 * 0.5);

        String bigEquatorial = String.format(Locale.US, "RA  %7.2f°\nDec %+7.2f°\n", res.raJ2000Deg, res.decJ2000Deg);
        String magStr = magNormUt > 0 ? String.format(Locale.US, "%.1f µT", magNormUt) : "n/a";
        String body = String.format(Locale.US,
            "\nAIM (phone top edge -> sky)\n" +
            "True Az / Alt : %6.2f° / %+6.2f°\n" +
            "Est. Error    : ±%.1f° (Accuracy=%s)\n" +
            "\nCALCULATED OFFSETS & DEBUG\n" +
            "Est. Az Error   : ±%.1f°\n" +
            "Mag Decl / |B|: %+6.2f° (WMM) / %s\n" +
            "Precession Δ    : %+6.3f° RA, %+6.3f° Dec\n" +
            "Galactic (J2000): l %6.2f°  b %+6.2f°\n" +
            "LST / UTC       : %6.2f° / %s\n" +
            "GPS (%s)       : %.4f°, %.4f° (±%.0fm, %ds ago)\n" +
            "Sensor Mode     : %s\n",
            res.azTrueDeg, res.altDeg, totalErrDeg, accuracyLabel(sensorAccuracy),
            azErrDeg,
            res.declDeg, magStr, res.precessionRaDeg, res.precessionDecDeg,
            res.galLDeg, res.galBDeg, res.lstDeg, utcFmt.format(new Date(nowMs)),
            location.getProvider(), location.getLatitude(), location.getLongitude(), gpsAccM, (long) fixAgeSec,
            usingRotationVector ? "ROTATION_VECTOR (gyro+mag)" : "ACCEL+MAG fallback");

        String header = "EQUATORIAL (J2000)\n";
        SpannableStringBuilder sb = new SpannableStringBuilder(header + bigEquatorial + body);
        int eqStart = header.length();
        int eqEnd = eqStart + bigEquatorial.length();
        sb.setSpan(new RelativeSizeSpan(1.9f), eqStart, eqEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
        sb.setSpan(new ForegroundColorSpan(0xFF7CE8FF), eqStart, eqEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
        view.setText(sb);
    }

    private double estimateAzimuthErrorDeg() {
        double azErr = sensorAccuracy == SensorManager.SENSOR_STATUS_ACCURACY_HIGH ? 2.5
            : sensorAccuracy == SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM ? 6.0
            : sensorAccuracy == SensorManager.SENSOR_STATUS_ACCURACY_LOW ? 15.0 : 25.0;
        if (reportedHeadingErrRad > 0 && reportedHeadingErrRad < 1.5) {
            azErr = Math.max(azErr, Math.toDegrees(reportedHeadingErrRad));
        }
        return azErr;
    }

    private double estimateSensorErrorDeg(double altDeg, double azErr) {
        double azProj = azErr * Math.cos(Math.toRadians(altDeg));
        double tiltErr = 1.5;
        return Math.sqrt(azProj * azProj + tiltErr * tiltErr);
    }

    private static String accuracyLabel(int acc) {
        if (acc == SensorManager.SENSOR_STATUS_ACCURACY_HIGH) return "HIGH";
        if (acc == SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM) return "MEDIUM";
        if (acc == SensorManager.SENSOR_STATUS_ACCURACY_LOW) return "LOW - calibrate figure-8";
        return "UNRELIABLE - calibrate figure-8";
    }
}
