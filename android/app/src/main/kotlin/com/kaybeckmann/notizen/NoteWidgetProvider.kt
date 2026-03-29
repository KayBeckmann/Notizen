package com.kaybeckmann.notizen

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class NoteWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.note_widget).apply {
                // Daten aus den SharedPreferences holen (von Flutter gesetzt)
                val title = widgetData.getString("widget_title", "Keine Notiz")
                val content = widgetData.getString("widget_content", "Tippe hier, um eine Notiz zu erstellen.")

                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_content, content)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
