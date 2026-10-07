package com.szbnce.pettrack_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget: the latest camera still plus a one-line status.
 *
 * Everything visible is sent from Flutter (see HomeWidgetService), so the
 * texts arrive already localized — this class only paints them.
 */
class PetTrackHomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val title = widgetData.getString("title", null)
        val status = widgetData.getString("status", null)
        val battery = widgetData.getString("battery", null)
        val emptyHint = widgetData.getString("empty_hint", null)
        val imagePath = widgetData.getString("snapshot", null)
        val bitmap = imagePath?.let { path ->
            try {
                BitmapFactory.decodeFile(path)
            } catch (e: Exception) {
                null
            }
        }

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.pettrack_home_widget)
            if (bitmap != null) {
                views.setImageViewBitmap(R.id.widget_snapshot, bitmap)
                views.setViewVisibility(R.id.widget_empty_hint, View.GONE)
            } else {
                views.setImageViewResource(R.id.widget_snapshot, android.R.color.transparent)
                views.setViewVisibility(R.id.widget_empty_hint, View.VISIBLE)
                // Prefer the hint localized in the app; the resource is the
                // pre-first-launch fallback.
                views.setTextViewText(
                    R.id.widget_empty_hint,
                    emptyHint ?: context.getString(R.string.widget_empty_hint),
                )
            }
            views.setTextViewText(R.id.widget_title, title ?: context.getString(R.string.widget_name))
            views.setTextViewText(R.id.widget_status, status ?: "")
            views.setTextViewText(R.id.widget_battery, battery ?: "")
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
