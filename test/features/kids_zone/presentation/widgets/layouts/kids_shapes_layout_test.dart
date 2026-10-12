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
import 'package:vowl/features/kids_zone/presentation/widgets/layouts/kids_shapes_layout.dart';

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
    id: 'KIDS_SHAPES_L1_Q1',
    gameType: 'shapes',
    level: 2,
    instruction: 'Which shape matches a big round pizza fresh out of the oven?',
    question: '?',
    correctAnswer: 'Circle',
    options: [
      'Circle',
      'Triangle',
      'Square',
    ],
    hint: 'Think of something round that has no corners at all.',
    emoji: '🍕',
    explanation: 'A pizza is round all over with no straight edges, just like a circle!',
    funFact: 'A circle is perfectly round, so every point on its edge is the same distance from the middle.',
    metadata: {'subtype': 'basic_2d_shapes'},
  );

  const testBatch20Quest = KidsQuest(
    id: 'KIDS_SHAPES_L191_Q3',
    gameType: 'shapes',
    level: 191,
    instruction:
        'Which shape is the simplest possible polygon, has the fewest lines of symmetry among the regular polygons in this game, and is also used to build both pyramids and hexagons?',
    question: '?',
    correctAnswer: 'Triangle',
    options: [
      'Triangle',
      'Pentagon',
      'Rectangular Prism',
    ],
    hint: 'Think of a shape with three sides.',
    emoji: '📐',
    explanation: 'A triangle is the simplest polygon with three sides.',
    funFact: 'Triangles are structural wonders in architecture.',
    metadata: {'subtype': 'advanced_shape_reasoning'},
  );

  const testLoadedState = KidsLoaded(
    quests: [testQuest],
    originalTotalQuests: 1,
    gameType: 'shapes',
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
    when(() => mockKidsBloc.stream).thenAnswer(
      (_) => const Stream<KidsState>.empty(),
    );

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
    when(() => mockAuthBloc.stream).thenAnswer(
      (_) => const Stream<AuthState>.empty(),
    );

    when(() => mockTTSService.speak(any(), force: any(named: 'force')))
        .thenAnswer((_) async => true);
    when(() => mockTTSService.isNarrationEnabled()).thenAnswer((_) async => false);
    when(() => mockTTSService.stop()).thenAnswer((_) async {});

    when(() => mockAudioService.playLevelCompleteSFX()).thenAnswer((_) async {});

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});

    when(() => mockLogger.debug(any(), tag: any(named: 'tag'))).thenReturn(null);
    when(() => mockLogger.warning(any(), tag: any(named: 'tag'))).thenReturn(null);
    when(() => mockLogger.error(
          any(),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
          tag: any(named: 'tag'),
        )).thenReturn(null);

    when(() => mockLocaleService.tr(any())).thenAnswer(
      (inv) => inv.positionalArguments[0] as String,
    );

    if (di.sl.isRegistered<KidsTTSService>()) {
      di.sl.unregister<KidsTTSService>();
    }
    if (di.sl.isRegistered<KidsAudioService>()) {
      di.sl.unregister<KidsAudioService>();
    }
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<AppLogger>()) {
      di.sl.unregister<AppLogger>();
    }
    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }

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
          home: const KidsShapesLayout(
            level: 2,
            title: 'Shapes',
            primaryColor: Color(0xFF10B981),
          ),
        ),
      ),
    );
  }

  Future<void> pumpShapesScreen(
    WidgetTester tester, {
    Size? customSize,
    KidsState? stateOverride,
  }) async {
    final size = customSize ?? const Size(390, 844);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(buildTestScreen(stateOverride: stateOverride));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  }

  group('KidsShapesLayout Production Tests', () {
    testWidgets(
      'renders blueprint crane, clue banner, prompt, and all options fully with no truncation',
      (tester) async {
        await pumpShapesScreen(tester);

        // 1. Clue Text on Banner
        expect(
          find.text('Which shape matches a big round pizza fresh out of the oven?'),
          findsAtLeastNWidgets(1),
        );

        // 2. Action Guidance
        expect(
          find.text('Tap or drag the matching shape block'),
          findsOneWidget,
        );

        // 3. Object Emoji on Blueprint
        expect(find.text('🍕'), findsOneWidget);

        // 4. All Options Visible
        expect(find.text('Circle'), findsOneWidget);
        expect(find.text('Triangle'), findsOneWidget);
        expect(find.text('Square'), findsOneWidget);

        // 5. Geometric Shape Symbols on Blocks
        expect(find.text('●'), findsOneWidget);
        expect(find.text('▲'), findsOneWidget);
        expect(find.text('■'), findsOneWidget);

        // 6. Blueprint Drag Target exists
        expect(find.byType(DragTarget<String>), findsOneWidget);
      },
    );

    testWidgets('tap-to-answer submits correct answer to KidsBloc', (
      tester,
    ) async {
      await pumpShapesScreen(tester);

      final circleBlock = find.byKey(const Key('toy_block_Circle'));
      expect(circleBlock, findsOneWidget);

      await tester.tap(circleBlock);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
      verify(() => mockHapticService.success()).called(1);
    });

    testWidgets(
      'tap-to-answer submits incorrect answer and speaks pronunciation',
      (tester) async {
        await pumpShapesScreen(tester);

        final triangleBlock = find.byKey(const Key('toy_block_Triangle'));
        expect(triangleBlock, findsOneWidget);

        await tester.tap(triangleBlock);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        verify(() => mockKidsBloc.add(const SubmitKidsAnswer(false))).called(1);
        verify(() => mockHapticService.error()).called(1);
        verify(() => mockTTSService.speak('Triangle')).called(1);
      },
    );

    testWidgets(
      'option audio speaker button plays option pronunciation via TTS without submitting answer',
      (tester) async {
        await pumpShapesScreen(tester);

        // Find speaker icons
        final speakerIcons = find.byIcon(Icons.volume_up_rounded);
        // At least: 1 in blueprint header, 1 in clue banner, 3 on blocks
        expect(speakerIcons, findsAtLeastNWidgets(4));

        // Tap the last block speaker (Square)
        await tester.tap(speakerIcons.last);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        verify(() => mockTTSService.speak('Square', force: true)).called(1);
        verify(() => mockHapticService.selection()).called(1);
        // Verify SubmitKidsAnswer was NOT submitted
        verifyNever(
          () => mockKidsBloc.add(any(that: isA<SubmitKidsAnswer>())),
        );
      },
    );

    testWidgets(
      'tapping clue banner or blueprint replays question instruction via TTS',
      (tester) async {
        await pumpShapesScreen(tester);

        final clueBanner = find.byKey(const Key('kids_shapes_clue_banner'));
        expect(clueBanner, findsOneWidget);

        await tester.tap(clueBanner);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        verify(
          () => mockTTSService.speak(
            'Which shape matches a big round pizza fresh out of the oven?',
            force: true,
          ),
        ).called(1);
        verify(() => mockHapticService.selection()).called(1);
      },
    );

    testWidgets(
      'drag-and-drop correct option onto blueprint target submits answer',
      (tester) async {
        await pumpShapesScreen(tester);

        final circleDraggable = find.byWidgetPredicate(
          (widget) => widget is Draggable<String> && widget.data == 'Circle',
        );
        final blueprintTarget = find.byType(DragTarget<String>);

        expect(circleDraggable, findsOneWidget);
        expect(blueprintTarget, findsOneWidget);

        // Perform drag and drop gesture
        final gesture = await tester.startGesture(tester.getCenter(circleDraggable));
        await tester.pump(const Duration(milliseconds: 100));

        await gesture.moveTo(tester.getCenter(blueprintTarget));
        await tester.pump(const Duration(milliseconds: 100));

        await gesture.up();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
      },
    );

    testWidgets(
      'correct state reveals triumphant celebration with checkmark inside blueprint',
      (tester) async {
        final answeredCorrectState = testLoadedState.copyWith(
          answerStatus: AnswerStatus.correct,
        );

        await pumpShapesScreen(tester, stateOverride: answeredCorrectState);

        expect(find.text('✨ Nice Match! ✨'), findsOneWidget);
        expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'already answered state disables re-submitting upon taps',
      (tester) async {
        final answeredState = testLoadedState.copyWith(
          answerStatus: AnswerStatus.correct,
        );

        await pumpShapesScreen(tester, stateOverride: answeredState);

        // Blocks are no longer wrapped in interactive Draggables
        expect(find.byType(Draggable<String>), findsNothing);

        // Tapping the block text does nothing
        await tester.tap(find.text('Circle'), warnIfMissed: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        verifyNever(
          () => mockKidsBloc.add(any(that: isA<SubmitKidsAnswer>())),
        );
      },
    );

    testWidgets(
      'renders cleanly on compact 360x640 phone without overflow',
      (tester) async {
        await pumpShapesScreen(tester, customSize: const Size(360, 640));

        expect(tester.takeException(), isNull);
        expect(find.text('Circle'), findsOneWidget);
        expect(find.text('Triangle'), findsOneWidget);
        expect(find.text('Square'), findsOneWidget);
      },
    );

    testWidgets(
      'renders cleanly on large 430x932 phone without overflow',
      (tester) async {
        await pumpShapesScreen(tester, customSize: const Size(430, 932));

        expect(tester.takeException(), isNull);
        expect(find.text('Circle'), findsOneWidget);
        expect(find.text('Triangle'), findsOneWidget);
        expect(find.text('Square'), findsOneWidget);
      },
    );

    testWidgets(
      'renders cleanly on ultra-narrow 320x568 phone without overflow',
      (tester) async {
        await pumpShapesScreen(tester, customSize: const Size(320, 568));

        expect(tester.takeException(), isNull);
        expect(find.text('Circle'), findsOneWidget);
        expect(find.text('Triangle'), findsOneWidget);
        expect(find.text('Square'), findsOneWidget);
      },
    );

    testWidgets(
      'Batch 20 advanced quest with long instruction and Rectangular Prism renders cleanly',
      (tester) async {
        final advancedState = testLoadedState.copyWith(
          quests: [testBatch20Quest],
        );

        await pumpShapesScreen(tester, stateOverride: advancedState);

        expect(tester.takeException(), isNull);
        expect(
          find.text(
            'Which shape is the simplest possible polygon, has the fewest lines of symmetry among the regular polygons in this game, and is also used to build both pyramids and hexagons?',
          ),
          findsAtLeastNWidgets(1),
        );
        expect(find.text('Triangle'), findsOneWidget);
        expect(find.text('Pentagon'), findsOneWidget);
        expect(find.text('Rectangular Prism'), findsOneWidget);
        expect(find.text('📦'), findsOneWidget); // 3D symbol for rectangular prism
      },
    );

    testWidgets(
      'ShapeOptionData.parse extracts geometric symbols and flags 3D shapes correctly',
      (tester) async {
      final circle = ShapeOptionData.parse('Circle');
      expect(circle.title, 'Circle');
      expect(circle.shapeSymbol, '●');
      expect(circle.is3D, isFalse);

      final triangle = ShapeOptionData.parse('Triangle');
      expect(triangle.shapeSymbol, '▲');

      final prism = ShapeOptionData.parse('Rectangular Prism');
      expect(prism.title, 'Rectangular Prism');
      expect(prism.shapeSymbol, '📦');
      expect(prism.is3D, isTrue);

      final cube = ShapeOptionData.parse('Cube');
      expect(cube.shapeSymbol, '🎲');
      expect(cube.is3D, isTrue);
    });

    testWidgets(
      'GameInstructionService returns authentic Shapes briefing matching crane mechanics',
      (tester) async {
        await pumpShapesScreen(tester);

        final BuildContext context = tester.element(find.byType(KidsShapesLayout));
        final briefing = GameInstructionService.getBriefing(
          context,
          null,
          'Shapes',
          level: 1,
        );

        expect(briefing.title, 'Shapes');
        expect(briefing.actionText, 'Start Playing');
        expect(briefing.rules.length, 3);
        expect(briefing.rules.any((r) => r.contains('shape clue')), isTrue);
        expect(briefing.rules.any((r) => r.contains('matching shape block')), isTrue);
        expect(briefing.tip.contains('PRO TIP:'), isFalse);
        expect(briefing.tip.contains('Tip: Count the sides and corners'), isTrue);
      },
    );

    test('StoryService contains authentic milestone beats for Shapes from Level 1 to 200', () {
      final shapesScripts = StoryServiceImpl.kidsScripts['shapes'];
      expect(shapesScripts, isNotNull);
      expect(shapesScripts!.length, 6);

      // Verify Level 1 (Beat 0)
      expect(shapesScripts[0], contains('Circles, squares, and triangles!'));
      expect(shapesScripts[0], contains('explore shapes all around us'));

      // Verify Level 10 (Beat 1)
      expect(shapesScripts[1], contains('first 10 levels'));
      expect(shapesScripts[1], contains('straight sides, round curves, and corners'));

      // Verify Level 20 (Beat 2)
      expect(shapesScripts[2], contains('Twenty levels complete!'));

      // Verify Level 50 (Beat 3)
      expect(shapesScripts[3], contains('Fifty levels done!'));
      expect(shapesScripts[3], contains('2D shapes to solid 3D cubes'));

      // Verify Level 100 (Beat 4)
      expect(shapesScripts[4], contains('One hundred levels of shapes!'));
      expect(shapesScripts[4], contains('how shapes connect, stack, and fit'));

      // Verify Level 200 (Beat 5)
      expect(shapesScripts[5], contains('Two hundred levels completed!'));
      expect(shapesScripts[5], contains('sharp eye for every pattern and form'));

      // Verify no robotic buzzwords or fantasy personas exist in any beat
      for (final beat in shapesScripts) {
        expect(beat.contains('PRO TIP'), isFalse);
        expect(beat.contains('Geometry Genius'), isFalse);
        expect(beat.contains('Shape Shifter'), isFalse);
        expect(beat.contains('Grand Architect'), isFalse);
        expect(beat.contains('Master of Forms'), isFalse);
        expect(beat.contains('Shape Kingdom'), isFalse);
      }
    });

    testWidgets('Accessibility Semantics labels are properly configured for screen readers', (tester) async {
      await pumpShapesScreen(tester);

      // Verify clue banner semantics
      expect(
        find.byWidgetPredicate((w) =>
            w is Semantics &&
            w.properties.label != null &&
            w.properties.label!.contains('Shape clue:')),
        findsOneWidget,
      );

      // Verify toy block semantics
      expect(
        find.byWidgetPredicate((w) =>
            w is Semantics &&
            w.properties.label != null &&
            w.properties.label!.contains('Circle shape block')),
        findsOneWidget,
      );

      // Verify pronunciation button semantics
      expect(
        find.byWidgetPredicate((w) =>
            w is Semantics &&
            w.properties.label != null &&
            w.properties.label!.contains('Hear pronunciation for Circle')),
        findsOneWidget,
      );
    });
  });
}
