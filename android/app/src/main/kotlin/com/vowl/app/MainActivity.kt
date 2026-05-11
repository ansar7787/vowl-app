package com.vowl.app

import android.os.Bundle
import android.graphics.Color
import io.flutter.embedding.android.FlutterActivity
import android.content.Context

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
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
