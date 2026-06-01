import 'package:carpcraft_app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows CarpCraft splash', (tester) async {
    await tester.pumpWidget(const CarpCraftApp());

    expect(find.text('CarpCraft Intelligence'), findsOneWidget);
  });
}
