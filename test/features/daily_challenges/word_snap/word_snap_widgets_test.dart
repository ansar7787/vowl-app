import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/daily_challenges/word_snap/domain/models/word_snap_puzzle.dart';
import 'package:vowl/features/daily_challenges/word_snap/presentation/widgets/word_snap_completed_view.dart';
import 'package:vowl/features/daily_challenges/word_snap/presentation/widgets/word_snap_hint_card.dart';
import 'package:vowl/features/daily_challenges/word_snap/presentation/widgets/word_snap_target_card.dart';
import 'package:vowl/features/daily_challenges/word_snap/presentation/widgets/word_snap_top_bar.dart';

class MockSoundService extends Mock implements SoundService {}

class MockHapticService extends Mock implements HapticService {}

void main() {
  late MockSoundService mockSoundService;
  late MockHapticService mockHapticService;
  late WordSnapPuzzle samplePuzzle;

  setUp(() {
    mockSoundService = MockSoundService();
    mockHapticService = MockHapticService();

    when(() => mockSoundService.playTts(any(), speed: any(named: 'speed')))
        .thenAnswer((_) async {});
    when(() => mockSoundService.playHint()).thenAnswer((_) async {});
    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});

    samplePuzzle = WordSnapPuzzle.fromMap({
      'id': 1,
      'word': 'ZEBRINE',
      'question': 'Pertaining to, or resembling, the zebra.',
    });
  });

  Widget wrapWithScreenUtil(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, _) => MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('WordSnapTargetCard Tests', () {
    testWidgets('renders target word, letter count, and triggers TTS on tap',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrapWithScreenUtil(
          WordSnapTargetCard(
            puzzle: samplePuzzle,
            primaryColor: IllustrationColors.vibrantPink,
            soundService: mockSoundService,
            hapticService: mockHapticService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ZEBRINE'), findsOneWidget);
      expect(find.text('7 letters'), findsOneWidget);
      expect(find.text('6 words to assemble'), findsOneWidget);

      final speakerFinder = find.byIcon(Icons.volume_up_rounded);
      expect(speakerFinder, findsOneWidget);

      await tester.tap(speakerFinder);
      await tester.pump();

      verify(() => mockSoundService.playTts('zebrine')).called(1);
      verify(() => mockHapticService.selection()).called(1);
    });
  });

  group('WordSnapHintCard Tests', () {
    testWidgets('starts collapsed, expands on tap, and plays hint sound',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final isExpandedNotifier = ValueNotifier<bool>(false);

      await tester.pumpWidget(
        wrapWithScreenUtil(
          WordSnapHintCard(
            puzzle: samplePuzzle,
            isExpandedNotifier: isExpandedNotifier,
            primaryColor: IllustrationColors.vibrantPink,
            soundService: mockSoundService,
            hapticService: mockHapticService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final headerFinder = find.text('Need help? Tap for a hint');
      expect(headerFinder, findsOneWidget);

      await tester.tap(headerFinder);
      await tester.pumpAndSettle();

      expect(isExpandedNotifier.value, isTrue);
      expect(find.text('Hint & Clue'), findsOneWidget);
      expect(find.textContaining('Starts with "Pertaining"'), findsOneWidget);
      expect(
        find.textContaining('Pertaining to, or resembling, the zebra'),
        findsOneWidget,
      );

      verify(() => mockSoundService.playHint()).called(1);
      verify(() => mockHapticService.light()).called(1);
    });
  });

  group('WordSnapCompletedView Tests', () {
    testWidgets('renders completed state, solved word, and handles practice mode',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool practiceTapped = false;

      await tester.pumpWidget(
        wrapWithScreenUtil(
          WordSnapCompletedView(
            puzzle: samplePuzzle,
            streak: 5,
            primaryColor: IllustrationColors.vibrantPink,
            soundService: mockSoundService,
            hapticService: mockHapticService,
            onPracticeAgain: () => practiceTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Challenge Complete!'), findsOneWidget);
      expect(find.text('ZEBRINE'), findsOneWidget);
      expect(find.text('5 Day Streak'), findsOneWidget);

      final practiceFinder = find.text('Practice Another Word');
      expect(practiceFinder, findsOneWidget);
      await tester.ensureVisible(practiceFinder);
      await tester.pumpAndSettle();

      await tester.tap(practiceFinder);
      await tester.pump();

      expect(practiceTapped, isTrue);
    });

    testWidgets('renders practice complete title and description when isPracticeMode is true',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrapWithScreenUtil(
          WordSnapCompletedView(
            puzzle: samplePuzzle,
            streak: 0,
            primaryColor: IllustrationColors.vibrantPink,
            soundService: mockSoundService,
            hapticService: mockHapticService,
            onPracticeAgain: () {},
            isPracticeMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Practice Complete!'), findsOneWidget);
      expect(find.text('Well done! Keep practicing to strengthen your vocabulary.'), findsOneWidget);
    });
  });

  group('WordSnapTopBar Tests', () {
    testWidgets('renders title and streak badge when streak > 0',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrapWithScreenUtil(
          const WordSnapTopBar(streak: 12),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Word Snap'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    });
  });
}
