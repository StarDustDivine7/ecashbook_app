import 'package:flutter_test/flutter_test.dart';
import 'package:ecashbook_app/main.dart';  // contains EcashbookApp

void main() {
  testWidgets('App builds without crashing', (tester) async {
    await tester.pumpWidget(const EcashbookApp());

    // Simple sanity check: the login button is visible.
    expect(find.text('SIGN IN'), findsOneWidget);
  });
}
