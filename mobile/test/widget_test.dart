import 'package:flutter_test/flutter_test.dart';
import 'package:stakk_savings/main.dart';

void main() {
  testWidgets('App loads and shows auth or dashboard', (tester) async {
    await tester.pumpWidget(const StakkApp());

    // App should show either Login/Register or Dashboard
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Should show Stakk title
    expect(find.text('Stakk'), findsWidgets);
  });
}
