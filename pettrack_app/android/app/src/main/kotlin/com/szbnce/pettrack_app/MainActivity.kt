package com.szbnce.pettrack_app

import android.os.Build
import android.view.View
import android.view.WindowInsetsController
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Owns the glyph tint of the system bars.
 *
 * Flutter sets it through the modern appearance flags, but the engine's
 * edge-to-edge pass clears the legacy light-bar flags and never puts them
 * back — and on some builds the clock and icons keep following those, so they
 * turn white over a light page. This re-asserts both vocabularies from the
 * activity's own window, and goes last so it wins over the engine's restore.
 */
class MainActivity : FlutterActivity() {
    private var darkStatusIcons = true
    private var darkNavIcons = true

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pettrack/system_ui")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setInk" -> {
                        darkStatusIcons = call.argument("status") ?: true
                        darkNavIcons = call.argument("nav") ?: true
                        applyInk()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onResume() {
        super.onResume()
        applyInk()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        // super() is where the engine restores its overlays — go after it.
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) applyInk()
    }

    private fun applyInk() {
        val decor = window.decorView
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.insetsController?.setSystemBarsAppearance(
                (if (darkStatusIcons) WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS else 0) or
                    (if (darkNavIcons) WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS else 0),
                WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS or
                    WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS,
            )
        }
        // Read-modify-write: the engine's layout flags live in the same word.
        @Suppress("DEPRECATION")
        var flags = decor.systemUiVisibility
        @Suppress("DEPRECATION")
        flags = setFlag(flags, View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR, darkStatusIcons)
        @Suppress("DEPRECATION")
        flags = setFlag(flags, View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR, darkNavIcons)
        @Suppress("DEPRECATION")
        decor.systemUiVisibility = flags
    }

    private fun setFlag(flags: Int, bit: Int, on: Boolean): Int = if (on) flags or bit else flags and bit.inv()
}
