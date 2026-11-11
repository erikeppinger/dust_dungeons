package io.github.changeme.homework_and_chores

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val main = Handler(Looper.getMainLooper())

    /** The backup call waiting for a system picker, with what to do with its answer. */
    private var pending: Pair<MethodChannel.Result, (Uri) -> Any?>? = null

    /** Runs [work] off the main thread and answers [result] with what it returns. */
    private fun background(result: MethodChannel.Result, tag: String, work: () -> Any?) =
        Thread {
            try {
                val value = work()
                main.post { result.success(value) }
            } catch (e: Exception) {
                main.post { result.error(tag, e.message, null) }
            }
        }.start()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "screen_time")
            .setMethodCallHandler { call, result ->
                // Package manager and usage queries run off the main thread.
                val background = { work: () -> Any? -> background(result, "screen_time", work) }
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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "home_widget")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "placed" -> result.success(QuestWidget.placed(this))
                    "refresh" -> {
                        QuestWidget.refresh(this)
                        result.success(null)
                    }
                    "ticks" -> result.success(Ticks.all(this))
                    "dropTicks" -> {
                        // Dart sends small numbers as Int, large ones as Long.
                        val at = call.argument<List<Number>>("at") ?: listOf()
                        Ticks.drop(this, at.map { it.toLong() })
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "haptics")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "beat" -> {
                        Haptics.beat(this)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "backup")
            .setMethodCallHandler { call, result ->
                // File copies run off the main thread.
                val background = { work: () -> Any? -> background(result, "backup", work) }
                fun folder() = Uri.parse(call.argument<String>("folder")!!)
                when (call.method) {
                    "saveAs" -> {
                        val path = call.argument<String>("path")!!
                        pick(result, Backup.createDocumentIntent(call.argument<String>("name")!!)) {
                            Backup.writeTo(this, it, path)
                            true
                        }
                    }
                    "open" -> {
                        val dest = File(call.argument<String>("dest")!!)
                        pick(result, Backup.openDocumentIntent()) {
                            Backup.readFrom(this, it, dest)
                            dest.path
                        }
                    }
                    "pickFolder" -> pick(result, Backup.openFolderIntent()) {
                        Backup.keepFolder(this, it)
                        it.toString()
                    }
                    "folderName" -> background { Backup.folderName(this, folder()) }
                    "writeToFolder" -> background {
                        Backup.writeToFolder(
                            this,
                            folder(),
                            call.argument<String>("name")!!,
                            call.argument<String>("path")!!,
                        )
                        null
                    }
                    "pruneFolder" -> background {
                        Backup.pruneFolder(
                            this,
                            folder(),
                            call.argument<String>("prefix")!!,
                            call.argument<Int>("keep")!!,
                        )
                        null
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Opens a system picker; [then] gets the picked URI (off the main thread) and its
     * return value answers the call. Cancelling answers null.
     */
    private fun pick(result: MethodChannel.Result, intent: Intent, then: (Uri) -> Any?) {
        if (pending != null) {
            result.error("backup", "a picker is already open", null)
            return
        }
        pending = result to then
        startActivityForResult(intent, PICK_REQUEST)
    }

    @Deprecated("FlutterActivity delivers results here")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_REQUEST) return
        val (result, then) = pending ?: return
        pending = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        background(result, "backup") { then(uri) }
    }

    private companion object {
        const val PICK_REQUEST = 4201
    }
}
