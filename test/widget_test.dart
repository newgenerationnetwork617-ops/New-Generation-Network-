import 'package:flutter_test/flutter_test.dart';
import 'package:new_generation_network/main.dart';

void main() {
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
