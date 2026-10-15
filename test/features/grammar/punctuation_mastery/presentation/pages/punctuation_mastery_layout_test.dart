import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';
import 'package:vowl/core/presentation/widgets/game_briefing_layer.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/analytics_service.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/punctuation_mastery/presentation/pages/punctuation_mastery_screen.dart';
import 'package:vowl/features/grammar/punctuation_mastery/presentation/widgets/punctuation_mastery_instruction.dart';
import 'package:vowl/features/grammar/punctuation_mastery/presentation/widgets/punctuation_sticker_sheet.dart';

class MockGrammarBloc extends MockBloc<GrammarEvent, GrammarState>
    implements GrammarBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockEconomyBloc extends MockBloc<EconomyEvent, EconomyState>
    implements EconomyBloc {}

class MockHapticService extends Mock implements HapticService {}

class MockSoundService extends Mock implements SoundService {}

class MockTtsService extends Mock implements TtsService {}

class MockLocaleService extends Mock implements LocaleService {}

class MockAppLogger extends Mock implements AppLogger {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockAdService extends Mock implements AdService {}

class FakeGrammarEvent extends Fake implements GrammarEvent {}

class FakeGrammarState extends Fake implements GrammarState {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGrammarBloc mockGrammarBloc;
  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;
  late MockTtsService mockTtsService;
  late MockLocaleService mockLocaleService;
  late MockAppLogger mockLogger;
  late MockAnalyticsService mockAnalyticsService;
  late MockAdService mockAdService;

  setUpAll(() {
    registerFallbackValue(FakeGrammarEvent());
    registerFallbackValue(FakeGrammarState());
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const GrammarHintUsed());
    registerFallbackValue(const Duration(milliseconds: 50));
  });

  const testQuest1 = GrammarQuest(
    id: 'punc_l1_q1',
    instruction: 'APPLY HOLOGRAPHIC DECALS',
    difficulty: 1,
    subtype: GameSubtype.punctuationMastery,
    question: 'Hello world',
    sentence: 'Hello world',
    correctAnswer: 'Hello, world!',
    options: [],
    grammarRule: 'Comma and Exclamation',
    hint: 'Add a comma after Hello and an exclamation mark at the end.',
  );

  const testQuestNoRule = GrammarQuest(
    id: 'punc_l1_q2',
    instruction: 'PUNCTUATE THE SENTENCE',
    difficulty: 1,
    subtype: GameSubtype.punctuationMastery,
    question: 'How are you',
    sentence: 'How are you',
    correctAnswer: 'How are you?',
    options: [],
    hint: 'Add a question mark at the end.',
  );

  final testLoadedState = GrammarLoaded(
    quests: const [testQuest1, testQuestNoRule],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
    hintUsed: false,
    wrongCount: 0,
    isFinalFailure: false,
  );

  setUp(() async {
    mockGrammarBloc = MockGrammarBloc();
    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    mockTtsService = MockTtsService();
    mockLocaleService = MockLocaleService();
    mockLogger = MockAppLogger();
    mockAnalyticsService = MockAnalyticsService();
    mockAdService = MockAdService();

    VowlMotion.lowAnimationModeOverride.value = true;

    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_punctuationMastery': true,
    });

    when(
      () => mockLocaleService.tr(
        any(),
        fallback: any(named: 'fallback'),
        args: any(named: 'args'),
      ),
    ).thenAnswer(
      (inv) =>
          inv.namedArguments[#fallback] as String? ??
          inv.positionalArguments.first as String,
    );

    when(() => mockLocaleService.currentLocale).thenReturn(const Locale('en'));

    when(() => mockGrammarBloc.state).thenReturn(testLoadedState);
    when(
      () => mockGrammarBloc.stream,
    ).thenAnswer((_) => const Stream<GrammarState>.empty());

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user_id',
          email: 'test@vowl.app',
          displayName: 'Test Grammarian',
          hintCount: 3,
        ),
      ),
    );
    when(
      () => mockAuthBloc.stream,
    ).thenAnswer((_) => const Stream<AuthState>.empty());

    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(
      () => mockEconomyBloc.stream,
    ).thenAnswer((_) => const Stream<EconomyState>.empty());

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});

    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.playClick()).thenAnswer((_) async {});
    when(() => mockSoundService.playHint()).thenAnswer((_) async {});
    when(() => mockSoundService.stopAudio()).thenAnswer((_) async {});

    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(
      () => mockTtsService.speak(
        any(),
        rate: any(named: 'rate'),
        locale: any(named: 'locale'),
        pauseMarkers: any(named: 'pauseMarkers'),
        forcedPreset: any(named: 'forcedPreset'),
        isKids: any(named: 'isKids'),
      ),
    ).thenAnswer((_) async {});

    await di.sl.reset();

    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<AppLogger>(mockLogger);
    di.sl.registerSingleton<AnalyticsService>(mockAnalyticsService);
    di.sl.registerSingleton<AdService>(mockAdService);
  });

  tearDown(() async {
    await di.sl.reset();
  });

  Future<void> pumpPunctuationMastery(
    WidgetTester tester, {
    GrammarState? state,
    int level = 2,
    Size size = const Size(390, 844),
    ThemeMode themeMode = ThemeMode.dark,
  }) async {
    if (state != null) {
      when(() => mockGrammarBloc.state).thenReturn(state);
    }

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<GrammarBloc>.value(value: mockGrammarBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  padding: EdgeInsets.zero,
                  viewInsets: EdgeInsets.zero,
                ),
                child: Scaffold(
                  body: PunctuationMasteryScreen(level: level),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('PunctuationMasteryScreen Hardened Layout & Logic Tests', () {
    testWidgets('1. displays shimmer loading when quest is null', (tester) async {
      final initialEmptyState = GrammarInitial();
      await pumpPunctuationMastery(tester, state: initialEmptyState);

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byKey(const ValueKey('punctuation_context_card')), findsNothing);
    });

    testWidgets('2. renders instruction badge with default text', (tester) async {
      await pumpPunctuationMastery(tester);

      expect(find.byKey(const ValueKey('punctuation_mastery_instruction')), findsOneWidget);
      expect(find.text('APPLY HOLOGRAPHIC DECALS'), findsOneWidget);
    });

    testWidgets('3. renders instruction badge with custom instruction text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PunctuationMasteryInstruction(
              primaryColor: Colors.blue,
              instruction: 'CUSTOM PUNCTUATION DIRECTIVE',
            ),
          ),
        ),
      );

      expect(find.text('CUSTOM PUNCTUATION DIRECTIVE'), findsOneWidget);
    });

    testWidgets('4. renders grammar rule box when rule is provided', (tester) async {
      await pumpPunctuationMastery(tester);

      expect(find.byKey(const ValueKey('grammar_rule_box')), findsOneWidget);
      expect(find.text('RULE: COMMA AND EXCLAMATION'), findsOneWidget);
      expect(find.text('Tap to remove misplaced stickers'), findsOneWidget);
    });

    testWidgets('5. omits grammar rule box when grammarRule is null', (tester) async {
      final stateWithoutRule = GrammarLoaded(
        quests: const [testQuestNoRule],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );
      await pumpPunctuationMastery(tester, state: stateWithoutRule);

      expect(find.byKey(const ValueKey('grammar_rule_box')), findsNothing);
      expect(find.byKey(const ValueKey('punctuation_context_card')), findsOneWidget);
    });

    testWidgets('6. renders context card with sticker slots and words', (tester) async {
      await pumpPunctuationMastery(tester);

      expect(find.byKey(const ValueKey('punctuation_context_card')), findsOneWidget);
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('world'), findsOneWidget);

      expect(find.byKey(const ValueKey('punctuation_prefix_slot_0')), findsOneWidget);
      expect(find.byKey(const ValueKey('punctuation_suffix_slot_0')), findsOneWidget);
      expect(find.byKey(const ValueKey('punctuation_prefix_slot_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('punctuation_suffix_slot_1')), findsOneWidget);
    });

    testWidgets('7. renders punctuation sticker sheet with draggable stickers', (tester) async {
      await pumpPunctuationMastery(tester);

      expect(find.byType(PunctuationStickerSheet), findsOneWidget);
      expect(find.byKey(const ValueKey('sticker_mark_,')), findsOneWidget);
      expect(find.byKey(const ValueKey('sticker_mark_!')), findsOneWidget);
      expect(find.byKey(const ValueKey('sticker_mark_.')), findsOneWidget);
      expect(find.byKey(const ValueKey('sticker_mark_?')), findsOneWidget);
    });

    testWidgets('8. renders CHECK ANSWER scale button in unanswered state', (tester) async {
      await pumpPunctuationMastery(tester);

      expect(find.byKey(const ValueKey('punctuation_check_answer_button')), findsOneWidget);
      expect(find.text('CHECK ANSWER'), findsOneWidget);
    });

    testWidgets('9. accepts sticker into slot and updates slot display', (tester) async {
      await pumpPunctuationMastery(tester);

      final slot0 = tester.widget<DragTarget<String>>(
        find.byKey(const ValueKey('punctuation_suffix_slot_0')),
      );
      slot0.onAcceptWithDetails?.call(
        DragTargetDetails<String>(data: ',', offset: Offset.zero),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.descendant(
        of: find.byKey(const ValueKey('punctuation_suffix_slot_0')),
        matching: find.text(','),
      ), findsOneWidget);
    });

    testWidgets('10. tapping filled slot removes sticker', (tester) async {
      await pumpPunctuationMastery(tester);

      final slot0 = tester.widget<DragTarget<String>>(
        find.byKey(const ValueKey('punctuation_suffix_slot_0')),
      );
      slot0.onAcceptWithDetails?.call(
        DragTargetDetails<String>(data: ',', offset: Offset.zero),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.descendant(
        of: find.byKey(const ValueKey('punctuation_suffix_slot_0')),
        matching: find.text(','),
      ), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('punctuation_suffix_slot_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.descendant(
        of: find.byKey(const ValueKey('punctuation_suffix_slot_0')),
        matching: find.text(','),
      ), findsNothing);
    });

    testWidgets('11. tapping CHECK ANSWER with incorrect stickers marks wrong answer and dispatches SubmitAnswer(false)', (tester) async {
      await pumpPunctuationMastery(tester);

      await tester.tap(find.byKey(const ValueKey('punctuation_check_answer_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockGrammarBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('12. tapping CHECK ANSWER with correct stickers enters pending typing mode and reveals TypeToConfirmOverlay', (tester) async {
      await pumpPunctuationMastery(tester);

      final slot0 = tester.widget<DragTarget<String>>(
        find.byKey(const ValueKey('punctuation_suffix_slot_0')),
      );
      slot0.onAcceptWithDetails?.call(
        DragTargetDetails<String>(data: ',', offset: Offset.zero),
      );

      final slot1 = tester.widget<DragTarget<String>>(
        find.byKey(const ValueKey('punctuation_suffix_slot_1')),
      );
      slot1.onAcceptWithDetails?.call(
        DragTargetDetails<String>(data: '!', offset: Offset.zero),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const ValueKey('punctuation_check_answer_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockSoundService.playCorrect()).called(1);
      expect(find.byType(TypeToConfirmOverlay), findsOneWidget);
    });

    testWidgets('13. typing correct target sentence in TypeToConfirmOverlay dispatches SubmitAnswer(true)', (tester) async {
      await pumpPunctuationMastery(tester);

      final slot0 = tester.widget<DragTarget<String>>(
        find.byKey(const ValueKey('punctuation_suffix_slot_0')),
      );
      slot0.onAcceptWithDetails?.call(
        DragTargetDetails<String>(data: ',', offset: Offset.zero),
      );

      final slot1 = tester.widget<DragTarget<String>>(
        find.byKey(const ValueKey('punctuation_suffix_slot_1')),
      );
      slot1.onAcceptWithDetails?.call(
        DragTargetDetails<String>(data: '!', offset: Offset.zero),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const ValueKey('punctuation_check_answer_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final textField = find.descendant(
        of: find.byType(TypeToConfirmOverlay),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(textField);
      await tester.pump();
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'Hello, world!');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final submitBtn = find.descendant(
        of: find.byType(TypeToConfirmOverlay),
        matching: find.text('SUBMIT'),
      );
      await tester.ensureVisible(submitBtn);
      await tester.pump();
      expect(submitBtn, findsOneWidget);

      await tester.tap(submitBtn);
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockGrammarBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('14. typing in TypeToConfirmOverlay and tapping skip or failing dispatches SubmitAnswer(false)', (tester) async {
      await pumpPunctuationMastery(tester);

      final slot0 = tester.widget<DragTarget<String>>(
        find.byKey(const ValueKey('punctuation_suffix_slot_0')),
      );
      slot0.onAcceptWithDetails?.call(
        DragTargetDetails<String>(data: ',', offset: Offset.zero),
      );

      final slot1 = tester.widget<DragTarget<String>>(
        find.byKey(const ValueKey('punctuation_suffix_slot_1')),
      );
      slot1.onAcceptWithDetails?.call(
        DragTargetDetails<String>(data: '!', offset: Offset.zero),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const ValueKey('punctuation_check_answer_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final overlay = tester.widget<TypeToConfirmOverlay>(
        find.byType(TypeToConfirmOverlay),
      );
      overlay.onSkipped.call();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      verify(() => mockGrammarBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('15. answering state disables further sticker interaction and hides CHECK ANSWER button', (tester) async {
      final answeredState = GrammarLoaded(
        quests: const [testQuest1],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );
      await pumpPunctuationMastery(tester, state: answeredState);

      expect(find.byKey(const ValueKey('punctuation_check_answer_button')), findsNothing);
      expect(find.byType(PunctuationStickerSheet), findsNothing);
    });

    testWidgets('16. renders properly on compact screen (< 700dp height)', (tester) async {
      await pumpPunctuationMastery(
        tester,
        size: const Size(360, 640),
      );

      expect(find.byKey(const ValueKey('punctuation_context_card')), findsOneWidget);
      expect(find.byKey(const ValueKey('punctuation_check_answer_button')), findsOneWidget);
    });

    testWidgets('17. renders properly on tablet screen (800x1280)', (tester) async {
      await pumpPunctuationMastery(
        tester,
        size: const Size(800, 1280),
      );

      expect(find.byKey(const ValueKey('punctuation_context_card')), findsOneWidget);
      expect(find.byKey(const ValueKey('punctuation_check_answer_button')), findsOneWidget);
    });

    testWidgets('18. renders properly in light theme mode', (tester) async {
      await pumpPunctuationMastery(
        tester,
        themeMode: ThemeMode.light,
      );

      expect(find.byKey(const ValueKey('punctuation_context_card')), findsOneWidget);
      expect(find.byKey(const ValueKey('punctuation_check_answer_button')), findsOneWidget);
    });

    testWidgets('19. renders properly in dark theme mode', (tester) async {
      await pumpPunctuationMastery(
        tester,
        themeMode: ThemeMode.dark,
      );

      expect(find.byKey(const ValueKey('punctuation_context_card')), findsOneWidget);
      expect(find.byKey(const ValueKey('punctuation_check_answer_button')), findsOneWidget);
    });

    testWidgets('20. renders game briefing layer when level == 1 and briefing unread', (tester) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_punctuationMastery': false,
      });

      await pumpPunctuationMastery(tester, level: 1);

      expect(find.byType(GameBriefingLayer), findsOneWidget);
    });
  });
}
