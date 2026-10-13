import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/daily_challenges/word_mixer/domain/models/word_mixer_puzzle.dart';
import 'package:vowl/features/daily_challenges/word_mixer/presentation/widgets/word_mixer_completed_view.dart';
import 'package:vowl/features/daily_challenges/word_mixer/presentation/widgets/word_mixer_hint_card.dart';
import 'package:vowl/features/daily_challenges/word_mixer/presentation/widgets/word_mixer_info_card.dart';
import 'package:vowl/features/daily_challenges/word_mixer/presentation/widgets/word_mixer_top_bar.dart';

class MockTtsService extends Mock implements TtsService {}

class MockHapticService extends Mock implements HapticService {}

void main() {
  late MockTtsService mockTtsService;
  late MockHapticService mockHapticService;
  late WordMixerPuzzle samplePuzzle;

  setUp(() {
    mockTtsService = MockTtsService();
    mockHapticService = MockHapticService();

    when(() => mockTtsService.speak(any())).thenAnswer((_) async {});
    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});

    samplePuzzle = WordMixerPuzzle.fromMap({
      'id': 1,
      'word': 'OCTOPUS',
      'hint':
          'A marine cephalopod having eight fleshy arms provided with suction cups.',
    });
  });

  Widget wrapWithScreenUtil(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('WordMixerTopBar Tests', () {
    testWidgets('renders title and streak badge when streak > 0', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool backTapped = false;

      await tester.pumpWidget(
        wrapWithScreenUtil(
          WordMixerTopBar(
            onBackPressed: () => backTapped = true,
            streak: 7,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Word Mixer'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);

      final backButton = find.byIcon(Icons.arrow_back_rounded);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pump();

      expect(backTapped, isTrue);
    });

    testWidgets('renders practice mode title when isPracticeMode is true', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrapWithScreenUtil(
          WordMixerTopBar(
            onBackPressed: () {},
            streak: 5,
            isPracticeMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Word Mixer Practice'), findsOneWidget);
      expect(find.text('Unlimited Practice'), findsOneWidget);
    });
  });

  group('WordMixerInfoCard Tests', () {
    testWidgets('renders difficulty, length, and title properly without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568)); // Small screen test
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrapWithScreenUtil(
          WordMixerInfoCard(
            puzzle: samplePuzzle,
            primaryColor: IllustrationColors.richPurple,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Daily Challenge'), findsOneWidget);
      expect(find.text('HARD'), findsOneWidget); // 7 letters is Hard
      expect(find.text('7 letters'), findsOneWidget);
    });
  });

  group('WordMixerHintCard Tests', () {
    testWidgets('starts collapsed, expands on tap, and plays TTS', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final isExpanded = ValueNotifier<bool>(false);

      await tester.pumpWidget(
        wrapWithScreenUtil(
          WordMixerHintCard(
            puzzle: samplePuzzle,
            isExpanded: isExpanded,
            primaryColor: IllustrationColors.richPurple,
            hapticService: mockHapticService,
            ttsService: mockTtsService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tap to reveal definition clue'), findsOneWidget);

      // Tap header to expand
      await tester.tap(find.text('Tap to reveal definition clue'));
      await tester.pumpAndSettle();

      expect(isExpanded.value, isTrue);
      expect(find.text('Hint & Definition'), findsOneWidget);
      expect(
        find.textContaining('A marine cephalopod having eight fleshy arms'),
        findsOneWidget,
      );
      expect(find.text('Starts with: O'), findsOneWidget);

      verify(() => mockHapticService.light()).called(1);

      // Tap Listen button
      final listenBtn = find.text('Listen');
      expect(listenBtn, findsOneWidget);
      await tester.tap(listenBtn);
      await tester.pump();

      verify(() => mockTtsService.speak(any())).called(1);
    });
  });

  group('WordMixerCompletedView Tests', () {
    testWidgets('renders victory state, solved word, definition review, and practice button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool practiceTapped = false;
      bool goBackTapped = false;

      await tester.pumpWidget(
        wrapWithScreenUtil(
          WordMixerCompletedView(
            puzzle: samplePuzzle,
            streak: 4,
            onGoBack: () => goBackTapped = true,
            onPracticeMore: () => practiceTapped = true,
            primaryColor: IllustrationColors.richPurple,
            hapticService: mockHapticService,
            ttsService: mockTtsService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Challenge Complete!'), findsOneWidget);
      expect(find.text('OCTOPUS'), findsOneWidget);
      expect(
        find.textContaining('A marine cephalopod having eight fleshy arms'),
        findsOneWidget,
      );
      expect(find.text('4 Day Streak'), findsOneWidget);

      // Tap speaker button to pronounce word
      final speakerBtn = find.byIcon(Icons.volume_up_rounded);
      expect(speakerBtn, findsOneWidget);
      await tester.tap(speakerBtn);
      await tester.pump();

      verify(() => mockTtsService.speak('OCTOPUS')).called(1);

      // Tap Practice Another Word button
      final practiceBtn = find.text('Practice Another Word');
      expect(practiceBtn, findsOneWidget);
      await tester.ensureVisible(practiceBtn);
      await tester.pumpAndSettle();
      await tester.tap(practiceBtn);
      await tester.pump();

      expect(practiceTapped, isTrue);

      // Tap Back to Home button
      final returnBtn = find.text('Back to Home');
      expect(returnBtn, findsOneWidget);
      await tester.ensureVisible(returnBtn);
      await tester.pumpAndSettle();
      await tester.tap(returnBtn);
      await tester.pump();

      expect(goBackTapped, isTrue);
    });

    testWidgets('renders practice complete title and description when isPracticeMode is true', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrapWithScreenUtil(
          WordMixerCompletedView(
            puzzle: samplePuzzle,
            streak: 0,
            onGoBack: () {},
            onPracticeMore: () {},
            isPracticeMode: true,
            hapticService: mockHapticService,
            ttsService: mockTtsService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Practice Complete!'), findsOneWidget);
      expect(find.text('Great job! Keep practicing to build your vocabulary.'), findsOneWidget);
    });
  });
}
