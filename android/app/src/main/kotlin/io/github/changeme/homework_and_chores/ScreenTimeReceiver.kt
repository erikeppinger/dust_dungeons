package io.github.changeme.homework_and_chores

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Runs the screen-time check, and re-arms it after a reboot or update. */
class ScreenTimeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ScreenTime.ACTION_CHECK -> {
                // Off the main thread; the usage query can take a moment.
                val pending = goAsync()
                Thread {
                    try {
                        ScreenTime.check(context)
                    } finally {
                        pending.finish()
                    }
                }.start()
            }
            Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED ->
                ScreenTime.reschedule(context)
        }
    }
}
