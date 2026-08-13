import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets(
    'TraceLocked app starts',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const TraceLockedApp(),
      );

      expect(
        find.text('TraceLocked'),
        findsWidgets,
      );
    },
  );
}