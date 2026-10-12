import 'package:flutter_test/flutter_test.dart';
import 'package:ipo_tracker/main.dart';

void main() {
  testWidgets('IPO Tracker loads splash screen and navigates', (WidgetTester tester) async {
    await tester.pumpWidget(const IpoTrackerApp());
    expect(find.text('IPO Tracker'), findsWidgets);
    expect(find.text('Manage your IPO applications easily'), findsOneWidget);

    // Let splash screen timer complete and pump navigation
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();
  });
}
