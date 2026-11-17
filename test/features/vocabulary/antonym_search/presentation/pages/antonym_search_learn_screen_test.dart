import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/vocabulary/antonym_search/presentation/pages/antonym_search_learn_screen.dart';

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

  group('AntonymSearchLearnScreen', () {
    testWidgets(
        'renders contrast explorer header, polar words, and opposition cards',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AntonymSearchLearnScreen(level: 1),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AntonymSearchLearnScreen), findsOneWidget);
      expect(find.text('HERE'), findsWidgets);
      expect(find.text('THERE'), findsWidgets);
      expect(find.text('The Fundamental Opposition'), findsOneWidget);
      expect(find.text('CONTRASTING CONTEXTS'), findsOneWidget);
      expect(find.text('COMMON BEGINNER PITFALL'), findsOneWidget);
      expect(find.text('Next Opposite Pair ➔'), findsOneWidget);

      // Tap next pair
      await tester.tap(find.text('Next Opposite Pair ➔'));
      await tester.pumpAndSettle();

      // Pair 2 (Give ↔ Take)
      expect(find.text('GIVE'), findsWidgets);
      expect(find.text('TAKE'), findsWidgets);
    });
  });
}
