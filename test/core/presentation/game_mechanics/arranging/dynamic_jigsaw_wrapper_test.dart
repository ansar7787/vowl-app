import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/presentation/game_mechanics/arranging/dynamic_jigsaw_wrapper.dart';

void main() {
  testWidgets('DynamicJigsawWrapper renders expected text split into words', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DynamicJigsawWrapper(
            expectedText: 'Hello world',
            primaryColor: Colors.blue,
            onConfirmed: () {},
            onSkipped: () {},
          ),
        ),
      ),
    );

    // Give animations time to settle
    await tester.pumpAndSettle();

    // Verify words are present in the available tiles area
    expect(find.text('hello'), findsOneWidget);
    expect(find.text('world'), findsOneWidget);
  });
}
