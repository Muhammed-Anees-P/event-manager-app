import 'package:flutter_test/flutter_test.dart';
import 'package:event_management_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HayaEventManagementApp());
    expect(find.text('Haya'), findsWidgets);
  });
}
