import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:phyra/app.dart';

void main() {
  testWidgets('App boots to the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PhyraApp()));
    await tester.pump(); 

    expect(find.text('PHYRA'), findsWidgets);
    expect(find.text('TRANSMIT'), findsOneWidget);
    expect(find.text('RECEIVE'), findsOneWidget);
  });
}
