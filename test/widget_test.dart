import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_mblf_events_mobile/main.dart';

void main() {
  testWidgets('MBLF Events inicia corretamente', (WidgetTester tester) async {
    await tester.pumpWidget(const MblfEventsApp());

    expect(find.text('MBLF Events'), findsOneWidget);
  });
}