package com.mysticcat.journal

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home screen widget provider for 몽이.
 *
 * Reads garden progress data (saved from Flutter via HomeWidget.saveWidgetData)
 * and renders it into a small RemoteViews layout showing 몽이's growth status.
 *
 * Data keys pushed from Dart side (see garden_provider.dart):
 *  - garden_progress_percent (Int, 0-100)
 *  - garden_stage (Int)
 *  - garden_streak (Int)
 */
class GardenWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.garden_widget_layout)

            val progressPercent = widgetData.getInt("garden_progress_percent", 0)
                .coerceIn(0, 100)
            val stage = widgetData.getInt("garden_stage", 1)
            val streak = widgetData.getInt("garden_streak", 0)

            views.setProgressBar(R.id.widget_progress_bar, 100, progressPercent, false)
            views.setTextViewText(
                R.id.widget_progress_text,
                "정원 성장 $progressPercent% · ${stage}단계"
            )

            val statusText = if (streak > 0) {
                "연속 $streak" + "일째 몽이를 만나고 있어요"
            } else {
                "몽이가 기다리고 있어요"
            }
            views.setTextViewText(R.id.widget_status, statusText)

            // Tap widget to open the app
            val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
