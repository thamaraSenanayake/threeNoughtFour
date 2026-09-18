import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:three_note_four/main.dart';
import 'package:three_note_four/ui/screens/home_screen.dart';
import 'package:three_note_four/ui/screens/table_screen.dart';

void main() {
  testWidgets('304 Arena HomeScreen and Navigation test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ThreeNoteFourApp());
    await tester.pump();

    // Verify HomeScreen elements
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('304 ARENA'), findsOneWidget);
    expect(find.text('ENTER 304 ARENA'), findsOneWidget);

    // Enter custom name
    final nameField = find.byType(TextField);
    expect(nameField, findsOneWidget);
    await tester.enterText(nameField, 'Chamara');
    await tester.pump();

    // Tap Start Game button
    final startButton = find.text('ENTER 304 ARENA');
    await tester.tap(startButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify navigation to TableScreen
    expect(find.byType(TableScreen), findsOneWidget);
    expect(find.textContaining('Chamara (South)'), findsOneWidget);
  });
}
