import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/vocabulary/academic_word/presentation/pages/academic_word_learn_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MaterialApp(
        home: child,
      ),
    );
  }

  group('AcademicWordLearnScreen', () {
    testWidgets(
        'renders academic field, definition, collocations, register contrast, and advances',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AcademicWordLearnScreen(level: 1),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AcademicWordLearnScreen), findsOneWidget);
      expect(find.text('ACADEMIC DEFINITION'), findsOneWidget);
      expect(find.text('STANDARD COLLOCATIONS'), findsOneWidget);
      expect(find.text('REGISTER CONTRAST'), findsOneWidget);
      expect(find.text('SCHOLARLY DISCOURSE'), findsOneWidget);
      expect(find.textContaining('Next Academic Word'), findsOneWidget);

      // Scroll and advance to next academic word
      final nextFinder = find.textContaining('Next Academic Word');
      await tester.ensureVisible(nextFinder);
      await tester.tap(nextFinder);
      await tester.pumpAndSettle();

      expect(find.textContaining('TERM 2 OF'), findsOneWidget);
    });
  });
}
