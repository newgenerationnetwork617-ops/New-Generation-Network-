import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:new_generation_network/main.dart';

void main() {
  setUpAll(() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );
  });

  testWidgets('N.G.N. home page loads', (WidgetTester tester) async {
    await tester.pumpWidget(const NewGenerationNetworkApp());

    expect(find.text('NEW GENERATION NETWORK'), findsOneWidget);
    expect(
      find.text('Raising a righteous generation for Christ.'),
      findsOneWidget,
    );
    expect(find.text('Daily Bible Verse'), findsOneWidget);
  });
}
