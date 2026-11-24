import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/theme/app_theme.dart';
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
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/pages/prefix_suffix_learn_screen.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/pages/prefix_suffix_practice_screen.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/pages/prefix_suffix_screen.dart';

class MockVocabularyBloc extends MockBloc<VocabularyEvent, VocabularyState>
    implements VocabularyBloc {}

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

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockVocabularyBloc mockVocabularyBloc;
  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;
  late MockTtsService mockTtsService;
  late MockLocaleService mockLocaleService;
  late MockAppLogger mockAppLogger;
  late MockAnalyticsService mockAnalyticsService;
  late MockAdService mockAdService;
  late MockNetworkInfo mockNetworkInfo;
  late StreamController<VocabularyState> vocabularyStreamController;

  final testQuest = VocabularyQuest(
    id: 'VOC_PS_L1_MASTERY_Q1',
    type: QuestType.vocabulary,
    subtype: GameSubtype.prefixSuffix,
    word: 'PREVIEW',
    rootWord: 'VIEW',
    prefix: 'PRE-',
    correctAnswer: 'PRE-',
    options: const ['PRE-', 'RE-', 'UN-', 'DE-'],
    correctAnswerIndex: 0,
    instruction: 'SLICE OFF THE PREFIX: PRE-',
    definition: 'An early viewing before public release',
    contextSentence: 'We watched the movie preview before the film began.',
    explanation: 'PRE- combines with VIEW to form PREVIEW.',
    meaningBreakdown: 'PRE- (Before) + VIEW ➔ PREVIEW',
    difficulty: 1,
  );

  final testLoadedState = VocabularyLoaded(
    quests: [testQuest],
    currentIndex: 0,
    livesRemaining: 3,
    wrongCount: 0,
    hintUsed: false,
    answerStatus: AnswerStatus.unanswered,
  );

  setUpAll(() {
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockVocabularyBloc = MockVocabularyBloc();
    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    mockTtsService = MockTtsService();
    mockLocaleService = MockLocaleService();
    mockAppLogger = MockAppLogger();
    mockAnalyticsService = MockAnalyticsService();
    mockAdService = MockAdService();
    mockNetworkInfo = MockNetworkInfo();

    vocabularyStreamController = StreamController<VocabularyState>.broadcast();

    when(() => mockVocabularyBloc.state).thenReturn(testLoadedState);
    when(
      () => mockVocabularyBloc.stream,
    ).thenAnswer((_) => vocabularyStreamController.stream);

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(id: 'u1', email: 't@v.c', displayName: 'Test'),
      ),
    );
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockEconomyBloc.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});

    when(
      () => mockSoundService.playCorrect(comboStep: any(named: 'comboStep')),
    ).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.stopAudio()).thenAnswer((_) async {});
    when(() => mockSoundService.playLevelComplete()).thenAnswer((_) async {});

    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(
      () => mockTtsService.speak(
        any(),
        rate: any(named: 'rate'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async {});

    when(() => mockLocaleService.currentLocale).thenReturn(const Locale('en'));

    await di.sl.reset();
    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<AppLogger>(mockAppLogger);
    di.sl.registerSingleton<AnalyticsService>(mockAnalyticsService);
    di.sl.registerSingleton<AdService>(mockAdService);
    di.sl.registerSingleton<NetworkInfo>(mockNetworkInfo);
  });

  tearDown(() async {
    await vocabularyStreamController.close();
  });

  Widget buildTestableWidget(Widget child, Size size) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MultiBlocProvider(
        providers: [
          BlocProvider<VocabularyBloc>.value(value: mockVocabularyBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: MediaQuery(
            data: MediaQueryData(size: size, disableAnimations: true),
            child: child,
          ),
        ),
      ),
    );
  }

  final testViewports = [
    const Size(320, 640), // Small phone
    const Size(360, 800), // Standard Android
    const Size(430, 932), // Large phone / Phablet
  ];

  group('PrefixSuffix Layout Multi-Screen Verification', () {
    for (final size in testViewports) {
      testWidgets(
        'Mastery screen renders with zero overflows at ${size.width}x${size.height}',
        (tester) async {
          tester.view.physicalSize = size * 2.0;
          tester.view.devicePixelRatio = 2.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            buildTestableWidget(
              const PrefixSuffixScreen(level: 1, enableTimer: false),
              size,
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(find.byType(PrefixSuffixScreen), findsOneWidget);

          await tester.pumpWidget(const SizedBox());
        },
      );

      testWidgets(
        'Practice screen renders with zero overflows at ${size.width}x${size.height}',
        (tester) async {
          tester.view.physicalSize = size * 2.0;
          tester.view.devicePixelRatio = 2.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            buildTestableWidget(
              const PrefixSuffixPracticeScreen(level: 1),
              size,
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(find.byType(PrefixSuffixPracticeScreen), findsOneWidget);

          await tester.pumpWidget(const SizedBox());
        },
      );

      testWidgets(
        'Learn screen renders with zero overflows at ${size.width}x${size.height}',
        (tester) async {
          tester.view.physicalSize = size * 2.0;
          tester.view.devicePixelRatio = 2.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            buildTestableWidget(const PrefixSuffixLearnScreen(level: 1), size),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(find.byType(PrefixSuffixLearnScreen), findsOneWidget);

          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  });
}
