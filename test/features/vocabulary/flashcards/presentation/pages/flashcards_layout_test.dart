import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_card_layout.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_game_body.dart';

class MockHapticService extends Mock implements HapticService {}

class MockTtsService extends Mock implements TtsService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHapticService mockHapticService;
  late MockTtsService mockTtsService;

  const testQuest = VocabularyQuest(
    id: 'VOC_FLASHCARDS_L1_Q1',
    type: QuestType.vocabulary,
    subtype: GameSubtype.flashcards,
    word: 'EXTRAORDINARY',
    correctAnswer:
        'Very unusual, remarkable, or exceptional beyond normal bounds.',
    definition:
        'Very unusual, remarkable, or exceptional beyond normal bounds.',
    contextSentence:
        'She made an extraordinary discovery in the laboratory that changed science forever.',
    topicEmoji: '🌟',
    instruction: 'CHOOSE THE CORRECT MEANING',
    hint: 'Far beyond what is ordinary or common.',
    explanation: 'Used to describe things that are remarkable or amazing.',
    difficulty: 1,
  );

  setUp(() {
    VowlMotion.lowAnimationModeOverride.value = true;
    mockHapticService = MockHapticService();
    mockTtsService = MockTtsService();

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockTtsService.speak(any())).thenAnswer((_) async {});

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<TtsService>()) {
      di.sl.unregister<TtsService>();
    }
    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<TtsService>()) {
      di.sl.unregister<TtsService>();
    }
  });

  Widget buildLayoutTestWidget({
    required Size screenSize,
    required Widget child,
    double textScaleFactor = 1.0,
  }) {
    return MediaQuery(
      data: MediaQueryData(
        size: screenSize,
        textScaler: TextScaler.linear(textScaleFactor),
      ),
      child: ScreenUtilInit(
        designSize: screenSize,
        builder: (context, _) => MaterialApp(home: Scaffold(body: child)),
      ),
    );
  }

  group('FlashcardCardLayout Math & Responsiveness', () {
    testWidgets(
      'computes valid card dimensions for compact screens (320x568)',
      (tester) async {
        await tester.pumpWidget(
          buildLayoutTestWidget(
            screenSize: const Size(320, 568),
            child: Builder(
              builder: (context) {
                final layout = FlashcardCardLayout.compute(
                  const BoxConstraints(maxWidth: 320, maxHeight: 568),
                );
                expect(layout.cardWidth, lessThanOrEqualTo(320));
                expect(layout.cardHeight, greaterThanOrEqualTo(200));
                expect(layout.horizontalPadding, greaterThan(0));
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      },
    );

    testWidgets(
      'computes valid card dimensions for standard phones (390x844)',
      (tester) async {
        await tester.pumpWidget(
          buildLayoutTestWidget(
            screenSize: const Size(390, 844),
            child: Builder(
              builder: (context) {
                final layout = FlashcardCardLayout.compute(
                  const BoxConstraints(maxWidth: 390, maxHeight: 844),
                );
                expect(layout.cardWidth, lessThanOrEqualTo(390));
                expect(layout.cardHeight, inInclusiveRange(200.0, 480.0));
                expect(layout.horizontalPadding, greaterThan(0));
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      },
    );

    testWidgets('computes valid card dimensions for tablets (768x1024)', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildLayoutTestWidget(
          screenSize: const Size(768, 1024),
          child: Builder(
            builder: (context) {
              final layout = FlashcardCardLayout.compute(
                const BoxConstraints(maxWidth: 768, maxHeight: 1024),
              );
              expect(layout.cardWidth, lessThanOrEqualTo(440.0));
              expect(layout.horizontalPadding, greaterThan(0));
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });

  group('FlashcardGameBody Layout & No Overflow Tests', () {
    testWidgets('renders without overflow on small phone (320x568)', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));

      final isFlippedNotifier = ValueNotifier<bool>(false);
      final dragOffset = ValueNotifier<Offset>(Offset.zero);
      final dragAngle = ValueNotifier<double>(0.0);
      final dragProgress = ValueNotifier<double>(0.0);
      final comboStreak = ValueNotifier<int>(0);

      await tester.pumpWidget(
        buildLayoutTestWidget(
          screenSize: const Size(320, 568),
          child: FlashcardGameBody(
            quest: testQuest,
            primaryColor: Colors.indigo,
            isDark: false,
            isFlipped: isFlippedNotifier,
            isAnswered: false,
            isRetrying: false,
            isHintActive: false,
            hideActions: false,
            dragOffset: dragOffset,
            dragAngle: dragAngle,
            dragProgress: dragProgress,
            comboStreak: comboStreak,
            onHorizontalDragUpdate: (_) {},
            onHorizontalDragEnd: (details, threshold) {},
            onCardTap: () {},
            onSubmitAnswer: (_) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byType(FlashcardGameBody), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets(
      'renders without overflow with large accessibility text scale (1.5x)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));

        final isFlippedNotifier = ValueNotifier<bool>(true);
        final dragOffset = ValueNotifier<Offset>(Offset.zero);
        final dragAngle = ValueNotifier<double>(0.0);
        final dragProgress = ValueNotifier<double>(0.0);
        final comboStreak = ValueNotifier<int>(3);

        await tester.pumpWidget(
          buildLayoutTestWidget(
            screenSize: const Size(390, 844),
            textScaleFactor: 1.5,
            child: FlashcardGameBody(
              quest: testQuest,
              primaryColor: Colors.indigo,
              isDark: true,
              isFlipped: isFlippedNotifier,
              isAnswered: false,
              isRetrying: false,
              isHintActive: false,
              hideActions: false,
              dragOffset: dragOffset,
              dragAngle: dragAngle,
              dragProgress: dragProgress,
              comboStreak: comboStreak,
              onHorizontalDragUpdate: (_) {},
              onHorizontalDragEnd: (details, threshold) {},
              onCardTap: () {},
              onSubmitAnswer: (_) {},
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(find.byType(FlashcardGameBody), findsOneWidget);

        await tester.binding.setSurfaceSize(null);
      },
    );
  });
}
