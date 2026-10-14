import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/kids_zone/domain/entities/kids_quest.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_audio_service.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/layouts/kids_opposites_layout.dart';

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

  const testQuestHot = KidsQuest(
    id: 'KIDS_OPPOSITES_L1_Q1',
    gameType: 'opposites',
    level: 1,
    instruction: 'Which word is the opposite of “hot”?',
    question: '?',
    correctAnswer: 'Cold',
    options: ['Wet', 'Soft', 'Cold'],
    hint: 'Imagine holding an ice cube in your bare hand.',
    emoji: '🧊',
    explanation: 'Hot and cold sit at opposite ends of how things feel to touch.',
    funFact: 'The English word “hot” comes from the Old English word “hāt”.',
  );

  const testQuestLong = KidsQuest(
    id: 'KIDS_OPPOSITES_L10_Q3',
    gameType: 'opposites',
    level: 10,
    instruction: 'Two matching socks are the same. A red sock and a blue sock are…',
    question: '?',
    correctAnswer: 'Different',
    options: ['Dry', 'Different', 'Matching'],
    hint: 'Do these two socks go together as a pair?',
    emoji: '🧦',
    explanation: 'Same means exactly alike. Different means not alike in some way.',
    funFact: '“Different” comes from a Latin word meaning “to set apart”.',
  );

  const testLoadedState = KidsLoaded(
    quests: [testQuestHot],
    originalTotalQuests: 1,
    gameType: 'opposites',
    level: 1,
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
      if (key == 'games.kids_opposites_prompt' ||
          key == 'games.kids_opposites_drag') {
        return 'Tap or drag the matching opposite';
      }
      if (key == 'games.clue') return 'CLUE';
      if (key == 'games.opposite') return 'OPPOSITE';
      if (key == 'games.listen') return 'Listen';
      if (key == 'games.drop_target') return 'Drop opposite here';
      if (key == 'games.drop_now') return 'Drop here';
      if (key == 'games.matched') return 'Matched';
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
      builder: (context, _) => MediaQuery(
        data: MediaQueryData(size: screenSize),
        child: MultiBlocProvider(
          providers: [
            BlocProvider<KidsBloc>.value(value: mockKidsBloc),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const KidsOppositesLayout(
              level: 2,
              title: 'Opposites',
              primaryColor: Color(0xFF6366F1),
            ),
          ),
        ),
      ),
    );
  }

  group('KidsOppositesLayout Production Tests', () {
    testWidgets('renders Split World portal, premise clue HOT, prompt text, and all options', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Premise word extracted from quotes in instruction
      expect(find.text('HOT'), findsOneWidget);

      // Premise realm headers
      expect(find.text('CLUE'), findsOneWidget);
      expect(find.text('OPPOSITE'), findsOneWidget);

      // Subtitle clue in realm
      expect(find.text('Opposite of “HOT”'), findsOneWidget);

      // Mascot speech bubble instruction
      expect(find.text('Which word is the opposite of “hot”?'), findsOneWidget);

      // All option plaques present
      expect(find.text('Wet'), findsOneWidget);
      expect(find.text('Soft'), findsOneWidget);
      expect(find.text('Cold'), findsOneWidget);

      // Action hint present
      expect(find.text('Tap or drag the matching opposite'), findsOneWidget);
    });

    testWidgets('tap-to-answer submits correct answer to KidsBloc with speech and haptic', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap on correct option 'Cold'
      final coldOption = find.text('Cold');
      expect(coldOption, findsOneWidget);

      await tester.tap(coldOption, warnIfMissed: false);
      await tester.pump();

      // Verify answer submission
      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);

      // Verify TTS pronounced 'Cold'
      verify(() => mockTTSService.speak('Cold', force: true)).called(1);

      // Verify success haptic fired
      verify(() => mockHapticService.success()).called(1);
    });

    testWidgets('tap-to-answer submits incorrect answer with error speech and haptic', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap on wrong option 'Wet'
      final wetOption = find.text('Wet');
      expect(wetOption, findsOneWidget);

      await tester.tap(wetOption, warnIfMissed: false);
      await tester.pump();

      // Verify incorrect answer submission
      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(false))).called(1);

      // Verify TTS pronounced 'Wet'
      verify(() => mockTTSService.speak('Wet', force: true)).called(1);

      // Verify error haptic fired
      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('speaker button on plaque pronounces word without submitting answer', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Find speaker icons on plaques
      final speakerIcons = find.byIcon(Icons.volume_up_rounded);
      expect(speakerIcons, findsWidgets);

      // Tap the last speaker icon (which corresponds to 'Cold')
      await tester.tap(speakerIcons.last, warnIfMissed: false);
      await tester.pump();

      // Verify TTS pronounced 'Cold'
      verify(() => mockTTSService.speak('Cold', force: true)).called(1);

      // Verify no answer event was dispatched to KidsBloc
      verifyNever(() => mockKidsBloc.add(any(that: isA<SubmitKidsAnswer>())));
    });

    testWidgets('tapping premise realm replays instruction audio', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap the Premise Realm (e.g. text 'HOT')
      final premiseFinder = find.text('HOT');
      await tester.tap(premiseFinder, warnIfMissed: false);
      await tester.pump();

      // Verify instruction was replayed via TTS
      verify(() => mockTTSService.speak('Which word is the opposite of “hot”?', force: true)).called(1);
    });

    testWidgets('drag-and-drop correct option plaque onto opposite drop target submits answer', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final coldDraggable = find.byWidgetPredicate(
        (widget) => widget is Draggable<String> && widget.data == 'Cold',
      );
      expect(coldDraggable, findsOneWidget);

      final dropTarget = find.byType(DragTarget<String>);
      expect(dropTarget, findsOneWidget);

      // Drag plaque onto drop target
      await tester.drag(coldDraggable, const Offset(0, -260));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify correct answer submission
      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
    });

    testWidgets('unanswered state does not spoil answer emoji in drop target', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Celebratory answer emoji 🧊 should NOT be visible in unanswered state
      final solitaryEmoji = find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == '🧊' && (widget.style?.fontSize ?? 0) > 30,
      );
      expect(solitaryEmoji, findsNothing);
    });

    testWidgets('correct state reveals triumphant opposite with celebratory emoji', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final correctState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );

      await tester.pumpWidget(buildTestScreen(stateOverride: correctState));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Celebratory emoji 🧊 should now be visible
      final celebratoryEmoji = find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == '🧊' && (widget.style?.fontSize ?? 0) >= 30,
      );
      expect(celebratoryEmoji, findsOneWidget);

      // Matched indicator
      expect(find.text('Matched!'), findsOneWidget);
    });

    testWidgets('50/50 lifeline dissolves first distractor when hint is used', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final hintState = testLoadedState.copyWith(hintUsed: true);

      await tester.pumpWidget(buildTestScreen(stateOverride: hintState));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Distractor 'Wet' should be wrapped in AnimatedOpacity with opacity 0.0
      final wetWidget = find.byWidgetPredicate(
        (widget) => widget is AnimatedOpacity && widget.opacity == 0.0,
      );
      expect(wetWidget, findsOneWidget);
    });

    testWidgets('renders cleanly on compact 360x640 phone with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestScreen(screenSize: const Size(360, 640)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      expect(find.text('HOT'), findsOneWidget);
      expect(find.text('Cold'), findsOneWidget);
    });

    testWidgets('renders cleanly on large 430x932 phone with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestScreen(screenSize: const Size(430, 932)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      expect(find.text('HOT'), findsOneWidget);
      expect(find.text('Cold'), findsOneWidget);
    });

    testWidgets('renders long content without clipping or overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final longState = testLoadedState.copyWith(
        quests: [testQuestLong],
      );

      await tester.pumpWidget(buildTestScreen(stateOverride: longState));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      expect(find.text('Different'), findsOneWidget);
      expect(find.text('Matching'), findsOneWidget);
      expect(find.text('Dry'), findsOneWidget);
    });
  });
}
