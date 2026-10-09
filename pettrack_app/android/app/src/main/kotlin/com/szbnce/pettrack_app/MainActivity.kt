package com.szbnce.pettrack_app

import android.content.Intent
import android.os.Build
import android.view.View
import android.view.WindowInsetsController
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pettrack/updater")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "installApk" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("args", "missing path", null)
                            return@setMethodCallHandler
                        }
                        try {
                            installApk(path)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("install", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Hands a downloaded APK to the system installer. The installer shows
     * its own confirmation and does the actual work — this only launches
     * it with read access to the staged file.
     */
    private fun installApk(path: String) {
        val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", File(path))
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
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
