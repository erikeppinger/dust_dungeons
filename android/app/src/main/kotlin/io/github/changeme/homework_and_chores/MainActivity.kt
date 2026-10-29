package io.github.changeme.homework_and_chores

import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val main = Handler(Looper.getMainLooper())
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "screen_time")
            .setMethodCallHandler { call, result ->
                // Package manager and usage queries run off the main thread.
                fun background(work: () -> Any?) = Thread {
                    try {
                        val value = work()
                        main.post { result.success(value) }
                    } catch (e: Exception) {
                        main.post { result.error("screen_time", e.message, null) }
                    }
                }.start()
                when (call.method) {
                    "hasAccess" -> result.success(ScreenTime.hasAccess(this))
                    "openAccessSettings" -> {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        result.success(null)
                    }
                    "launcherApps" -> background { ScreenTime.launcherApps(this) }
                    "usage" -> background {
                        ScreenTime.usage(
                            this,
                            call.argument<List<String>>("packages")!!.toSet(),
                            call.argument<Number>("from")!!.toLong(),
                            call.argument<Number>("to")!!.toLong(),
                        )
                    }
                    "writeSnapshot" -> {
                        ScreenTime.writeSnapshot(this, call.argument<String>("json")!!)
                        result.success(null)
                    }
                    "checkNow" -> background { ScreenTime.check(this); null }
                    else -> result.notImplemented()
                }
            }
    }
}
