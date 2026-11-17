import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MaterialApp(
        home: child,
      ),
    );
  }

  group('PracticePhaseScaffold', () {
    testWidgets('renders title, progress, practice badge and triggers onComplete', (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        buildTestableWidget(
          PracticePhaseScaffold(
            title: 'Word Gym',
            gameType: 'flashcards',
            level: 1,
            currentExerciseIndex: 0,
            totalExercises: 3,
            onComplete: () => completed = true,
            child: const Text('Practice Question Body'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Word Gym'), findsOneWidget);
      expect(find.text('PRACTICE PHASE • LEVEL 1'), findsOneWidget);
      expect(find.text('Practice Question Body'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      final button = find.byType(ElevatedButton);
      expect(button, findsOneWidget);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(completed, isTrue);
    });
  });
}
