import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'content_repository.dart';

/// Keeps the Android home-screen devotional widget in sync with the
/// devotional already bundled in the app. No network request is required.
class DevotionalWidgetService {
  DevotionalWidgetService._();
  static final DevotionalWidgetService instance = DevotionalWidgetService._();

  static const String styleKey = 'ngn_devotional_widget_style';
  static const Map<String, String> styles = {
    'classic': 'NGN Blue',
    'midnight': 'Midnight',
    'gold': 'Warm Gold',
  };

  Future<String> selectedStyle() async {
    final saved = await HomeWidget.getWidgetData<String>(styleKey);
    return styles.containsKey(saved) ? saved! : 'classic';
  }

  Future<void> setStyle(String style) async {
    final safeStyle = styles.containsKey(style) ? style : 'classic';
    await HomeWidget.saveWidgetData<String>(styleKey, safeStyle);
    await refreshToday();
  }

  Future<void> refreshToday() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final item = await ContentRepository(Supabase.instance.client)
          .devotionalForDate(DateTime.now());
      await HomeWidget.saveWidgetData<String>(
        'ngn_devotional_title',
        item?['title']?.toString().trim().isNotEmpty == true
            ? item!['title'].toString().trim()
            : 'Today\'s Devotional',
      );
      await HomeWidget.saveWidgetData<String>(
        'ngn_devotional_reference',
        item?['bible_reference']?.toString().trim() ?? '',
      );
      final message = item?['message']?.toString().replaceAll(RegExp(r'\\s+'), ' ').trim() ?? '';
      final excerpt = message.length > 210 ? '${message.substring(0, 207).trimRight()}…' : message;
      await HomeWidget.saveWidgetData<String>(
        'ngn_devotional_message',
        excerpt.isEmpty ? 'Open Holy Word [NGN] for today\'s reading.' : excerpt,
      );
      await HomeWidget.saveWidgetData<String>(
        'ngn_devotional_date',
        DateTime.now().toLocal().toString().substring(0, 10),
      );
      await HomeWidget.updateWidget(name: 'DevotionalWidgetProvider');
    } catch (error) {
      debugPrint('NGN devotional widget refresh failed: $error');
    }
  }
}
