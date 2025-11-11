package com.nekkochan.tlucalendar

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.nekkochan.tlucalendar/navigation"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openLicenseActivity" -> {
                    try {
                        val intent = Intent(this, LicenseActivity::class.java)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ACTIVITY_ERROR", "Failed to open LicenseActivity", e.message)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}

