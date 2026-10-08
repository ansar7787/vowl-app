
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  testWidgets("ReorderableDragStartListener throws outside ReorderableList", (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              ReorderableDragStartListener(
                index: 0,
                child: Container(width: 50, height: 50, color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNotNull);
  });
}

