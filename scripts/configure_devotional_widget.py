#!/usr/bin/env python3
"""Generate the Android devotional home-screen widget after flutter create."""
from pathlib import Path
import re

android = Path("android/app/src/main")
manifest = android / "AndroidManifest.xml"
if not manifest.exists():
    raise SystemExit("AndroidManifest.xml was not generated")

activity_files = list((android / "kotlin").rglob("MainActivity.kt")) if (android / "kotlin").exists() else []
if not activity_files:
    activity_files = list((android / "java").rglob("MainActivity.java")) if (android / "java").exists() else []
if not activity_files:
    raise SystemExit("Could not find generated MainActivity to determine Android package")

activity_text = activity_files[0].read_text()
match = re.search(r"^package\s+([A-Za-z0-9_.]+)", activity_text, re.MULTILINE)
if not match:
    raise SystemExit("Could not determine Android package from MainActivity")
package_name = match.group(1)
source_dir = activity_files[0].parent
(source_dir / "DevotionalWidgetProvider.kt").write_text(f'''package {package_name}

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.net.Uri
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin\nimport es.antonborri.home_widget.HomeWidgetLaunchIntent

class DevotionalWidgetProvider : AppWidgetProvider() {{
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {{
        val data = HomeWidgetPlugin.getData(context)
        val style = data.getString("ngn_devotional_widget_style", "classic") ?: "classic"
        val palette = when (style) {{
            "midnight" -> intArrayOf(Color.rgb(9, 20, 38), Color.WHITE, Color.rgb(190, 205, 225), Color.rgb(255, 201, 74))
            "gold" -> intArrayOf(Color.rgb(255, 247, 224), Color.rgb(34, 37, 43), Color.rgb(80, 83, 90), Color.rgb(7, 59, 140))
            else -> intArrayOf(Color.rgb(7, 59, 140), Color.WHITE, Color.rgb(224, 235, 255), Color.rgb(255, 201, 74))
        }}
        val pendingIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("ngn://devotional")
        )
        ids.forEach {{ id ->
            val views = RemoteViews(context.packageName, R.layout.ngn_devotional_widget).apply {{
                setInt(R.id.widget_container, "setBackgroundColor", palette[0])
                setTextColor(R.id.widget_brand, palette[3])
                setTextColor(R.id.widget_title, palette[1])
                setTextColor(R.id.widget_reference, palette[3])
                setTextColor(R.id.widget_message, palette[2])
                setTextViewText(R.id.widget_title, data.getString("ngn_devotional_title", "Today's Devotional"))
                setTextViewText(R.id.widget_reference, data.getString("ngn_devotional_reference", "A daily moment in God's Word"))
                setTextViewText(R.id.widget_message, data.getString("ngn_devotional_message", "Open Holy Word [NGN] to read today's devotional."))
                setTextViewText(R.id.widget_date, data.getString("ngn_devotional_date", ""))
                if (pendingIntent != null) setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }}
            manager.updateAppWidget(id, views)
        }}
    }}
}}
''')

layout_dir = android / "res/layout"
xml_dir = android / "res/xml"
layout_dir.mkdir(parents=True, exist_ok=True)
xml_dir.mkdir(parents=True, exist_ok=True)
(layout_dir / "ngn_devotional_widget.xml").write_text('''<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/widget_container"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:padding="16dp"
    android:background="#073B8C">
    <TextView
        android:id="@+id/widget_brand"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="HOLY WORD [NGN]"
        android:textColor="#FFC94A"
        android:textSize="11sp"
        android:textStyle="bold"
        android:letterSpacing="0.08" />
    <TextView
        android:id="@+id/widget_title"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="7dp"
        android:text="Today's Devotional"
        android:textColor="#FFFFFF"
        android:textSize="18sp"
        android:textStyle="bold"
        android:maxLines="2"
        android:ellipsize="end" />
    <TextView
        android:id="@+id/widget_reference"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="4dp"
        android:textColor="#FFC94A"
        android:textSize="12sp"
        android:textStyle="bold"
        android:maxLines="1"
        android:ellipsize="end" />
    <TextView
        android:id="@+id/widget_message"
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1"
        android:layout_marginTop="8dp"
        android:textColor="#E0EBFF"
        android:textSize="13sp"
        android:lineSpacingExtra="2dp"
        android:maxLines="4"
        android:ellipsize="end" />
    <TextView
        android:id="@+id/widget_date"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="8dp"
        android:textColor="#B8C9E5"
        android:textSize="10sp" />
</LinearLayout>
''')
(xml_dir / "ngn_devotional_widget_info.xml").write_text('''<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="250dp"
    android:minHeight="150dp"
    android:updatePeriodMillis="1800000"
    android:initialLayout="@layout/ngn_devotional_widget"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen" />
''')

manifest_text = manifest.read_text()
receiver = f'''    <receiver
        android:name="{package_name}.DevotionalWidgetProvider"
        android:exported="true"
        android:label="NGN Daily Devotional">
        <intent-filter>
            <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
        </intent-filter>
        <meta-data
            android:name="android.appwidget.provider"
            android:resource="@xml/ngn_devotional_widget_info" />
    </receiver>
'''
if 'es.antonborri.home_widget.action.LAUNCH' not in manifest_text:
    launch_filter = """            <intent-filter>
                <action android:name="es.antonborri.home_widget.action.LAUNCH" />
                <category android:name="android.intent.category.DEFAULT" />
            </intent-filter>
"""
    manifest_text = manifest_text.replace("</activity>", launch_filter + "        </activity>", 1)
if "DevotionalWidgetProvider" not in manifest_text:
    if "</application>" not in manifest_text:
        raise SystemExit("Could not find application closing tag in AndroidManifest.xml")
    manifest_text = manifest_text.replace("</application>", receiver + "    </application>", 1)
    manifest.write_text(manifest_text)

print(f"Generated NGN devotional widget for {package_name}")
