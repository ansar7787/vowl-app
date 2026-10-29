import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/tts_service.dart';

class MockLocaleService extends Mock implements LocaleService {}
class MockTtsService extends Mock implements TtsService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLocaleService mockLocale;
  late MockTtsService mockTts;

  setUp(() {
    mockLocale = MockLocaleService();
    mockTts = MockTtsService();

    when(() => mockLocale.currentLocale).thenReturn(const Locale('en'));
    when(() => mockLocale.tr(
      any(),
      args: any(named: 'args'),
      fallback: any(named: 'fallback'),
    )).thenAnswer((invocation) {
      final fallback = invocation.namedArguments[#fallback] as String?;
      return fallback ?? invocation.positionalArguments[0] as String;
    });

    when(() => mockTts.stop()).thenAnswer((_) async {});
    when(() => mockTts.isSpeaking).thenReturn(false);
    when(() => mockTts.isSpeakingNotifier).thenReturn(ValueNotifier<bool>(false));

    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    di.sl.registerLazySingleton<LocaleService>(() => mockLocale);

    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    di.sl.registerLazySingleton<TtsService>(() => mockTts);

    initLocaleServiceReference(mockLocale);
  });

  tearDown(() {
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
  });

  Widget buildTestHarness({
    required Widget child,
    double bottomPadding = 0.0,
    double viewPaddingBottom = 0.0,
    Size viewport = const Size(390, 844),
  }) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MediaQuery(
        data: MediaQueryData(
          size: viewport,
          padding: EdgeInsets.only(bottom: bottomPadding),
          viewPadding: EdgeInsets.only(bottom: viewPaddingBottom),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  group('GameFeedbackCard Navigation Bar & Inset Resilience', () {
    testWidgets('3-button navigation bar (48dp inset) allocates dynamic safe bottom padding', (tester) async {
      var continued = false;

      await tester.pumpWidget(
        buildTestHarness(
          viewPaddingBottom: 48.0,
          child: GameFeedbackCard(
            isCorrect: true,
            isFinalFailure: false,
            livesRemaining: 3,
            onContinue: () => continued = true,
            isDark: false,
            primaryColor: Colors.blue,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final containerFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints != null &&
            widget.padding is EdgeInsets,
      );
      expect(containerFinder, findsOneWidget);

      final container = tester.widget<Container>(containerFinder);
      final padding = container.padding as EdgeInsets;

      // Bottom padding must be at least 48.0 + 16.0 (>= 64.0dp)
      expect(padding.bottom, greaterThanOrEqualTo(64.0));

      final continueButton = find.text('CONTINUE');
      expect(continueButton, findsOneWidget);

      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(continued, isTrue);
    });

    testWidgets('gesture navigation bar (20dp inset) scales bottom padding appropriately', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          viewPaddingBottom: 20.0,
          child: GameFeedbackCard(
            isCorrect: false,
            isFinalFailure: false,
            livesRemaining: 2,
            onContinue: () {},
            isDark: true,
            primaryColor: Colors.amber,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final containerFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints != null &&
            widget.padding is EdgeInsets,
      );
      final container = tester.widget<Container>(containerFinder);
      final padding = container.padding as EdgeInsets;

      // Bottom padding must be at least 20.0 + 16.0 (>= 36.0dp)
      expect(padding.bottom, greaterThanOrEqualTo(36.0));
      expect(find.text('TRY AGAIN'), findsOneWidget);
    });

    testWidgets('zero inset device uses minimum safe fallback padding', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          viewPaddingBottom: 0.0,
          bottomPadding: 0.0,
          child: GameFeedbackCard(
            isCorrect: true,
            isFinalFailure: false,
            livesRemaining: 1,
            onContinue: () {},
            isDark: false,
            primaryColor: Colors.teal,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final containerFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints != null &&
            widget.padding is EdgeInsets,
      );
      final container = tester.widget<Container>(containerFinder);
      final padding = container.padding as EdgeInsets;

      expect(padding.bottom, greaterThanOrEqualTo(24.0));
    });

    testWidgets('continue button is pinned while educational rules scroll above it', (tester) async {
      var continued = false;

      await tester.pumpWidget(
        buildTestHarness(
          viewPaddingBottom: 48.0,
          viewport: const Size(360, 640),
          child: GameFeedbackCard(
            isCorrect: false,
            isFinalFailure: true,
            livesRemaining: 0,
            onContinue: () => continued = true,
            isDark: true,
            primaryColor: Colors.purple,
            correctAnswer: 'The correct answer is present perfect continuous.',
            explanation: 'We use the present perfect continuous for actions that began in the past and continue into the present.',
            ruleTitle: 'GRAMMAR RULE',
            ruleContent: 'Subject + have/has been + present participle (-ing).',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Action button is SEE RESULTS (since livesRemaining <= 0)
      final actionButton = find.text('SEE RESULTS');
      expect(actionButton, findsOneWidget);

      // Verify that SingleChildScrollView exists for educational info
      expect(find.byType(SingleChildScrollView), findsWidgets);

      // Tap action button directly without needing to scroll to bottom
      await tester.tap(actionButton);
      await tester.pumpAndSettle();

      expect(continued, isTrue);
    });
  });
}
