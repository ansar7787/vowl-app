import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/presentation/phases/phase_progress_indicator.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MaterialApp(
        home: Scaffold(
          body: Center(child: child),
        ),
      ),
    );
  }

  group('PhaseProgressIndicator', () {
    testWidgets('renders SizedBox.shrink when completedPhases is empty and hideIfEmpty is true', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const PhaseProgressIndicator(completedPhases: {}, hideIfEmpty: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Row), findsNothing);
    });

    testWidgets('renders 3 dots when completedPhases has entries', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const PhaseProgressIndicator(completedPhases: {'learn'}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Row), findsOneWidget);
      // Finding 3 containers inside Row
      final row = tester.widget<Row>(find.byType(Row));
      expect(row.children.length, equals(3));
    });
  });
}
