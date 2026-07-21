package com.app.interview_test_app

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.location.LocationManager
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.location.LocationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "here_navigate_demo/location_permission"
    private val locationPermissionRequestCode = 9001
    private val prefsFileName = "location_permission_prefs"
    private val hasRequestedBeforeKey = "has_requested_location_permission_before"

    // Held between requestPermission() being called and
    // onRequestPermissionsResult() firing, since ActivityCompat's
    // request is async/callback-based, not a direct return value.
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isLocationServiceEnabled" -> result.success(isLocationServiceEnabled())
                    "checkPermission" -> result.success(currentPermissionStatus())
                    "requestPermission" -> requestPermission(result)
                    "openLocationSettings" -> {
                        startActivity(Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun isLocationServiceEnabled(): Boolean {
        val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        // Compat shim handles the API 28 isLocationEnabled() vs the
        // older isProviderEnabled() split for us across minSdk 24+.
        return LocationManagerCompat.isLocationEnabled(locationManager)
    }

    private fun currentPermissionStatus(): String {
        val fineGranted = ContextCompat.checkSelfPermission(
            this, Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        val coarseGranted = ContextCompat.checkSelfPermission(
            this, Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        return if (fineGranted || coarseGranted) "granted" else "denied"
    }

    private fun requestPermission(result: MethodChannel.Result) {
        if (currentPermissionStatus() == "granted") {
            result.success("granted")
            return
        }

        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION,
            ),
            locationPermissionRequestCode,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != locationPermissionRequestCode) return

        val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED

        val status = when {
            granted -> "granted"
            // shouldShowRequestPermissionRationale() returns false both
            // the very first time you ever ask AND after the user picks
            // "don't ask again" — the only way to tell those apart is to
            // remember, ourselves, whether we've asked before.
            ActivityCompat.shouldShowRequestPermissionRationale(
                this, Manifest.permission.ACCESS_FINE_LOCATION
            ) -> "denied"
            hasRequestedBefore() -> "deniedForever"
            else -> "denied"
        }

        markHasRequestedBefore()
        pendingPermissionResult?.success(status)
        pendingPermissionResult = null
    }

    private fun prefs(): SharedPreferences =
        getSharedPreferences(prefsFileName, Context.MODE_PRIVATE)

    private fun hasRequestedBefore(): Boolean =
        prefs().getBoolean(hasRequestedBeforeKey, false)

    private fun markHasRequestedBefore() {
        prefs().edit().putBoolean(hasRequestedBeforeKey, true).apply()
    }
}