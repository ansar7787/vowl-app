import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MaterialApp(
        home: child,
      ),
    );
  }

  group('LearnPhaseScaffold', () {
    testWidgets('renders title, level, learn badge and responds to actions', (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        buildTestableWidget(
          LearnPhaseScaffold(
            title: 'Word Discovery',
            gameType: 'flashcards',
            level: 1,
            onComplete: () => completed = true,
            child: const Text('Educational Content Body'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Word Discovery'), findsOneWidget);
      expect(find.text('LEARN PHASE • LEVEL 1'), findsOneWidget);
      expect(find.text('Educational Content Body'), findsOneWidget);

      final button = find.byType(ElevatedButton);
      expect(button, findsOneWidget);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(completed, isTrue);
    });
  });
}
