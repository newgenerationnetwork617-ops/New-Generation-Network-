import 'package:home_widget/home_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'content_repository.dart';

/// Publishes the current offline daily Scripture and devotional preview to
/// Android home-screen widgets. The full devotional remains available in-app.
class HomeScreenWidgetService {
  HomeScreenWidgetService._();

  static const _scriptureWidget = 'DailyScriptureWidgetProvider';
  static const _devotionWidget = 'DailyDevotionWidgetProvider';

  static Future<void> refresh() async {
    final repository = ContentRepository(Supabase.instance.client);
    final today = DateTime.now();

    // Both sources are bundled assets, so the widgets can refresh offline.
    final scripture = await repository.wordForDate(today);
    final devotion = await repository.devotionalForDate(today);

    final verseText = (scripture?['verse_text'] ?? '').toString().trim();
    final reference = (scripture?['reference'] ?? '').toString().trim();
    final word = (scripture?['word'] ?? '').toString().trim();

    final devotionTitle = (devotion?['title'] ?? 'Daily Devotion').toString().trim();
    final devotionReference =
        (devotion?['bible_reference'] ?? '').toString().trim();
    final devotionText = (devotion?['message'] ?? '').toString().trim();

    await Future.wait([
      HomeWidget.saveWidgetData<String>(
        'ngn_scripture_word',
        word.isEmpty ? 'Scripture for Today' : word,
      ),
      HomeWidget.saveWidgetData<String>(
        'ngn_scripture_reference',
        reference.isEmpty ? 'Open Holy Word to read today\'s Scripture' : reference,
      ),
      HomeWidget.saveWidgetData<String>(
        'ngn_scripture_text',
        verseText.isEmpty ? 'Your daily Scripture will appear here.' : verseText,
      ),
      HomeWidget.saveWidgetData<String>(
        'ngn_devotion_title',
        devotionTitle,
      ),
      HomeWidget.saveWidgetData<String>(
        'ngn_devotion_reference',
        devotionReference,
      ),
      HomeWidget.saveWidgetData<String>(
        'ngn_devotion_preview',
        devotionText.isEmpty
            ? 'Open Holy Word to read today\'s full devotion.'
            : devotionText,
      ),
      HomeWidget.saveWidgetData<String>(
        'ngn_widget_updated',
        today.toIso8601String(),
      ),
    ]);

    await Future.wait([
      HomeWidget.updateWidget(androidName: _scriptureWidget),
      HomeWidget.updateWidget(androidName: _devotionWidget),
    ]);
  }
}
