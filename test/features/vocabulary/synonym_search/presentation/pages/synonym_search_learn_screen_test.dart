import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/pages/synonym_search_learn_screen.dart';

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

  group('SynonymSearchLearnScreen', () {
    testWidgets('renders nuance explorer header, word pairs, and distinction cards', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const SynonymSearchLearnScreen(level: 1),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SynonymSearchLearnScreen), findsOneWidget);
      expect(find.text('Big'), findsWidgets);
      expect(find.text('Large'), findsWidgets);
      expect(find.text('The Native Distinction'), findsOneWidget);
      expect(find.text('Real-World Contexts'), findsOneWidget);
      expect(find.text('Common Native Trap'), findsOneWidget);
      expect(find.text('Next Synonym Pair ➔'), findsOneWidget);

      // Tap next pair
      await tester.tap(find.text('Next Synonym Pair ➔'));
      await tester.pumpAndSettle();

      // Pair 2 (Happy ↔ Glad)
      expect(find.text('Happy'), findsWidgets);
      expect(find.text('Glad'), findsWidgets);
    });
  });
}
