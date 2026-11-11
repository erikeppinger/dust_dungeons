package io.github.changeme.homework_and_chores

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.util.Calendar

/**
 * The home screen widget with every quest, as a list that scrolls. The app
 * draws its parts (see home_widget_sync.dart) into the app's files:
 * `list-<day|night>-head.png`, a picture per row
 * (`list-<day|night>-row-<n>.png`) and, per day, which rows to show
 * (`list-<yyyy-mm-dd>.json`). Like the picture widgets it picks today's
 * file, so it stays right after midnight without the app.
 *
 * Tapping a quest that is open ticks it off; tapping it again takes that
 * back. The widget only remembers the tick ([Ticks]) and shows the row as
 * done: the app books it, with points and all, when it is next opened.
 */
class QuestListWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        update(context, manager, ids)
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_TICK) return super.onReceive(context, intent)
        val chore = intent.getIntExtra(EXTRA_CHORE, -1)
        val profile = day(context)?.optInt("profile", -1) ?: -1
        // A row that can't be ticked, or files from before ticking existed.
        if (chore < 0 || profile < 0) return
        val now = Calendar.getInstance()
        val minutes = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        val from = intent.getIntExtra(EXTRA_FROM, -1)
        val to = intent.getIntExtra(EXTRA_TO, -1)
        // On time: due today and, if it has a time of day, within it.
        val onTime = intent.getBooleanExtra(EXTRA_DUE, false) &&
            (from < 0 || (minutes >= from && minutes <= to))
        Ticks.toggle(context, chore, profile, today(), onTime)
        @Suppress("DEPRECATION")
        AppWidgetManager.getInstance(context)
            .notifyAppWidgetViewDataChanged(ids(context), R.id.widget_list)
    }

    companion object {
        const val ACTION_TICK = "io.github.changeme.homework_and_chores.TICK"
        const val EXTRA_CHORE = "chore"
        const val EXTRA_DUE = "due"
        const val EXTRA_FROM = "from"
        const val EXTRA_TO = "to"

        fun ids(context: Context): IntArray =
            AppWidgetManager.getInstance(context)
                .getAppWidgetIds(ComponentName(context, QuestListWidget::class.java))

        /** Shows the files the app drew last. */
        fun refresh(context: Context) {
            update(context, AppWidgetManager.getInstance(context), ids(context))
        }

        fun mode(context: Context): String {
            val night = context.resources.configuration.uiMode and
                Configuration.UI_MODE_NIGHT_MASK == Configuration.UI_MODE_NIGHT_YES
            return if (night) "night" else "day"
        }

        fun today(): String {
            val c = Calendar.getInstance()
            return "%04d-%02d-%02d".format(
                c.get(Calendar.YEAR), c.get(Calendar.MONTH) + 1, c.get(Calendar.DAY_OF_MONTH),
            )
        }

        fun folder(context: Context) = File(context.filesDir, "widget")

        /** Today's rows, or null if the app hasn't drawn them. */
        fun day(context: Context): JSONObject? {
            val file = File(folder(context), "list-${today()}.json")
            return try {
                if (file.exists()) JSONObject(file.readText()) else null
            } catch (e: Exception) {
                null
            }
        }

        private fun update(context: Context, manager: AppWidgetManager, ids: IntArray) {
            if (ids.isEmpty()) return
            val mode = mode(context)
            val head = File(folder(context), "list-$mode-head.png")
            val headPicture = if (head.exists()) BitmapFactory.decodeFile(head.path) else null
            val day = day(context)
            // Tapping the heading or the empty text opens the app.
            val open = PendingIntent.getActivity(
                context, 1,
                Intent(context, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            // Tapping a row ticks it: the row fills in which quest. Mutable,
            // as Android requires for that; it only ever reaches this class.
            val mutable =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0
            val tick = PendingIntent.getBroadcast(
                context, 2,
                Intent(context, QuestListWidget::class.java).setAction(ACTION_TICK),
                PendingIntent.FLAG_UPDATE_CURRENT or mutable,
            )
            for (id in ids) {
                val views = RemoteViews(context.packageName, R.layout.quest_list_widget)
                views.setOnClickPendingIntent(R.id.widget_list_head, open)
                views.setOnClickPendingIntent(R.id.widget_list_empty, open)
                if (headPicture == null || day == null) {
                    // Not drawn yet (or the app wasn't opened for a week).
                    views.setViewVisibility(R.id.widget_list_head, View.GONE)
                    views.setViewVisibility(R.id.widget_list, View.GONE)
                    views.setViewVisibility(R.id.widget_list_empty, View.VISIBLE)
                    views.setTextViewText(
                        R.id.widget_list_empty, context.getString(R.string.widget_setup),
                    )
                } else {
                    views.setImageViewBitmap(R.id.widget_list_head, headPicture)
                    views.setViewVisibility(R.id.widget_list_head, View.VISIBLE)
                    views.setViewVisibility(R.id.widget_list, View.VISIBLE)
                    views.setTextViewText(R.id.widget_list_empty, day.optString("empty"))
                    // Each widget needs its own intent (the data makes it so),
                    // or Android reuses one list for all of them.
                    val rows = Intent(context, QuestListService::class.java)
                        .putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id)
                    rows.data = Uri.parse(rows.toUri(Intent.URI_INTENT_SCHEME))
                    @Suppress("DEPRECATION")
                    views.setRemoteAdapter(R.id.widget_list, rows)
                    views.setEmptyView(R.id.widget_list, R.id.widget_list_empty)
                    views.setPendingIntentTemplate(R.id.widget_list, tick)
                }
                manager.updateAppWidget(id, views)
            }
            // The rows may have changed, or the day, or day and night.
            @Suppress("DEPRECATION")
            manager.notifyAppWidgetViewDataChanged(ids, R.id.widget_list)
        }
    }
}

/** Gives the list its rows. */
class QuestListService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory = Rows(applicationContext)

    private class Rows(private val context: Context) : RemoteViewsFactory {
        /** Today's rows, as the app wrote them. */
        private var rows = listOf<JSONObject>()

        /** The quests ticked off in the widget today. */
        private var ticked = setOf<Int>()
        private var mode = "day"

        override fun onCreate() {}

        override fun onDataSetChanged() {
            mode = QuestListWidget.mode(context)
            val day = QuestListWidget.day(context)
            val list = day?.optJSONArray("rows")
            rows = if (list == null) listOf() else (0 until list.length()).map(list::getJSONObject)
            ticked = Ticks.tickedOn(context, QuestListWidget.today(), day?.optInt("profile", -1) ?: -1)
        }

        override fun onDestroy() {}

        override fun getCount() = rows.size

        override fun getViewAt(position: Int): RemoteViews? {
            val row = rows.getOrNull(position) ?: return null
            val views = RemoteViews(context.packageName, R.layout.quest_list_row)
            val canTick = row.optBoolean("tick") && row.has("chore")
            val done = canTick && row.getInt("chore") in ticked
            val name = "list-$mode-row-${row.getInt("row")}${if (done) "-done" else ""}.png"
            val file = File(QuestListWidget.folder(context), name)
            val picture: Bitmap? = if (file.exists()) BitmapFactory.decodeFile(file.path) else null
            if (picture != null) views.setImageViewBitmap(R.id.widget_row_picture, picture)
            views.setContentDescription(
                R.id.widget_row_picture,
                row.optString(if (done) "doneLabel" else "label"),
            )
            // Fills the list's template with the quest: a tap ticks it, or
            // takes the tick back. Rows that can't be ticked fill in
            // nothing, and their tap does nothing.
            val tap = Intent()
            if (canTick) {
                tap.putExtra(QuestListWidget.EXTRA_CHORE, row.getInt("chore"))
                    .putExtra(QuestListWidget.EXTRA_DUE, row.optBoolean("due"))
                    .putExtra(QuestListWidget.EXTRA_FROM, row.optInt("from", -1))
                    .putExtra(QuestListWidget.EXTRA_TO, row.optInt("to", -1))
            }
            views.setOnClickFillInIntent(R.id.widget_row, tap)
            return views
        }

        override fun getLoadingView(): RemoteViews? = null

        override fun getViewTypeCount() = 1

        override fun getItemId(position: Int) = position.toLong()

        override fun hasStableIds() = false
    }
}

/**
 * The quests ticked off in the list widget that the app hasn't booked yet,
 * in `widget_ticks.json` in the app's files (not in the widget's folder,
 * which the app clears): `[{"chore": id, "profile": id, "day":
 * "yyyy-mm-dd", "at": epoch milliseconds, "onTime": true}]`.
 */
object Ticks {
    private fun file(context: Context) = File(context.filesDir, "widget_ticks.json")

    private fun read(context: Context): MutableList<JSONObject> {
        val file = file(context)
        return try {
            if (!file.exists()) return mutableListOf()
            val list = JSONArray(file.readText())
            (0 until list.length()).map(list::getJSONObject).toMutableList()
        } catch (e: Exception) {
            mutableListOf()
        }
    }

    private fun write(context: Context, ticks: List<JSONObject>) {
        val file = file(context)
        if (ticks.isEmpty()) {
            file.delete()
            return
        }
        // Written whole, then renamed: never half a file.
        val tmp = File(file.path + ".tmp")
        tmp.writeText(JSONArray(ticks).toString())
        tmp.renameTo(file)
    }

    /** Ticks the quest for [day], or takes that tick back. */
    @Synchronized
    fun toggle(context: Context, chore: Int, profile: Int, day: String, onTime: Boolean) {
        val ticks = read(context)
        val had = ticks.removeAll {
            it.optInt("chore") == chore && it.optInt("profile") == profile &&
                it.optString("day") == day
        }
        if (!had) {
            // The time also tells ticks apart: never two in one millisecond.
            var at = System.currentTimeMillis()
            while (ticks.any { it.optLong("at") == at }) at++
            ticks.add(
                JSONObject().put("chore", chore).put("profile", profile).put("day", day)
                    .put("at", at).put("onTime", onTime),
            )
        }
        write(context, ticks)
    }

    /** The quests of [profile] ticked on [day]. */
    @Synchronized
    fun tickedOn(context: Context, day: String, profile: Int): Set<Int> =
        read(context)
            .filter { it.optString("day") == day && it.optInt("profile") == profile }
            .map { it.optInt("chore") }
            .toSet()

    /** Every tick, for the app to book. */
    @Synchronized
    fun all(context: Context): List<Map<String, Any>> = read(context).map {
        mapOf(
            "chore" to it.optInt("chore"),
            "profile" to it.optInt("profile"),
            "at" to it.optLong("at"),
            "onTime" to it.optBoolean("onTime"),
        )
    }

    /** Forgets the ticks made at these times: the app has booked them. */
    @Synchronized
    fun drop(context: Context, at: List<Long>) {
        val ticks = read(context)
        if (ticks.removeAll { it.optLong("at") in at }) write(context, ticks)
    }
}
