package com.freematch.app

import io.flutter.embedding.android.FlutterActivity

import androidx.core.view.WindowCompat

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        // Aligns the Window with the screen edges to allow edge-to-edge content.
        WindowCompat.setDecorFitsSystemWindows(window, false)
        super.onCreate(savedInstanceState)
    }
}
