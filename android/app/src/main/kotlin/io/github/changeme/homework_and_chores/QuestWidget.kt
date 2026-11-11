package io.github.changeme.homework_and_chores

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.BitmapFactory
import android.view.View
import android.widget.RemoteViews
import java.io.File
import java.util.Calendar

/**
 * A home screen widget showing a picture the app drew (see
 * home_widget_sync.dart): `<style>-<day|night>-<yyyy-mm-dd>.png` in the
 * app's files. The widget picks today's picture in the current mode, so it
 * stays right after midnight without the app. Three styles, so people
 * choose the look by placing the one they like.
 */
abstract class QuestWidget(private val style: String) : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) manager.updateAppWidget(id, render(context, style))
    }

    companion object {
        private val STYLES = mapOf(
            "board" to QuestBoardWidget::class.java,
            "path" to QuestPathWidget::class.java,
            "next" to NextQuestWidget::class.java,
        )

        /** The styles placed on the home screen, and "list" for the list. */
        fun placed(context: Context): List<String> {
            val manager = AppWidgetManager.getInstance(context)
            val pictures = STYLES.filter { (_, type) ->
                manager.getAppWidgetIds(ComponentName(context, type)).isNotEmpty()
            }.keys.toList()
            return if (QuestListWidget.ids(context).isEmpty()) pictures else pictures + "list"
        }

        /** Redraws every placed widget from the pictures. */
        fun refresh(context: Context) {
            QuestListWidget.refresh(context)
            val manager = AppWidgetManager.getInstance(context)
            for ((style, type) in STYLES) {
                for (id in manager.getAppWidgetIds(ComponentName(context, type))) {
                    manager.updateAppWidget(id, render(context, style))
                }
            }
        }

        private fun today(): String {
            val c = Calendar.getInstance()
            return "%04d-%02d-%02d".format(
                c.get(Calendar.YEAR), c.get(Calendar.MONTH) + 1, c.get(Calendar.DAY_OF_MONTH),
            )
        }

        private fun render(context: Context, style: String): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.quest_widget)
            val open = PendingIntent.getActivity(
                context, 0,
                Intent(context, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_root, open)
            val night = context.resources.configuration.uiMode and
                Configuration.UI_MODE_NIGHT_MASK == Configuration.UI_MODE_NIGHT_YES
            val mode = if (night) "night" else "day"
            val file = File(context.filesDir, "widget/$style-$mode-${today()}.png")
            val bitmap = if (file.exists()) BitmapFactory.decodeFile(file.path) else null
            if (bitmap == null) {
                // Not drawn yet (or the app wasn't opened for a week).
                views.setViewVisibility(R.id.widget_picture, View.GONE)
                views.setViewVisibility(R.id.widget_setup, View.VISIBLE)
            } else {
                views.setImageViewBitmap(R.id.widget_picture, bitmap)
                views.setViewVisibility(R.id.widget_picture, View.VISIBLE)
                views.setViewVisibility(R.id.widget_setup, View.GONE)
            }
            return views
        }
    }
}

/** Quest board: icon tiles in rows, with badges. */
class QuestBoardWidget : QuestWidget("board")

/** Board-game path: tiles joined by arrows. */
class QuestPathWidget : QuestWidget("path")

/** The next quest large, the following ones small. */
class NextQuestWidget : QuestWidget("next")
