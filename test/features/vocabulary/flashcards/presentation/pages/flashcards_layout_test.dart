import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/controllers/flashcard_controller.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_learn_view.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_practice_chunk_weaver.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_speed_slam_view.dart';

class MockCallbackFunction extends Mock {
  void call();
  void callString(String str);
  void callInt(int val);
}

class MockHapticService extends Mock implements HapticService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockCb = MockCallbackFunction();

  final testQuest = PhasedQuest(
    id: 'VOC_FC_TEST_Q1',
    level: 1,
    word: 'AUTHENTIC',
    pronunciation: '/ɔːˈθen.tɪk/',
    definition:
        'Genuine, real, and true to original traditions rather than an imitation.',
    example:
        'The chef insisted on using only authentic Italian ingredients for the pasta.',
    nativeTip:
        'Native speakers often describe honest, grounded people as authentic.',
    commonMistake: "Don't confuse authentic with original.",
    familyWords: const ['authenticity', 'authenticate', 'authentically'],
    rawExtra: const {
      'syllables': ['au', 'then', 'tic'],
      'stressedSyllableIndex': 1,
      'contextDomain': 'Dining & Hospitality',
      'collocations': [
        'authentic cuisine',
        'authentic leadership',
        'authentic smile',
      ],
      'collocationOptions': [
        'authentic cuisine',
        'authentic weather',
        'authentic price',
      ],
      'correctCollocationIndex': 0,
    },
  );

  const testVocabQuest = VocabularyQuest(
    id: 'VOC_FC_TEST_Q1',
    word: 'AUTHENTIC',
    definition: 'Genuine, real, and true to original traditions.',
    contextSentence:
        'The chef insisted on using only authentic Italian ingredients.',
    collocations: ['authentic cuisine'],
    wrongCollocations: ['authentic weather'],
    options: ['authentic', 'authoritarian', 'automatic'],
    difficulty: 1,
    instruction: 'Choose the natural phrase before the timer runs out!',
  );

  Widget buildResponsiveHarness({
    required Widget child,
    required Size screenSize,
  }) {
    return ScreenUtilInit(
      designSize: screenSize,
      builder: (context, _) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  group('Flashcard Responsive Layout Tests (Zero Overflow Guarantee)', () {
    const screenSizes = [
      Size(320, 568), // Small phone (iPhone SE 1st gen)
      Size(375, 812), // Standard phone (iPhone X/11/12 mini)
      Size(430, 932), // Large phone (iPhone 14 Pro Max / modern Android)
    ];

    for (final size in screenSizes) {
      testWidgets(
        'FlashcardLearnView renders cleanly without overflow on ${size.width}x${size.height}',
        (tester) async {
          await tester.pumpWidget(
            buildResponsiveHarness(
              screenSize: size,
              child: FlashcardLearnView(
                quest: testQuest,
                isFlipped: false,
                isSpeaking: false,
                isDark: false,
                onFlip: () => mockCb(),
                onSpeakSyllable: (s) => mockCb.callString(s),
                onSpeakFullWord: () => mockCb(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('AUTHENTIC'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'FlashcardLearnView BackFace renders cleanly without overflow on ${size.width}x${size.height}',
        (tester) async {
          await tester.pumpWidget(
            buildResponsiveHarness(
              screenSize: size,
              child: FlashcardLearnView(
                quest: testQuest,
                isFlipped: true,
                isSpeaking: false,
                isDark: false,
                onFlip: () => mockCb(),
                onSpeakSyllable: (s) => mockCb.callString(s),
                onSpeakFullWord: () => mockCb(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('AUTHENTIC'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'FlashcardPracticeChunkWeaver renders cleanly without overflow on ${size.width}x${size.height}',
        (tester) async {
          await tester.pumpWidget(
            buildResponsiveHarness(
              screenSize: size,
              child: FlashcardPracticeChunkWeaver(
                sentence: testQuest.example ?? '',
                targetWord: testQuest.word ?? '',
                availableChunks: const ['AU', 'THEN', 'TIC', 'TION', 'IC'],
                placedChunks: const ['AU'],
                hasCheckedAssembly: false,
                isAssemblyCorrect: false,
                showCollocationStage: false,
                hasCheckedCollocation: false,
                shakeTrigger: 0,
                isDark: false,
                onAddChunk: (c) => mockCb.callString(c),
                onRemoveChunk: (i) => mockCb.callInt(i),
                onCheckAssembly: () => mockCb(),
                onSelectCollocation: (i) => mockCb.callInt(i),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('COMPLETE THE CONTEXT SENTENCE'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'FlashcardSpeedSlamView renders cleanly without overflow on ${size.width}x${size.height}',
        (tester) async {
          final mockHaptic = MockHapticService();
          final controller = FlashcardMasteryController(
            hapticService: mockHaptic,
            onSubmitResult:
                ({required bool isCorrect, required bool speedBonus}) {},
          );

          await tester.pumpWidget(
            buildResponsiveHarness(
              screenSize: size,
              child: FlashcardSpeedSlamView(
                quest: testVocabQuest,
                controller: controller,
                isDark: false,
                onAdvanceToStage2: () {},
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('AUTHENTIC'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
