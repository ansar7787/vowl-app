package com.vowl.app

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.ActivityInfo
import android.graphics.Color
import android.net.Uri
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val EMAIL_CHANNEL = "com.vowl.app/email_launcher"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EMAIL_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "openEmailInbox") {
                    try {
                        // 1. Primary: open default email application directly to its Main / Inbox dashboard
                        val emailAppIntent = Intent(Intent.ACTION_MAIN).apply {
                            addCategory(Intent.CATEGORY_APP_EMAIL)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        if (emailAppIntent.resolveActivity(packageManager) != null) {
                            startActivity(emailAppIntent)
                            result.success(true)
                            return@setMethodCallHandler
                        }

                        // 2. Secondary fallback: generic mail view intent
                        val mailtoIntent = Intent(Intent.ACTION_VIEW, Uri.parse("mailto:")).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        if (mailtoIntent.resolveActivity(packageManager) != null) {
                            startActivity(mailtoIntent)
                            result.success(true)
                            return@setMethodCallHandler
                        }

                        result.success(false)
                    } catch (e: ActivityNotFoundException) {
                        result.success(false)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        // Lock portrait orientation at the native level (belt-and-suspenders with manifest)
        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT

        // Enable edge-to-edge: tells the system this app draws behind system bars
        // and needs correct inset reporting (critical for 3-button navigation)
        WindowCompat.setDecorFitsSystemWindows(window, false)

        // Read theme preference before super.onCreate to prevent flicker
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isDarkMode = prefs.getBoolean("flutter.dark_mode", false)
        
        if (isDarkMode) {
            // Force dark background if user preference is dark
            window.decorView.setBackgroundColor(Color.parseColor("#020617"))
        } else {
            // Check if system is dark (fallback)
            val isSystemDark = (resources.configuration.uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK) == android.content.res.Configuration.UI_MODE_NIGHT_YES
            if (isSystemDark && !prefs.contains("flutter.dark_mode")) {
                 window.decorView.setBackgroundColor(Color.parseColor("#020617"))
            } else {
                 window.decorView.setBackgroundColor(Color.WHITE)
            }
        }
        
        super.onCreate(savedInstanceState)
    }
}
