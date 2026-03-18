import 'package:flutter_test/flutter_test.dart';
import 'package:transferd/main.dart';

void main() {
  testWidgets('TransferD app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TransferDApp());
    expect(find.text('Xin chào!'), findsOneWidget);
    expect(find.text('Hoang Phu Ngoc Tuong'), findsOneWidget);
  });
}
