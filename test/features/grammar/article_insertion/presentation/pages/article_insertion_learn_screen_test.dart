import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/grammar/article_insertion/presentation/pages/article_insertion_learn_screen.dart';

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

  group('ArticleInsertionLearnScreen', () {
    testWidgets(
      'renders Sound Radar, sentence display, rule explanation, and advances to next card',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(
            const ArticleInsertionLearnScreen(level: 1),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(ArticleInsertionLearnScreen), findsOneWidget);
        expect(find.text('Sound Radar'), findsOneWidget);
        expect(find.text('NATURAL SPEECH FLOW'), findsOneWidget);
        expect(find.text('HOW THE ARTICLE FLOWS'), findsOneWidget);
        expect(find.text('NATIVE SPEAKER TIP'), findsOneWidget);
        expect(find.textContaining('NEXT ARTICLE CARD'), findsOneWidget);

        // Tap NEXT ARTICLE CARD
        final nextFinder = find.textContaining('NEXT ARTICLE CARD');
        await tester.ensureVisible(nextFinder);
        await tester.tap(nextFinder);
        await tester.pumpAndSettle();

        expect(find.textContaining('Concept 2 of'), findsOneWidget);
      },
    );
  });
}
