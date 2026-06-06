import 'package:flutter_test/flutter_test.dart';
import 'package:mistake_book_app/app.dart';

void main() {
  testWidgets('App renders mistake list', (WidgetTester tester) async {
    await tester.pumpWidget(const MistakeBookApp());
    expect(find.text('错题本'), findsOneWidget);
  });
}
