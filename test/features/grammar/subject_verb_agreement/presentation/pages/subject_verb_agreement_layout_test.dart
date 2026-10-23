import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/game_skip_bypass_button.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';
import 'package:vowl/core/presentation/widgets/game_briefing_layer.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
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
import 'package:vowl/features/grammar/subject_verb_agreement/presentation/pages/subject_verb_agreement_screen.dart';

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
  late MockAppLogger mockAppLogger;
  late MockAnalyticsService mockAnalyticsService;
  late MockAdService mockAdService;

  setUpAll(() {
    VowlMotion.lowAnimationModeOverride.value = true;
    registerFallbackValue(FakeGrammarEvent());
    registerFallbackValue(FakeGrammarState());
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const GrammarHintUsed());
    registerFallbackValue(const Duration(milliseconds: 50));
  });

  tearDownAll(() {
    VowlMotion.lowAnimationModeOverride.value = false;
  });

  const testQuest1 = GrammarQuest(
    id: 'sva_l1_q1',
    instruction: 'COMPLETE THE AGREEMENT',
    difficulty: 1,
    subtype: GameSubtype.subjectVerbAgreement,
    sentenceWithBlank: 'The dogs ___ barking loudly.',
    correctAnswer: 'are',
    options: ['is', 'are'],
    correctAnswerIndex: 1,
    hint: 'Plural subject dogs requires are.',
  );

  const testQuestSingular = GrammarQuest(
    id: 'sva_l1_q2',
    instruction: 'COMPLETE THE AGREEMENT',
    difficulty: 1,
    subtype: GameSubtype.subjectVerbAgreement,
    sentenceWithBlank: 'The cat ___ sleeping peacefully.',
    correctAnswer: 'is',
    options: ['is', 'are'],
    correctAnswerIndex: 0,
    hint: 'Singular subject cat requires is.',
  );

  final testLoadedState = GrammarLoaded(
    quests: const [testQuest1, testQuestSingular],
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
    mockAppLogger = MockAppLogger();
    mockAnalyticsService = MockAnalyticsService();
    mockAdService = MockAdService();

    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_subjectVerbAgreement': true,
    });

    when(() => mockGrammarBloc.state).thenReturn(testLoadedState);
    when(() => mockGrammarBloc.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user_id',
          email: 'test@vowl.app',
          displayName: 'Test Grammarian',
          isPremium: true,
          hintCount: 3,
        ),
      ),
    );
    when(
      () => mockAuthBloc.stream,
    ).thenAnswer((_) => const Stream<AuthState>.empty());

    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockEconomyBloc.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});
    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});

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

    when(
      () => mockAnalyticsService.logGameSkipped(any()),
    ).thenAnswer((_) async {});

    await di.sl.reset();

    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<AppLogger>(mockAppLogger);
    di.sl.registerSingleton<AnalyticsService>(mockAnalyticsService);
    di.sl.registerSingleton<AdService>(mockAdService);
  });

  tearDown(() async {
    await di.sl.reset();
  });

  Future<void> pumpSubjectVerbAgreementScreen(
    WidgetTester tester, {
    GrammarState? state,
    int level = 2,
    Size size = const Size(390, 844),
    ThemeMode themeMode = ThemeMode.dark,
  }) async {
    tester.view.physicalSize = Size(size.width * 2, size.height * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    when(() => mockGrammarBloc.state).thenReturn(state ?? testLoadedState);

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
          builder: (context, child) => MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                padding: EdgeInsets.zero,
                viewInsets: EdgeInsets.zero,
                disableAnimations: true,
              ),
              child: Scaffold(body: SubjectVerbAgreementScreen(level: level)),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('SubjectVerbAgreementScreen Layout & Hardening Tests', () {
    testWidgets('1. displays shimmer loading when state is GrammarInitial', (
      tester,
    ) async {
      await pumpSubjectVerbAgreementScreen(tester, state: GrammarInitial());
      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('2. displays shimmer loading when state is GrammarLoading', (
      tester,
    ) async {
      await pumpSubjectVerbAgreementScreen(tester, state: GrammarLoading());
      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('3. renders atmospheric harmony hub with question text', (
      tester,
    ) async {
      await pumpSubjectVerbAgreementScreen(tester);
      expect(find.byKey(const ValueKey('sva_harmony_hub')), findsOneWidget);
      expect(find.text('The dogs ___ barking loudly.'), findsOneWidget);
    });

    testWidgets('4. renders verb terminal 0 with option IS', (tester) async {
      await pumpSubjectVerbAgreementScreen(tester);
      expect(find.byKey(const ValueKey('sva_terminal_0')), findsOneWidget);
      expect(find.text('IS'), findsOneWidget);
    });

    testWidgets('5. renders verb terminal 1 with option ARE', (tester) async {
      await pumpSubjectVerbAgreementScreen(tester);
      expect(find.byKey(const ValueKey('sva_terminal_1')), findsOneWidget);
      expect(find.text('ARE'), findsOneWidget);
    });

    testWidgets('6. renders quantum core harmony slider in initial position', (
      tester,
    ) async {
      await pumpSubjectVerbAgreementScreen(tester);
      expect(find.byKey(const ValueKey('sva_quantum_core')), findsOneWidget);
    });

    testWidgets(
      '7. tapping incorrect terminal 0 (IS) triggers error haptic, wrong sound, and submits false',
      (tester) async {
        await pumpSubjectVerbAgreementScreen(tester);
        final terminal0 = find.byKey(const ValueKey('sva_terminal_0'));
        expect(terminal0, findsOneWidget);

        await tester.tap(terminal0);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        verify(() => mockHapticService.error()).called(1);
        verify(() => mockSoundService.playWrong()).called(1);
        verify(() => mockGrammarBloc.add(const SubmitAnswer(false))).called(1);
      },
    );

    testWidgets(
      '8. tapping correct terminal 1 (ARE) triggers success haptic, correct sound, and displays TypeToConfirmOverlay',
      (tester) async {
        await pumpSubjectVerbAgreementScreen(tester);
        final terminal1 = find.byKey(const ValueKey('sva_terminal_1'));
        expect(terminal1, findsOneWidget);

        await tester.tap(terminal1);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        verify(() => mockHapticService.success()).called(1);
        verify(() => mockSoundService.playCorrect()).called(1);
        expect(
          find.byKey(const ValueKey('sva_type_overlay'), skipOffstage: false),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '9. correct terminal tap updates atmospheric harmony hub with completed sentence',
      (tester) async {
        await pumpSubjectVerbAgreementScreen(tester);
        await tester.tap(find.byKey(const ValueKey('sva_terminal_1')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('The dogs are barking loudly.'), findsOneWidget);
      },
    );

    testWidgets(
      '10. dragging quantum core slider left beyond threshold triggers terminal 0 (wrong answer)',
      (tester) async {
        await pumpSubjectVerbAgreementScreen(tester);
        final coreFinder = find.byKey(const ValueKey('sva_quantum_core'));
        expect(coreFinder, findsOneWidget);

        // Drag left beyond -100w threshold
        await tester.drag(coreFinder, const Offset(-150, 0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        verify(() => mockHapticService.error()).called(1);
        verify(() => mockSoundService.playWrong()).called(1);
        verify(() => mockGrammarBloc.add(const SubmitAnswer(false))).called(1);
      },
    );

    testWidgets(
      '11. dragging quantum core slider right beyond threshold triggers terminal 1 (correct answer)',
      (tester) async {
        await pumpSubjectVerbAgreementScreen(tester);
        final coreFinder = find.byKey(const ValueKey('sva_quantum_core'));
        expect(coreFinder, findsOneWidget);

        // Drag right beyond 100w threshold
        await tester.drag(coreFinder, const Offset(150, 0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        verify(() => mockHapticService.success()).called(1);
        verify(() => mockSoundService.playCorrect()).called(1);
        expect(
          find.byKey(const ValueKey('sva_type_overlay'), skipOffstage: false),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '12. releasing quantum core slider before threshold does not trigger answer',
      (tester) async {
        await pumpSubjectVerbAgreementScreen(tester);
        final coreFinder = find.byKey(const ValueKey('sva_quantum_core'));

        // Small drag that does not reach threshold
        await tester.drag(coreFinder, const Offset(-30, 0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        verifyNever(() => mockSoundService.playCorrect());
        verifyNever(() => mockSoundService.playWrong());
        expect(find.byType(TypeToConfirmOverlay), findsNothing);
      },
    );

    testWidgets(
      '13. Phase 2 TypeToConfirmOverlay accepts correct sentence input',
      (tester) async {
        await pumpSubjectVerbAgreementScreen(tester);
        await tester.tap(find.byKey(const ValueKey('sva_terminal_1')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        final overlayFinder = find.byKey(
          const ValueKey('sva_type_overlay'),
          skipOffstage: false,
        );
        expect(overlayFinder, findsOneWidget);
        await tester.ensureVisible(overlayFinder);
        await tester.pump(const Duration(milliseconds: 200));

        final textField = find.byType(TextField);
        expect(textField, findsOneWidget);

        await tester.enterText(textField, 'The dogs are barking loudly.');
        await tester.pump();

        final submitBtn = find.text('SUBMIT');
        expect(submitBtn, findsOneWidget);
        await tester.ensureVisible(submitBtn);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(submitBtn);
        await tester.pump(const Duration(milliseconds: 1000));
        await tester.pump(const Duration(milliseconds: 200));

        verify(() => mockGrammarBloc.add(const SubmitAnswer(true))).called(1);
      },
    );

    testWidgets(
      '14. Phase 2 TypeToConfirmOverlay skipping dispatches event to bloc',
      (tester) async {
        await pumpSubjectVerbAgreementScreen(tester);
        await tester.tap(find.byKey(const ValueKey('sva_terminal_1')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        final overlayFinder = find.byKey(
          const ValueKey('sva_type_overlay'),
          skipOffstage: false,
        );
        expect(overlayFinder, findsOneWidget);
        await tester.ensureVisible(overlayFinder);
        await tester.pump(const Duration(milliseconds: 200));

        final skipBtn = find.byType(GameSkipBypassButton);
        expect(skipBtn, findsOneWidget);
        await tester.ensureVisible(skipBtn);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(skipBtn);
        await tester.pump(const Duration(milliseconds: 1000));
        await tester.pump(const Duration(milliseconds: 200));

        verify(
          () => mockGrammarBloc.add(any()),
        ).called(greaterThanOrEqualTo(1));
      },
    );

    testWidgets('15. terminals are locked out once answered (answer lockout)', (
      tester,
    ) async {
      await pumpSubjectVerbAgreementScreen(tester);
      // Trigger wrong answer
      await tester.tap(find.byKey(const ValueKey('sva_terminal_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      clearInteractions(mockHapticService);
      clearInteractions(mockSoundService);

      // Tapping terminal 1 should do nothing now
      await tester.tap(
        find.byKey(const ValueKey('sva_terminal_1')),
        warnIfMissed: false,
      );
      await tester.pump();

      verifyNever(() => mockHapticService.success());
      verifyNever(() => mockSoundService.playCorrect());
    });

    testWidgets('16. dragging slider is disabled once answered', (
      tester,
    ) async {
      await pumpSubjectVerbAgreementScreen(tester);
      // Trigger wrong answer
      await tester.tap(find.byKey(const ValueKey('sva_terminal_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      clearInteractions(mockSoundService);

      final coreFinder = find.byKey(const ValueKey('sva_quantum_core'));
      await tester.drag(coreFinder, const Offset(150, 0), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verifyNever(() => mockSoundService.playCorrect());
    });

    testWidgets('17. handles singular subject quest correctly', (tester) async {
      final singularState = GrammarLoaded(
        quests: const [testQuestSingular],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );

      await pumpSubjectVerbAgreementScreen(tester, state: singularState);
      expect(find.text('The cat ___ sleeping peacefully.'), findsOneWidget);

      // Terminal 0 is IS (correct index 0)
      await tester.tap(find.byKey(const ValueKey('sva_terminal_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockSoundService.playCorrect()).called(1);
      expect(
        find.byKey(const ValueKey('sva_type_overlay'), skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('18. onContinue callback triggers NextQuestion event', (
      tester,
    ) async {
      await pumpSubjectVerbAgreementScreen(tester);
      await tester.tap(find.byKey(const ValueKey('sva_terminal_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final continueButtonFinder = find.widgetWithText(ScaleButton, 'CONTINUE');
      if (continueButtonFinder.evaluate().isNotEmpty) {
        await tester.tap(continueButtonFinder.first);
        await tester.pump();
        verify(() => mockGrammarBloc.add(const NextQuestion())).called(1);
      }
    });

    testWidgets('19. onHint callback triggers GrammarHintUsed event', (
      tester,
    ) async {
      await pumpSubjectVerbAgreementScreen(tester);
      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump();

      verify(() => mockGrammarBloc.add(const GrammarHintUsed())).called(1);
    });

    testWidgets('20. layout adapts gracefully in compact height (< 700)', (
      tester,
    ) async {
      await pumpSubjectVerbAgreementScreen(tester, size: const Size(360, 640));
      expect(find.byKey(const ValueKey('sva_harmony_hub')), findsOneWidget);
      expect(find.byKey(const ValueKey('sva_quantum_core')), findsOneWidget);
    });

    testWidgets(
      '21. renders correctly in light theme without layout overflow',
      (tester) async {
        await pumpSubjectVerbAgreementScreen(
          tester,
          themeMode: ThemeMode.light,
        );
        expect(find.byType(SubjectVerbAgreementScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('22. renders correctly in dark theme without layout overflow', (
      tester,
    ) async {
      await pumpSubjectVerbAgreementScreen(tester, themeMode: ThemeMode.dark);
      expect(find.byType(SubjectVerbAgreementScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('23. renders correctly on wide tablet screen', (tester) async {
      await pumpSubjectVerbAgreementScreen(tester, size: const Size(800, 1200));
      expect(find.byType(SubjectVerbAgreementScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('24. respects level 1 game briefing dialog on first run', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_subjectVerbAgreement': false,
      });

      await pumpSubjectVerbAgreementScreen(tester, level: 1);

      expect(find.byType(GameBriefingLayer), findsOneWidget);
    });

    testWidgets(
      '25. renders instruction pill with centered text and natural phrasing',
      (tester) async {
        await pumpSubjectVerbAgreementScreen(tester);
        final instructionFinder = find.byKey(const ValueKey('sva_instruction'));
        expect(instructionFinder, findsOneWidget);

        final textWidget = tester.widget<Text>(
          find.descendant(of: instructionFinder, matching: find.byType(Text)),
        );
        expect(textWidget.textAlign, TextAlign.center);
        expect(textWidget.softWrap, isTrue);
        expect(
          textWidget.data,
          contains('Select the verb that agrees with the subject'),
        );
      },
    );

    testWidgets(
      '26. TypeToConfirmOverlay has standard horizontal padding and does not touch edges',
      (tester) async {
        await pumpSubjectVerbAgreementScreen(tester);
        await tester.tap(find.byKey(const ValueKey('sva_terminal_1')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        final overlayFinder = find.byKey(
          const ValueKey('sva_type_overlay'),
          skipOffstage: false,
        );
        expect(overlayFinder, findsOneWidget);

        final overlayRect = tester.getRect(overlayFinder);
        expect(overlayRect.left, greaterThan(0));
        expect(overlayRect.right, lessThan(390));
      },
    );
  });
}
