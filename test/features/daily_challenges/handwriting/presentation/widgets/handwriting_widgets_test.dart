import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/features/daily_challenges/handwriting/domain/models/handwriting_puzzle.dart';
import 'package:vowl/features/daily_challenges/handwriting/presentation/widgets/handwriting_completed_view.dart';
import 'package:vowl/features/daily_challenges/handwriting/presentation/widgets/handwriting_top_bar.dart';

class MockHapticService extends Mock implements HapticService {}

void main() {
  late MockHapticService mockHapticService;
  late HandwritingPuzzle samplePuzzle;

  setUp(() {
    mockHapticService = MockHapticService();
    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});

    samplePuzzle = HandwritingPuzzle.fromMap({
      'id': 1,
      'target': 'A',
      'instruction': 'Trace uppercase letter A',
      'category': 'alphabet',
      'difficulty': 'easy',
      'funFact': 'The letter A is the first letter of the Latin alphabet.',
      'level': 1,
    });
  });

  Widget wrapWithScreenUtil(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, _) => MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: child),
      ),
    );
  }

  group('HandwritingTopBar Widget Tests', () {
    testWidgets('renders title and streak badge when streak > 0', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrapWithScreenUtil(const HandwritingTopBar(streak: 7)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Handwriting'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });

    testWidgets('renders practice mode badge when isPracticeMode is true', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrapWithScreenUtil(
          const HandwritingTopBar(streak: 0, isPracticeMode: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Handwriting'), findsOneWidget);
      expect(find.text('PRACTICE'), findsOneWidget);
    });

    testWidgets('invokes onBackPressed when back button is tapped', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool backTapped = false;
      await tester.pumpWidget(
        wrapWithScreenUtil(
          HandwritingTopBar(
            streak: 3,
            onBackPressed: () => backTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pump();

      expect(backTapped, isTrue);
    });
  });

  group('HandwritingCompletedView Widget Tests', () {
    testWidgets(
      'renders victory state, target letter, fun fact, and practice button',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        bool practiceTriggered = false;

        await tester.pumpWidget(
          wrapWithScreenUtil(
            HandwritingCompletedView(
              puzzle: samplePuzzle,
              streak: 4,
              primaryColor: AppColors.teal500,
              hapticService: mockHapticService,
              onPracticeAgain: () => practiceTriggered = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('A'), findsOneWidget);
        expect(
          find.text('The letter A is the first letter of the Latin alphabet.'),
          findsOneWidget,
        );

        final practiceButton = find.text('Practice Another Word');
        expect(practiceButton, findsOneWidget);
        await tester.ensureVisible(practiceButton);
        await tester.pumpAndSettle();

        await tester.tap(practiceButton);
        await tester.pump();

        expect(practiceTriggered, isTrue);
      },
    );

    testWidgets(
      'renders practice complete state when isPracticeMode is true',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          wrapWithScreenUtil(
            HandwritingCompletedView(
              puzzle: samplePuzzle,
              streak: 0,
              primaryColor: AppColors.teal500,
              hapticService: mockHapticService,
              onPracticeAgain: () {},
              isPracticeMode: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Practice Complete!'), findsOneWidget);
      },
    );
  });
}
