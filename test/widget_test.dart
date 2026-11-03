import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:new_generation_network/main.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );
  });

  testWidgets('N.G.N. splash and home load', (WidgetTester tester) async {
    await tester.pumpWidget(const NewGenerationNetworkApp());

    expect(find.text('NEW GENERATION NETWORK'), findsOneWidget);
    expect(
      find.text('Raising a Righteous Generation for Christ'),
      findsOneWidget,
    );

    // The app contains repeating animations, so pump a fixed duration rather
    // than waiting for every animation to settle indefinitely.
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('NEW GENERATION NETWORK'), findsOneWidget);
    expect(find.text('WORD FOR TODAY'), findsOneWidget);
    expect(find.text('Teachings'), findsOneWidget);
    expect(find.text('YOUR DAILY DEVOTIONAL'), findsOneWidget);
    expect(find.text('Announcements'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Bible'), findsOneWidget);
    expect(find.text('Media'), findsOneWidget);
    expect(find.text('Events'), findsWidgets);
    expect(find.text('Community'), findsWidgets);
  });
}
