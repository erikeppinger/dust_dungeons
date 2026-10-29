package io.github.changeme.homework_and_chores

import android.app.AlarmManager
import android.app.AppOpsManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.os.Build
import android.os.Process
import android.os.SystemClock
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.util.Calendar

/**
 * Soft screen-time budget, Android side: reads how long the chosen apps were
 * in the foreground (usage access), lists launcher apps for the picker, and
 * checks the budget every ~15 minutes in the background. The app writes a
 * small snapshot (budget, chosen apps, localized texts) that the check reads,
 * so no Dart code runs in the background. Usage never leaves the phone.
 */
object ScreenTime {
    private const val PREFS = "screen_time"
    private const val SNAPSHOT = "snapshot"
    private const val WARNED_DAY = "warnedDay"
    private const val OVER_NOTIFIED_AT = "overNotifiedAt"
    private const val CHANNEL = "screen_time"
    const val ACTION_CHECK = "io.github.changeme.homework_and_chores.SCREEN_TIME_CHECK"

    fun hasAccess(context: Context): Boolean {
        val ops = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ops.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName,
            )
        } else {
            @Suppress("DEPRECATION")
            ops.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName,
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    /** Foreground time per package in ms between [from] and [to] (epoch ms). */
    fun usage(context: Context, packages: Set<String>, from: Long, to: Long): Map<String, Long> {
        val result = packages.associateWith { 0L }.toMutableMap()
        if (packages.isEmpty() || !hasAccess(context)) return result
        val manager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val events = manager.queryEvents(from, to)
        val since = mutableMapOf<String, Long>()
        val event = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val pkg = event.packageName
            if (pkg !in packages) continue
            when (event.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED -> since.putIfAbsent(pkg, event.timeStamp)
                UsageEvents.Event.ACTIVITY_PAUSED, 23 /* ACTIVITY_STOPPED */ -> {
                    since.remove(pkg)?.let { start ->
                        result[pkg] = result.getValue(pkg) + (event.timeStamp - start)
                    }
                }
            }
        }
        // Still open at the end of the range.
        for ((pkg, start) in since) result[pkg] = result.getValue(pkg) + (to - start)
        return result
    }

    /** Apps with a launcher icon (not this one), sorted by name. */
    fun launcherApps(context: Context): List<Map<String, Any>> {
        val pm = context.packageManager
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        return pm.queryIntentActivities(intent, 0)
            .map { it.activityInfo.applicationInfo }
            .distinctBy { it.packageName }
            .filter { it.packageName != context.packageName }
            .map { info ->
                mapOf(
                    "package" to info.packageName,
                    "label" to pm.getApplicationLabel(info).toString(),
                    "icon" to iconPng(pm, info.packageName),
                )
            }
            .sortedBy { (it["label"] as String).lowercase() }
    }

    private fun iconPng(pm: PackageManager, pkg: String): ByteArray {
        val drawable = pm.getApplicationIcon(pkg)
        val size = 96
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        drawable.setBounds(0, 0, size, size)
        drawable.draw(Canvas(bitmap))
        return ByteArrayOutputStream().use {
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
            it.toByteArray()
        }
    }

    /** Stores the app's snapshot and starts or stops the background check. */
    fun writeSnapshot(context: Context, json: String) {
        prefs(context).edit().putString(SNAPSHOT, json).apply()
        schedule(context, JSONObject(json).optBoolean("enabled"))
    }

    fun schedule(context: Context, enabled: Boolean) {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = PendingIntent.getBroadcast(
            context,
            0,
            Intent(context, ScreenTimeReceiver::class.java).setAction(ACTION_CHECK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        alarms.cancel(intent)
        if (!enabled) return
        // Inexact and not waking the phone: usage only happens while it's awake.
        alarms.setInexactRepeating(
            AlarmManager.ELAPSED_REALTIME,
            SystemClock.elapsedRealtime() + AlarmManager.INTERVAL_FIFTEEN_MINUTES,
            AlarmManager.INTERVAL_FIFTEEN_MINUTES,
            intent,
        )
    }

    /** Re-arms the check after a reboot or an app update. */
    fun reschedule(context: Context) {
        val json = prefs(context).getString(SNAPSHOT, null) ?: return
        schedule(context, JSONObject(json).optBoolean("enabled"))
    }

    /** The background check: warn when little is left, remind when over. */
    fun check(context: Context) {
        val json = prefs(context).getString(SNAPSHOT, null) ?: return
        val snap = JSONObject(json)
        if (!snap.optBoolean("enabled")) return
        val today = dayKey(Calendar.getInstance())
        // On a new day the app has not written today's budget yet: the base.
        val budget = if (snap.optString("day") == today) {
            snap.optInt("budgetMinutes")
        } else {
            snap.optInt("baseMinutes")
        }
        val packages = snap.optJSONArray("packages")?.let { list ->
            (0 until list.length()).map { list.getString(it) }.toSet()
        } ?: emptySet()
        val start = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
        }.timeInMillis
        val now = System.currentTimeMillis()
        // Whole minutes per app, summed: the same count the app shows.
        val used = usage(context, packages, start, now).values.sumOf { it / 60000 }.toInt()
        val left = budget - used
        val texts = snap.optJSONObject("texts") ?: return
        val prefs = prefs(context)
        if (snap.optBoolean("warn") && left in 1..10 && prefs.getString(WARNED_DAY, "") != today) {
            notify(
                context, 7001, texts.optString("warnTitle"),
                texts.optString("warnBody").replace("{left}", left.toString()), texts,
            )
            prefs.edit().putString(WARNED_DAY, today).apply()
        }
        if (snap.optBoolean("over") && left <= 0 &&
            now - prefs.getLong(OVER_NOTIFIED_AT, 0) >= 60 * 60 * 1000
        ) {
            notify(
                context, 7002, texts.optString("overTitle"),
                if (snap.optString("day") == today) {
                    texts.optString("overBody")
                } else {
                    texts.optString("overBodyNewDay")
                },
                texts,
            )
            prefs.edit().putLong(OVER_NOTIFIED_AT, now).apply()
        }
    }

    private fun notify(context: Context, id: Int, title: String, body: String, texts: JSONObject) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL, texts.optString("channel"), NotificationManager.IMPORTANCE_DEFAULT,
                ),
            )
        }
        val open = PendingIntent.getActivity(
            context,
            id,
            Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }
        val notification = builder
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setContentIntent(open)
            .setAutoCancel(true)
            .build()
        // Without the notification permission this simply shows nothing.
        try {
            manager.notify(id, notification)
        } catch (_: SecurityException) {
        }
    }

    private fun dayKey(c: Calendar) = "%04d-%02d-%02d".format(
        c.get(Calendar.YEAR), c.get(Calendar.MONTH) + 1, c.get(Calendar.DAY_OF_MONTH),
    )

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
