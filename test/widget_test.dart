import 'package:flutter_test/flutter_test.dart';

import 'package:google_dialer/main.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const GoogleDialerApp());
    await tester.pump();

    expect(find.byType(GoogleDialerApp), findsOneWidget);
  });
}
