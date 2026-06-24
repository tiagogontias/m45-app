import 'package:flutter_test/flutter_test.dart';
import 'package:m45_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const M45App());
    expect(find.text('M45'), findsOneWidget);
  });
}
