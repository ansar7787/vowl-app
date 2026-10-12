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
import 'package:vowl/core/utils/story_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/kids_zone/domain/entities/kids_quest.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_audio_service.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/layouts/kids_nature_layout.dart';

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

  const testShortQuest = KidsQuest(
    id: 'KIDS_NATURE_L1_Q1',
    gameType: 'nature',
    level: 2,
    instruction: 'What gives Earth most of its light and warmth during the day?',
    question: '?',
    correctAnswer: 'Sun ☀️',
    options: [
      'Sun ☀️',
      'Moon 🌙',
      'Cloud ☁️',
    ],
    hint: 'Its light is the reason you can see colors outside in the morning.',
    emoji: '🌅',
    explanation: 'The Sun is a star that sends out light and heat.',
    funFact: 'Sunlight takes about eight minutes to reach Earth.',
  );

  const testLongQuest = KidsQuest(
    id: 'KIDS_NATURE_L52_Q1',
    gameType: 'nature',
    level: 52,
    instruction: 'What is the correct life cycle order of a flowering plant?',
    question: '?',
    correctAnswer: 'Seed, sprout, flowering plant 🌱',
    options: [
      'Flowering plant, sprout, seed 🌸',
      'Seed, sprout, flowering plant 🌱',
      'Sprout, seed, flowering plant 🌿',
    ],
    hint: 'It starts tiny in the soil, pushes up green, then blooms.',
    emoji: '🌱',
    explanation: 'Plants start as seeds, germinate into sprouts, and grow flowers.',
    funFact: 'Some seeds can wait hundreds of years before sprouting.',
  );

  const testShortLoadedState = KidsLoaded(
    quests: [testShortQuest],
    originalTotalQuests: 1,
    gameType: 'nature',
    level: 2,
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
  );

  const testLongLoadedState = KidsLoaded(
    quests: [testLongQuest],
    originalTotalQuests: 1,
    gameType: 'nature',
    level: 52,
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

    when(() => mockKidsBloc.state).thenReturn(testShortLoadedState);
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

    when(() => mockTTSService.isNarrationEnabled()).thenAnswer((_) async => true);
    when(() => mockTTSService.speak(any(), force: any(named: 'force')))
        .thenAnswer((_) async => true);
    when(() => mockTTSService.stop()).thenAnswer((_) => Future.value());
    when(() => mockTTSService.dispose()).thenAnswer((_) => Future.value());

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});

    when(() => mockLocaleService.tr(any())).thenAnswer((inv) {
      final key = inv.positionalArguments.first as String;
      if (key == 'games.kids_nature_action_hint') {
        return 'Tap a stone or drag it to the tree sign! ✨';
      }
      if (key == 'games.kids_drop_here') {
        return 'Drop here! ✨';
      }
      if (key == 'games.kids_clue') {
        return 'Clue';
      }
      if (key == 'games.try_again') {
        return 'Try Again! 🌿';
      }
      return key;
    });

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

  tearDown(() {
    if (di.sl.isRegistered<KidsTTSService>()) di.sl.unregister<KidsTTSService>();
    if (di.sl.isRegistered<KidsAudioService>()) di.sl.unregister<KidsAudioService>();
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
  });

  Widget buildTestScreen({
    Size screenSize = const Size(390, 844),
    KidsState? stateOverride,
  }) {
    if (stateOverride != null) {
      when(() => mockKidsBloc.state).thenReturn(stateOverride);
    }

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MultiBlocProvider(
        providers: [
          BlocProvider<KidsBloc>.value(value: mockKidsBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const KidsNatureLayout(
            level: 2,
            title: 'Nature',
            primaryColor: Color(0xFF22C55E),
          ),
        ),
      ),
    );
  }

  group('KidsNatureLayout Production Tests', () {
    testWidgets('renders ancient tree sign, fireflies, and short river stone options without overflow', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);

      // Verify all options are visible on river stones
      expect(find.text('Sun ☀️'), findsOneWidget);
      expect(find.text('Moon 🌙'), findsOneWidget);
      expect(find.text('Cloud ☁️'), findsOneWidget);

      // Verify clue button on ancient tree sign
      expect(find.text('Clue'), findsOneWidget);

      // Verify prompt subtitle is present
      expect(
        find.text('Choose an answer or drag it to the sign'),
        findsOneWidget,
      );
    });

    testWidgets('renders multi-word sentence options in legible stepping stone cards', (tester) async {
      await tester.pumpWidget(buildTestScreen(stateOverride: testLongLoadedState));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);

      // Verify long wrapped options are rendered cleanly
      expect(find.text('Seed, sprout, flowering plant 🌱'), findsOneWidget);
      expect(find.text('Flowering plant, sprout, seed 🌸'), findsOneWidget);
      expect(find.text('Sprout, seed, flowering plant 🌿'), findsOneWidget);

      // Verify 1, 2, 3 indexing badges
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('tap-to-select submits answer directly and triggers speech reinforcement', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap on the correct stone 'Sun ☀️'
      await tester.tap(find.text('Sun ☀️'));
      await tester.pump();

      // Verify SubmitKidsAnswer(true) was added to bloc
      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);

      // Verify speech reinforcement was called with 'Sun ☀️'
      verify(() => mockTTSService.speak('Sun ☀️', force: true)).called(1);
      verify(() => mockHapticService.success()).called(1);
    });

    testWidgets('tapping clue button replays question instruction via TTS', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap on 'Clue' button on tree sign
      await tester.tap(find.text('Clue'));
      await tester.pump();

      // Verify question instruction was read aloud
      verify(
        () => mockTTSService.speak(
          testShortQuest.instruction,
          force: true,
        ),
      ).called(1);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('tapping stone speaker icon plays option audio without submitting', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Find speaker icons on river stones
      final speakerIcons = find.byIcon(Icons.volume_up_rounded);
      expect(speakerIcons, findsWidgets);

      // Tap speaker on river stone
      await tester.tap(speakerIcons.at(2)); // index 0 is Clue, index 1 is Sun, index 2 is Moon
      await tester.pump();

      // Verify TTS spoke 'Moon 🌙'
      verify(() => mockTTSService.speak('Moon 🌙', force: true)).called(1);

      // Verify no answer was submitted
      verifyNever(() => mockKidsBloc.add(any(that: isA<SubmitKidsAnswer>())));
    });

    testWidgets('drag and drop onto tree sign submits answer successfully', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Find Draggable for 'Sun ☀️'
      final stoneFinder = find.byWidgetPredicate(
        (widget) => widget is Draggable<String> && widget.data == 'Sun ☀️',
      );
      expect(stoneFinder, findsOneWidget);

      final signFinder = find.byType(DragTarget<String>);
      expect(signFinder, findsOneWidget);

      // Drag 'Sun ☀️' onto tree sign target
      await tester.drag(stoneFinder, const Offset(0, -280));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify DragTarget processed the drop
      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
    });

    testWidgets('renders cleanly on compact 360x640 phone without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      expect(find.text('Sun ☀️'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('renders cleanly on large 430x932 phone without overflow', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      expect(find.text('Sun ☀️'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('displays celebration badge when answered correctly', (tester) async {
      const correctState = KidsLoaded(
        quests: [testShortQuest],
        originalTotalQuests: 1,
        gameType: 'nature',
        level: 2,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
      );

      await tester.pumpWidget(buildTestScreen(stateOverride: correctState));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);

      // Tree sign displays the discovered item name 'Sun ☀️' and discovery emoji '🌅'
      expect(find.text('Sun ☀️'), findsWidgets);
      expect(find.text('🌅'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('renders multi-part phrase options like Sunshine, wind, and stones with zero ellipsis and zero overflow', (tester) async {
      const userPhraseQuest = KidsQuest(
        id: 'KIDS_NATURE_USER_PHRASE',
        gameType: 'nature',
        level: 81,
        instruction: 'What are basic non-living parts of a habitat?',
        question: '?',
        correctAnswer: 'Sunshine, wind, and stones 🪨',
        options: [
          'Sunshine, wind, and stones 🪨',
          'Food, water, and shelter 🏠',
          'Toys, music, and games 🎮',
        ],
        hint: 'Think of things made by nature that are not alive.',
        emoji: '🪨',
        explanation: 'Habitats include both living things and non-living elements.',
        funFact: 'Rocks can take millions of years to form.',
      );

      const phraseState = KidsLoaded(
        quests: [userPhraseQuest],
        originalTotalQuests: 1,
        gameType: 'nature',
        level: 81,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
      );

      await tester.pumpWidget(buildTestScreen(stateOverride: phraseState));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);

      // Verify every full option is completely rendered without any truncation or ellipsis
      expect(find.text('Sunshine, wind, and stones 🪨'), findsOneWidget);
      expect(find.text('Food, water, and shelter 🏠'), findsOneWidget);
      expect(find.text('Toys, music, and games 🎮'), findsOneWidget);

      // Verify ellipsis string does not appear in any Text widget
      expect(find.textContaining('...'), findsNothing);
      expect(find.textContaining('…'), findsNothing);
    });

    testWidgets('renders 4 options smoothly without ellipsis or overflow when options count increases in future levels', (tester) async {
      const fourOptionsQuest = KidsQuest(
        id: 'KIDS_NATURE_FUTURE_4_OPTS',
        gameType: 'nature',
        level: 150,
        instruction: 'Which elements are found in an alpine mountain biome?',
        question: '?',
        correctAnswer: 'Rocky peaks, pine trees, and fresh snow 🏔️',
        options: [
          'Rocky peaks, pine trees, and fresh snow 🏔️',
          'Hot sand dunes and giant cactus plants 🏜️',
          'Tropical corals and colorful sea turtles 🐢',
          'City buildings, highways, and shopping centers 🏙️',
        ],
        hint: 'High up where the air is cold and thin.',
        emoji: '🏔️',
      );

      const fourOptsState = KidsLoaded(
        quests: [fourOptionsQuest],
        originalTotalQuests: 1,
        gameType: 'nature',
        level: 150,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
      );

      await tester.pumpWidget(buildTestScreen(stateOverride: fourOptsState));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);

      // Verify all 4 options are rendered as stepping stone cards
      expect(find.text('Rocky peaks, pine trees, and fresh snow 🏔️'), findsOneWidget);
      expect(find.text('Hot sand dunes and giant cactus plants 🏜️'), findsOneWidget);
      expect(find.text('Tropical corals and colorful sea turtles 🐢'), findsOneWidget);
      expect(find.text('City buildings, highways, and shopping centers 🏙️'), findsOneWidget);

      // Verify 4 indexing badges
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);

      // Zero ellipsis
      expect(find.textContaining('...'), findsNothing);
      expect(find.textContaining('…'), findsNothing);
    });

    testWidgets('displays Try Again encouragement when answered incorrectly', (tester) async {
      const incorrectState = KidsLoaded(
        quests: [testShortQuest],
        originalTotalQuests: 1,
        gameType: 'nature',
        level: 2,
        currentIndex: 0,
        livesRemaining: 2,
        answerStatus: AnswerStatus.incorrect,
      );

      await tester.pumpWidget(buildTestScreen(stateOverride: incorrectState));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);

      // Tree sign displays Try Again prompt
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    });

    testWidgets('StoryService resolves warm, human-crafted narrative beats for Level 1 and Level 100', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final BuildContext context = tester.element(find.byType(KidsNatureLayout));

      final storyService = StoryService();

      // Level 1 story beat
      final beat1 = storyService.getStoryBeat(context, 'nature', 1);
      expect(beat1, isNotNull);
      expect(beat1!.text, contains('Welcome to Nature!'));
      expect(beat1.mascotEmoji, equals('🌳'));

      // Level 100 milestone story beat
      final beat100 = storyService.getStoryBeat(context, 'nature', 100);
      expect(beat100, isNotNull);
      expect(beat100!.text, contains('100 levels completed!'));
      expect(beat100.mascotEmoji, equals('🌳'));
    });

    testWidgets('GameInstructionService resolves Nature briefing matching tree sign and audio features', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final BuildContext context = tester.element(find.byType(KidsNatureLayout));

      final briefing = GameInstructionService.getBriefing(context, null, 'nature', level: 1);

      expect(briefing.title, equals('Nature'));
      expect(briefing.objective, contains('tree sign'));
      expect(briefing.rules.any((r) => r.contains('tree sign')), isTrue);
      expect(briefing.rules.any((r) => r.contains('speaker')), isTrue);
      expect(briefing.tip, contains('speaker'));
      expect(briefing.actionText, equals('Start Playing'));
    });
  });
}
