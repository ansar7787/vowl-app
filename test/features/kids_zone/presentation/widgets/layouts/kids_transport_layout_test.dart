import 'dart:convert';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/game_instruction_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/kids_zone/domain/entities/kids_quest.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_audio_service.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/core/utils/story_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/layouts/kids_transport_layout.dart';

class MockKidsBloc extends MockBloc<KidsEvent, KidsState> implements KidsBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockKidsTTSService extends Mock implements KidsTTSService {}

class MockKidsAudioService extends Mock implements KidsAudioService {}

class MockHapticService extends Mock implements HapticService {}

class MockAppLogger extends Mock implements AppLogger {}

class MockLocaleService extends Mock implements LocaleService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(const SubmitKidsAnswer(true));
  });

  late MockKidsBloc mockKidsBloc;
  late MockAuthBloc mockAuthBloc;
  late MockKidsTTSService mockTTSService;
  late MockKidsAudioService mockAudioService;
  late MockHapticService mockHapticService;
  late MockAppLogger mockLogger;
  late MockLocaleService mockLocaleService;

  const testQuestBasic = KidsQuest(
    id: 'KIDS_TRANSPORT_L2_Q1',
    gameType: 'transport',
    level: 2,
    instruction:
        'Which vehicle does a family often keep at home for trips to the shops?',
    question: '?',
    correctAnswer: '🚗',
    options: ['⛵', '✈️', '🚗'],
    hint: 'It has four wheels, drives on the road, and has room for a few people.',
    emoji: '🚗',
    explanation:
        'A car has four wheels and a motor, and it drives on roads.',
    funFact: 'Some cars today run on electricity from a battery.',
  );

  const testQuestWalking = KidsQuest(
    id: 'KIDS_TRANSPORT_L91_Q1',
    gameType: 'transport',
    level: 91,
    instruction:
        'A child lives 400 metres from school along a quiet pavement. What is the healthiest way to get there?',
    question: '?',
    correctAnswer: '🚶',
    options: ['🚌', '🚶', '🚗'],
    hint: 'No ticket, no fuel, and only a few minutes.',
    emoji: '🚶',
    explanation: 'Walking is healthy and quiet.',
    funFact: 'Walking each day keeps the heart strong.',
  );

  const testLoadedState = KidsLoaded(
    quests: [testQuestBasic],
    originalTotalQuests: 1,
    gameType: 'transport',
    level: 2,
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    mockKidsBloc = MockKidsBloc();
    mockAuthBloc = MockAuthBloc();
    mockTTSService = MockKidsTTSService();
    mockAudioService = MockKidsAudioService();
    mockHapticService = MockHapticService();
    mockLogger = MockAppLogger();
    mockLocaleService = MockLocaleService();

    when(() => mockKidsBloc.state).thenReturn(testLoadedState);
    when(() => mockKidsBloc.stream).thenAnswer((_) => const Stream<KidsState>.empty());

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'kid_user_1',
          email: 'kid@vowl.app',
          completedLevels: {},
          totalExp: 50,
        ),
      ),
    );
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream<AuthState>.empty());

    when(() => mockTTSService.speak(any(), force: any(named: 'force')))
        .thenAnswer((_) async => true);
    when(() => mockTTSService.stop()).thenAnswer((_) => Future.value());
    when(() => mockTTSService.isNarrationEnabled()).thenAnswer((_) async => false);

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});

    when(() => mockAudioService.playLevelCompleteSFX()).thenAnswer((_) async {});

    when(() => mockLocaleService.tr(any())).thenAnswer((inv) => inv.positionalArguments.first as String);

    if (di.sl.isRegistered<KidsTTSService>()) di.sl.unregister<KidsTTSService>();
    if (di.sl.isRegistered<KidsAudioService>()) di.sl.unregister<KidsAudioService>();
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();

    di.sl.registerSingleton<KidsTTSService>(mockTTSService);
    di.sl.registerSingleton<KidsAudioService>(mockAudioService);
    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<AppLogger>(mockLogger);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
  });

  Future<void> pumpTransportLayout(
    WidgetTester tester, {
    KidsState? state,
    double width = 390,
    double height = 844,
  }) async {
    tester.view.physicalSize = Size(width * 2, height * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    if (state != null) {
      when(() => mockKidsBloc.state).thenReturn(state);
    }

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<KidsBloc>.value(value: mockKidsBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, height),
                  textScaler: TextScaler.noScaling,
                ),
                child: const KidsTransportLayout(
                  level: 2,
                  title: 'Transport',
                  primaryColor: Color(0xFF047857),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('KidsTransportLayout Production Audit Tests', () {
    testWidgets('renders highway gantry, route badge, clue scenario, and 3 transit cards',
        (tester) async {
      await pumpTransportLayout(tester);

      expect(find.text('Route 2'), findsOneWidget);
      expect(
        find.text(
          'Which vehicle does a family often keep at home for trips to the shops?',
        ),
        findsWidgets,
      );
      expect(find.text('Car'), findsOneWidget);
      expect(find.text('Sailboat'), findsOneWidget);
      expect(find.text('Airplane'), findsOneWidget);
      expect(find.text('Listen'), findsOneWidget);
    });

    testWidgets('supports accessible tap-to-answer submission (dual interaction)',
        (tester) async {
      await pumpTransportLayout(tester);

      // Tap the Car option card
      await tester.tap(find.text('Car'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockTTSService.speak('Car', force: true)).called(1);
      verify(() => mockHapticService.success()).called(1);
      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
      verify(() => mockLogger.debug(any())).called(greaterThanOrEqualTo(1));
    });

    testWidgets('supports drag-and-drop to highway gantry destination target',
        (tester) async {
      await pumpTransportLayout(tester);

      final carFinder = find.text('Car');
      final gantryFinder = find.byType(DragTarget<String>);

      expect(carFinder, findsOneWidget);
      expect(gantryFinder, findsOneWidget);

      final dragLocation = tester.getCenter(gantryFinder);
      final gesture = await tester.startGesture(tester.getCenter(carFinder));
      await tester.pump(const Duration(milliseconds: 100));

      await gesture.moveTo(dragLocation);
      await tester.pump(const Duration(milliseconds: 100));

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
    });

    testWidgets('replays clue audio when Listen button is tapped',
        (tester) async {
      await pumpTransportLayout(tester);

      final listenFinder = find.text('Listen');
      expect(listenFinder, findsOneWidget);

      await tester.tap(listenFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(
        () => mockTTSService.speak(
          'Which vehicle does a family often keep at home for trips to the shops?',
          force: true,
        ),
      ).called(1);
    });

    testWidgets('pronounces vehicle name when card speaker button is tapped',
        (tester) async {
      await pumpTransportLayout(tester);

      final speakerButtons = find.byIcon(Icons.volume_up_rounded);
      // First is Listen on gantry, next are the 3 cards
      expect(speakerButtons, findsNWidgets(4));

      // Tap speaker on the second card (Airplane)
      await tester.tap(speakerButtons.at(2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockTTSService.speak('Airplane', force: true)).called(1);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('displays celebratory route clear banner upon correct answer',
        (tester) async {
      const solvedState = KidsLoaded(
        quests: [testQuestBasic],
        originalTotalQuests: 1,
        gameType: 'transport',
        level: 1,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
      );

      await pumpTransportLayout(tester, state: solvedState);

      expect(find.text('Correct!'), findsOneWidget);
      expect(find.text('Car'), findsWidgets);
    });

    testWidgets('renders walking scenario with pedestrians correctly',
        (tester) async {
      const walkingState = KidsLoaded(
        quests: [testQuestWalking],
        originalTotalQuests: 1,
        gameType: 'transport',
        level: 91,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
      );

      await pumpTransportLayout(tester, state: walkingState);

      expect(
        find.text(
          'A child lives 400 metres from school along a quiet pavement. What is the healthiest way to get there?',
        ),
        findsWidgets,
      );
      expect(find.text('Walking'), findsOneWidget);
      expect(find.text('Bus'), findsOneWidget);
      expect(find.text('Car'), findsOneWidget);
    });

    testWidgets('dims a wrong distractor when lifeline hintUsed is true',
        (tester) async {
      const hintState = KidsLoaded(
        quests: [testQuestBasic],
        originalTotalQuests: 1,
        gameType: 'transport',
        level: 1,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: true,
      );

      await pumpTransportLayout(tester, state: hintState);

      final animatedOpacities = tester.widgetList<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );

      // At least one card must have opacity 0.32
      expect(animatedOpacities.any((ao) => ao.opacity == 0.32), isTrue);
    });

    testWidgets('locks interaction when question is already answered',
        (tester) async {
      const answeredState = KidsLoaded(
        quests: [testQuestBasic],
        originalTotalQuests: 1,
        gameType: 'transport',
        level: 2,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
      );

      await pumpTransportLayout(tester, state: answeredState);

      reset(mockKidsBloc);
      when(() => mockKidsBloc.state).thenReturn(answeredState);
      when(() => mockKidsBloc.stream).thenAnswer((_) => const Stream<KidsState>.empty());

      // Tapping option should not submit again
      await tester.tap(find.text('Car').last, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verifyNever(() => mockKidsBloc.add(any()));
    });

    testWidgets('renders without overflow on narrow 320dp screen',
        (tester) async {
      await pumpTransportLayout(tester, width: 320, height: 568);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on large 430dp screen',
        (tester) async {
      await pumpTransportLayout(tester, width: 430, height: 932);
      expect(tester.takeException(), isNull);
    });
  });

  group('GameInstructionService Integration Tests', () {
    testWidgets('GameInstructionService Level 1 transport briefing matches game mechanics',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final briefing = GameInstructionService.getBriefing(
                context,
                null,
                'transport',
                level: 1,
              );
              expect(briefing.title, 'Zoom Zoom!');
              expect(briefing.actionText, 'Start Engine');
              expect(briefing.icon, Icons.directions_car_rounded);
              expect(briefing.objective, contains('highway sign'));
              expect(briefing.rules.length, 3);
              expect(briefing.rules[0], 'Read or listen to the clue on the highway sign');
              expect(briefing.rules[1], 'Tap or drag the matching vehicle to answer');
              expect(briefing.rules[2], 'Tap any card\'s speaker to hear the word pronounced');
              expect(briefing.tip, contains('Think about where each vehicle travels'));
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('GameInstructionService Level 100 milestone briefing recognizes century achievement',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final briefing100 = GameInstructionService.getBriefing(
                context,
                null,
                'transport',
                level: 100,
              );
              expect(briefing100.title, 'Century Traveler! 🏆');
              expect(briefing100.actionText, 'Start Level 100');
              expect(briefing100.icon, Icons.emoji_events_rounded);
              expect(briefing100.objective, contains('Level 100'));
              expect(briefing100.rules.length, 3);
              expect(briefing100.rules[0], contains('milestone clue'));
              expect(briefing100.rules[1], contains('Tap or drag'));
              expect(briefing100.rules[2], contains('Celebrate 100 levels'));
              expect(briefing100.tip, contains('land, sea, and air'));
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });

  group('StoryService Transport Integration Tests', () {
    testWidgets('StoryService provides human, educational narrative beats for Level 1 and Level 100',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final storyService = StoryService();

              // Level 1: Welcome beat
              final beat1 = storyService.getStoryBeat(context, 'transport', 1);
              expect(beat1, isNotNull);
              expect(beat1!.title, 'New Quest');
              expect(beat1.text, contains('Welcome traveler!'));
              expect(beat1.text, contains('land, sea, and in the air!'));

              // Level 100: Grand milestone beat
              final beat100 = storyService.getStoryBeat(context, 'transport', 100);
              expect(beat100, isNotNull);
              expect(beat100!.title, 'Adventure Log');
              expect(beat100.text, contains('One hundred levels of travel!'));
              expect(beat100.text, contains('road, across oceans, and up in the sky!'));

              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });

  group('Curriculum Forensic Verification (All 20 Batches, 200 Levels, 600 Quests)', () {
    test('validates all 600 quests across 20 transport batches', () {
      int totalLevels = 0;
      int totalQuests = 0;

      for (int b = 1; b <= 20; b++) {
        final file = File('assets/curriculum/kids/transport/transport_batch_$b.json');
        expect(file.existsSync(), isTrue, reason: 'Batch $b file must exist');

        final content = jsonDecode(file.readAsStringSync()) as List<dynamic>;
        expect(content.length, 10, reason: 'Each batch must contain exactly 10 levels');

        for (final levelData in content) {
          totalLevels++;
          final quests = levelData['quests'] as List<dynamic>;
          expect(quests.length, 3, reason: 'Level ${levelData['level']} must contain 3 quests');

          for (final q in quests) {
            totalQuests++;
            final id = q['id'] as String;
            final instruction = q['instruction'] as String;
            final correctAnswer = q['correctAnswer'] as String;
            final options = (q['options'] as List<dynamic>).cast<String>();
            final hint = q['hint'] as String;
            final emoji = q['emoji'] as String;
            final explanation = q['explanation'] as String;
            final funFact = q['funFact'] as String;

            expect(id, isNotEmpty, reason: '$id has empty id');
            expect(instruction, isNotEmpty, reason: '$id has empty instruction');
            expect(correctAnswer, isNotEmpty, reason: '$id has empty correctAnswer');
            expect(options.length, 3, reason: '$id options length must be 3');
            expect(options.contains(correctAnswer), isTrue, reason: '$id options must contain correctAnswer');
            expect(hint, isNotEmpty, reason: '$id has empty hint');
            expect(emoji, isNotEmpty, reason: '$id has empty emoji');
            expect(explanation, isNotEmpty, reason: '$id has empty explanation');
            expect(funFact, isNotEmpty, reason: '$id has empty funFact');

            // Verify that TransportVocabularyHelper safely processes all options
            for (final opt in options) {
              expect(() => TransportVocabularyHelper.getLabel(opt), returnsNormally);
              expect(() => TransportVocabularyHelper.getSpeechText(opt), returnsNormally);
            }
          }
        }
      }

      expect(totalLevels, 200);
      expect(totalQuests, 600);

      // Verify core transport vocabulary coverage
      const coreVehicles = ['🚗', '🚙', '🚌', '🚆', '🚄', '✈️', '🚁', '🚢', '⛵', '🚲', '🏍️', '🚕', '🚖', '🚑', '🚒', '🚓'];
      for (final v in coreVehicles) {
        expect(
          TransportVocabularyHelper.getLabel(v),
          isNotEmpty,
          reason: 'Core transport vehicle $v must have an English label',
        );
      }
    });
  });
}
