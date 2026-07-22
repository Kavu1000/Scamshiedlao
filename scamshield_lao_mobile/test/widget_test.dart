import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scamshield_lao_mobile/main.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ScamShieldApp()),
    );
    // Verify the app title is present somewhere in the initial render
    expect(find.text('ScamShield Lao'), findsWidgets);
  });
}
