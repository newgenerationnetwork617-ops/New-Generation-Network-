#!/usr/bin/env python3
"""Generate native Android home-screen widgets for Holy Word [NGN]."""
from pathlib import Path
import re

manifest = Path("android/app/src/main/AndroidManifest.xml")
main_activity = next(Path("android/app/src/main/kotlin").rglob("MainActivity.kt"), None)
if main_activity is None or not manifest.exists():
    raise SystemExit("Generated Android MainActivity or manifest is missing")

match = re.search(r"^package\s+([A-Za-z0-9_.]+)", main_activity.read_text(), re.M)
if not match:
    raise SystemExit("Could not determine Android application package")
package = match.group(1)

kotlin_dir = Path("android/app/src/main/kotlin") / Path(*package.split("."))
kotlin_dir.mkdir(parents=True, exist_ok=True)
(kotlin_dir / "NgnHomeWidgetProviders.kt").write_text(r'''package __PACKAGE__

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

private fun launchHolyWord(context: Context, widgetId: Int): PendingIntent? {
    val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        ?: return null
    launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
    return PendingIntent.getActivity(
        context,
        widgetId,
        launchIntent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )
}

class DailyScriptureWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val data = HomeWidgetPlugin.getData(context)
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.ngn_daily_scripture_widget)
            views.setTextViewText(R.id.ngn_widget_word, data.getString("ngn_scripture_word", "Scripture for Today"))
            views.setTextViewText(R.id.ngn_widget_reference, data.getString("ngn_scripture_reference", "Open Holy Word"))
            views.setTextViewText(R.id.ngn_widget_verse, data.getString("ngn_scripture_text", "Your daily Scripture will appear here."))
            launchHolyWord(context, widgetId)?.let { views.setOnClickPendingIntent(R.id.ngn_widget_root, it) }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

class DailyDevotionWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val data = HomeWidgetPlugin.getData(context)
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.ngn_daily_devotion_widget)
            views.setTextViewText(R.id.ngn_devotion_title, data.getString("ngn_devotion_title", "Daily Devotion"))
            views.setTextViewText(R.id.ngn_devotion_reference, data.getString("ngn_devotion_reference", ""))
            views.setTextViewText(R.id.ngn_devotion_preview, data.getString("ngn_devotion_preview", "Open Holy Word to read today's devotion."))
            launchHolyWord(context, widgetId)?.let { views.setOnClickPendingIntent(R.id.ngn_devotion_root, it) }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
'''.replace("__PACKAGE__", package))

res = Path("android/app/src/main/res")
(res / "layout").mkdir(parents=True, exist_ok=True)
(res / "xml").mkdir(parents=True, exist_ok=True)
(res / "values").mkdir(parents=True, exist_ok=True)

(res / "layout/ngn_daily_scripture_widget.xml").write_text('''<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/ngn_widget_root"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:padding="16dp"
    android:background="@drawable/ngn_widget_background">
    <TextView
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="HOLY WORD • DAILY SCRIPTURE"
        android:textColor="#8A6410"
        android:textStyle="bold"
        android:textSize="11sp" />
    <TextView
        android:id="@+id/ngn_widget_word"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="7dp"
        android:text="Scripture for Today"
        android:textColor="#171717"
        android:textSize="18sp"
        android:textStyle="bold"
        android:maxLines="1"
        android:ellipsize="end" />
    <TextView
        android:id="@+id/ngn_widget_reference"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="3dp"
        android:textColor="#8A6410"
        android:textSize="12sp"
        android:textStyle="bold" />
    <TextView
        android:id="@+id/ngn_widget_verse"
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1"
        android:layout_marginTop="8dp"
        android:text="Your daily Scripture will appear here."
        android:textColor="#292929"
        android:textSize="14sp"
        android:lineSpacingExtra="2dp"
        android:maxLines="5"
        android:ellipsize="end" />
    <TextView
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="8dp"
        android:text="Tap to open Holy Word"
        android:textColor="#8A6410"
        android:textSize="11sp"
        android:textStyle="bold" />
</LinearLayout>
''')

(res / "layout/ngn_daily_devotion_widget.xml").write_text('''<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/ngn_devotion_root"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:padding="16dp"
    android:background="@drawable/ngn_widget_background">
    <TextView
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="HOLY WORD • DAILY DEVOTION"
        android:textColor="#8A6410"
        android:textStyle="bold"
        android:textSize="11sp" />
    <TextView
        android:id="@+id/ngn_devotion_title"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="7dp"
        android:text="Daily Devotion"
        android:textColor="#171717"
        android:textSize="17sp"
        android:textStyle="bold"
        android:maxLines="2"
        android:ellipsize="end" />
    <TextView
        android:id="@+id/ngn_devotion_reference"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="3dp"
        android:textColor="#8A6410"
        android:textSize="12sp"
        android:textStyle="bold" />
    <TextView
        android:id="@+id/ngn_devotion_preview"
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1"
        android:layout_marginTop="8dp"
        android:text="Open Holy Word to read today's devotion."
        android:textColor="#292929"
        android:textSize="13sp"
        android:lineSpacingExtra="2dp"
        android:maxLines="6"
        android:ellipsize="end" />
    <TextView
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="8dp"
        android:text="Tap to read the full devotion in the app"
        android:textColor="#8A6410"
        android:textSize="11sp"
        android:textStyle="bold" />
</LinearLayout>
''')

(res / "drawable").mkdir(parents=True, exist_ok=True)
(res / "drawable/ngn_widget_background.xml").write_text('''<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <solid android:color="#FFFFFEFA" />
    <corners android:radius="18dp" />
    <stroke android:width="1dp" android:color="#FFE0AD25" />
</shape>
''')

(res / "xml/ngn_daily_scripture_widget_info.xml").write_text('''<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="180dp"
    android:minHeight="150dp"
    android:targetCellWidth="3"
    android:targetCellHeight="2"
    android:updatePeriodMillis="0"
    android:initialLayout="@layout/ngn_daily_scripture_widget"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen" />
''')
(res / "xml/ngn_daily_devotion_widget_info.xml").write_text('''<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="180dp"
    android:minHeight="190dp"
    android:targetCellWidth="3"
    android:targetCellHeight="3"
    android:updatePeriodMillis="0"
    android:initialLayout="@layout/ngn_daily_devotion_widget"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen" />
''')

manifest_text = manifest.read_text()
receivers = f'''
        <receiver android:name="{package}.DailyScriptureWidgetProvider" android:exported="true" android:label="Daily Scripture">
            <intent-filter><action android:name="android.appwidget.action.APPWIDGET_UPDATE" /></intent-filter>
            <meta-data android:name="android.appwidget.provider" android:resource="@xml/ngn_daily_scripture_widget_info" />
        </receiver>
        <receiver android:name="{package}.DailyDevotionWidgetProvider" android:exported="true" android:label="Daily Devotion">
            <intent-filter><action android:name="android.appwidget.action.APPWIDGET_UPDATE" /></intent-filter>
            <meta-data android:name="android.appwidget.provider" android:resource="@xml/ngn_daily_devotion_widget_info" />
        </receiver>
'''
if "DailyScriptureWidgetProvider" not in manifest_text:
    manifest_text = manifest_text.replace("</application>", receivers + "\n    </application>")
manifest.write_text(manifest_text)
print(f"Configured Daily Scripture and Daily Devotion widgets for {package}")
