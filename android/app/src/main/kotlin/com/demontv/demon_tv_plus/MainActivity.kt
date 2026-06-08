package com.demontv.demon_tv_plus

import android.graphics.Color
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Fondo negro para evitar pantalla blanca del sistema
        window.setBackgroundDrawableResource(android.R.color.black)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }
}
