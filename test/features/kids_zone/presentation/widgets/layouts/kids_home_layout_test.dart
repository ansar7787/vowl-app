import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/layouts/kids_home_layout.dart';

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

  const testQuest = KidsQuest(
    id: 'KIDS_HOME_KIDS_L1_Q1',
    gameType: 'home',
    level: 1,
    instruction: 'What is a home?',
    question: '?',
    correctAnswer: 'A place to live and rest 🏠',
    options: [
      'A place to shop for food 🛒',
      'A place to live and rest 🏠',
      'A place to borrow books 📚',
    ],
    hint: 'Which of these is somewhere you come back to every day?',
    emoji: '🏠',
    explanation: 'A home is where people live and rest.',
    funFact: 'Homes can be big or small.',
  );

  const testLoadedState = KidsLoaded(
    quests: [testQuest],
    originalTotalQuests: 1,
    gameType: 'home',
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

    when(() => mockTTSService.isNarrationEnabled())
        .thenAnswer((_) async => true);
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
      if (key == 'games.kids_home_action_hint') {
        return 'Choose an answer or drag it to the house.';
      }
      if (key == 'games.kids_home_drop_here') {
        return 'Drop here';
      }
      if (key == 'games.kids_home_tap_or_drag') {
        return 'Drop answer here';
      }
      return key;
    });

    // Register mocks in service locator safely
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
          home: const KidsHomeLayout(
            level: 2,
            title: 'Home',
            primaryColor: Color(0xFFCA8A04),
          ),
        ),
      ),
    );
  }

  group('KidsHomeLayout Production Tests', () {
    testWidgets('renders dollhouse, instruction, and all options fully with no truncation', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify all options are visible and legible
      expect(find.text('A place to shop for food 🛒'), findsOneWidget);
      expect(find.text('A place to live and rest 🏠'), findsOneWidget);
      expect(find.text('A place to borrow books 📚'), findsOneWidget);

      // Verify action hint subtitle is present
      expect(
        find.text('Choose an answer or drag it to the house.'),
        findsOneWidget,
      );

      // Verify dollhouse drop zone is present
      expect(find.text('Drop answer here'), findsOneWidget);
    });

    testWidgets('tap-to-answer submits correct answer to KidsBloc', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap on the correct answer card
      final correctCard = find.text('A place to live and rest 🏠');
      expect(correctCard, findsOneWidget);

      await tester.tap(correctCard);
      await tester.pump();

      // Verify SubmitKidsAnswer(true) was dispatched
      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
    });

    testWidgets('tap-to-answer submits incorrect answer and speaks pronunciation', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap on the wrong answer card
      final wrongCard = find.text('A place to shop for food 🛒');
      expect(wrongCard, findsOneWidget);

      await tester.tap(wrongCard);
      await tester.pump();

      // Verify SubmitKidsAnswer(false) was dispatched
      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(false))).called(1);

      // Verify TTS pronounced the wrong card text
      verify(() => mockTTSService.speak('A place to shop for food 🛒')).called(1);
    });

    testWidgets('option audio speaker button plays option pronunciation via TTS without submitting answer', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Find speaker icons on option cards
      final speakerIcons = find.byIcon(Icons.volume_up_rounded);
      expect(speakerIcons, findsWidgets);

      // Tap speaker on the third option
      await tester.tap(speakerIcons.last);
      await tester.pump();

      // Verify TTS spoke the option
      verify(() => mockTTSService.speak('A place to borrow books 📚', force: any(named: 'force'))).called(1);

      // Verify no answer was submitted
      verifyNever(() => mockKidsBloc.add(any(that: isA<SubmitKidsAnswer>())));
    });

    testWidgets('tapping dollhouse replays question instruction via TTS', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap the dollhouse drop target
      final dollhouseFinder = find.byType(DragTarget<String>);
      expect(dollhouseFinder, findsOneWidget);

      await tester.tap(dollhouseFinder);
      await tester.pump();

      // Verify TTS spoke the instruction
      verify(() => mockTTSService.speak('What is a home?', force: any(named: 'force'))).called(1);
    });

    testWidgets('drag-and-drop correct option onto dollhouse target submits answer', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final correctDraggable = find.byWidgetPredicate(
        (widget) =>
            widget is Draggable<String> &&
            widget.data == 'A place to live and rest 🏠',
      );
      expect(correctDraggable, findsOneWidget);

      final dropTarget = find.byType(DragTarget<String>);
      expect(dropTarget, findsOneWidget);

      // Drag option into the dollhouse drop target
      await tester.drag(correctDraggable, const Offset(0, -280));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify SubmitKidsAnswer(true) was dispatched
      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
    });

    testWidgets('unanswered state does not spoil answer emoji silhouette', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // The answer emoji "🏠" should NOT be visible in the house in unanswered state
      // (It only appears in the option text "A place to live and rest 🏠")
      final solitaryEmojiFinder = find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == '🏠' && (widget.style?.fontSize ?? 0) > 30,
      );
      expect(solitaryEmojiFinder, findsNothing);
    });

    testWidgets('correct state reveals triumphant celebration with answer emoji inside the house', (tester) async {
      final correctState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );

      await tester.pumpWidget(buildTestScreen(stateOverride: correctState));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Triumphant emoji should now be visible inside the dollhouse
      final celebratoryEmoji = find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == '🏠' && (widget.style?.fontSize ?? 0) >= 35,
      );
      expect(celebratoryEmoji, findsOneWidget);
    });

    testWidgets('renders cleanly on compact 360x640 phone without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Must not throw any RenderFlex overflow exceptions
      expect(tester.takeException(), isNull);
      expect(find.text('A place to live and rest 🏠'), findsOneWidget);

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
      expect(find.text('A place to live and rest 🏠'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}

