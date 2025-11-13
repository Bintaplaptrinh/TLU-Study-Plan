package com.nekkochan.tlucalendar

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class TodayScheduleWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Update each widget instance
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        super.onReceive(context, intent)
        
        // Handle manual refresh
        if (intent?.action == "REFRESH_WIDGET") {
            context?.let {
                val appWidgetManager = AppWidgetManager.getInstance(it)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(
                    android.content.ComponentName(it, TodayScheduleWidgetProvider::class.java)
                )
                onUpdate(it, appWidgetManager, appWidgetIds)
            }
        }
    }

    companion object {
        internal fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            // Get widget data from shared preferences (set by Flutter)
            val widgetData = HomeWidgetPlugin.getData(context)
            
            val title = widgetData.getString("widget_title", "Lịch học hôm nay") ?: "Lịch học hôm nay"
            val date = widgetData.getString("widget_date", "") ?: ""
            val courseCount = widgetData.getInt("course_count", 0)
            val coursesText = widgetData.getString("courses_text", "Đang tải...") ?: "Đang tải..."

            // Create RemoteViews
            val views = RemoteViews(context.packageName, R.layout.today_schedule_widget)
            
            // Set data to views
            views.setTextViewText(R.id.widget_title, title)
            views.setTextViewText(R.id.widget_date, date)
            views.setTextViewText(R.id.course_count, courseCount.toString())
            views.setTextViewText(R.id.courses_text, coursesText)

            // Set click action to open app
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("from_widget", true)
            }
            val pendingIntent = android.app.PendingIntent.getActivity(
                context,
                0,
                intent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.courses_text, pendingIntent)

            // Update widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
