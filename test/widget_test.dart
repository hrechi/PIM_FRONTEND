import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_pim/main.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FieldlyApp());
    await tester.pump();
    expect(find.text('Fieldly'), findsOneWidget);
  });
}
