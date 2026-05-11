import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

void main() {
  Widget createWidgetForTesting({required Widget child}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('ScaleButton Widget Tests', () {
    testWidgets('should call onTap when pressed', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(createWidgetForTesting(
        child: ScaleButton(
          onTap: () => tapped = true,
          child: const Text('Tap Me'),
        ),
      ));

      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('should prevent double taps with debounce logic', (WidgetTester tester) async {
      int tapCount = 0;
      await tester.pumpWidget(createWidgetForTesting(
        child: ScaleButton(
          onTap: () => tapCount++,
          child: const Text('Debounce'),
        ),
      ));

      // First tap
      await tester.tap(find.text('Debounce'));
      await tester.pumpAndSettle();
      expect(tapCount, equals(1));

      // Second tap immediately - should be debounced
      await tester.tap(find.text('Debounce'));
      await tester.pumpAndSettle();
      expect(tapCount, equals(1));

      // Advance clock by 1 second using virtual time
      await tester.pump(const Duration(seconds: 1));

      // Third tap - should trigger
      await tester.tap(find.text('Debounce'));
      await tester.pumpAndSettle();
      expect(tapCount, equals(2));
    });
  });
}
