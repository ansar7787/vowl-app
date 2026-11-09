import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/home/presentation/widgets/daily_mystery_chest_card.dart';

class MockHapticService extends Mock implements HapticService {}

class MockSoundService extends Mock implements SoundService {}

class MockLocaleService extends Mock implements LocaleService {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockEconomyBloc extends MockBloc<EconomyEvent, EconomyState>
    implements EconomyBloc {}

class FakeEconomyEvent extends Fake implements EconomyEvent {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeEconomyEvent());
  });

  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;
  late MockLocaleService mockLocaleService;
  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;

  final testUser = UserEntity(
    id: 'user_123',
    email: 'learner@vowl.app',
    displayName: 'Aria',
    currentStreak: 7,
    coins: 150,
    totalExp: 1200,
    badges: const ['first_win'],
    completedLevels: const {
      'vocabulary': [1, 2],
    },
    isPremium: false,
    hasClaimedReferral: false,
  );

  setUp(() {
    VowlMotion.lowAnimationModeOverride.value = true;
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    mockLocaleService = MockLocaleService();
    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();

    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(
      () => mockSoundService.playCoinTally(count: any(named: 'count')),
    ).thenAnswer((_) async {});

    when(() => mockLocaleService.currentLocale).thenReturn(const Locale('en'));
    when(
      () => mockLocaleService.tr(
        any(),
        fallback: any(named: 'fallback'),
        args: any(named: 'args'),
      ),
    ).thenAnswer((inv) {
      final fallback = inv.namedArguments[#fallback] as String?;
      final args = inv.namedArguments[#args] as List<String>?;
      if (fallback != null && args != null && args.isNotEmpty) {
        var res = fallback;
        for (final arg in args) {
          res = res.replaceFirst('{}', arg);
        }
        return res;
      }
      return fallback ?? (inv.positionalArguments.first as String);
    });

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    di.sl.registerSingleton<HapticService>(mockHapticService);

    if (di.sl.isRegistered<SoundService>()) {
      di.sl.unregister<SoundService>();
    }
    di.sl.registerSingleton<SoundService>(mockSoundService);

    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    initLocaleServiceReference(mockLocaleService);

    whenListen(
      mockAuthBloc,
      Stream.value(AuthState.authenticated(testUser)),
      initialState: AuthState.authenticated(testUser),
    );

    whenListen(
      mockEconomyBloc,
      Stream.value(const EconomyState(isDailyRewardAvailable: true)),
      initialState: const EconomyState(isDailyRewardAvailable: true),
    );

    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<SoundService>()) {
      di.sl.unregister<SoundService>();
    }
    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
  });

  Widget createSubject({
    ThemeMode themeMode = ThemeMode.dark,
    double width = 393,
    double height = 852,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
      ],
      child: ScreenUtilInit(
        designSize: const Size(393, 852),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => MaterialApp(
          themeMode: themeMode,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                height: height,
                child: const DailyMysteryChestCard(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pumpCard(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.dark,
    double width = 393,
    double height = 852,
  }) async {
    tester.view.physicalSize = Size(width * 2.0, height * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      createSubject(themeMode: themeMode, width: width, height: height),
    );
  }

  testWidgets('renders nothing when isDailyRewardAvailable is false', (
    tester,
  ) async {
    whenListen(
      mockEconomyBloc,
      Stream.value(const EconomyState(isDailyRewardAvailable: false)),
      initialState: const EconomyState(isDailyRewardAvailable: false),
    );

    await pumpCard(tester);
    await tester.pump();

    expect(find.byType(DailyMysteryChestCard), findsOneWidget);
    expect(find.text('DAILY MYSTERY'), findsNothing);
  });

  testWidgets(
    'renders card with vector gift icon and sparkles when available',
    (tester) async {
      await pumpCard(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(DailyMysteryChestCard), findsOneWidget);
      expect(find.text('DAILY MYSTERY'), findsOneWidget);
      expect(find.text('TAP TO UNVEIL'), findsOneWidget);
      expect(find.text('CLAIM'), findsOneWidget);
      expect(find.byIcon(LucideIcons.gift), findsOneWidget);
      expect(find.byIcon(LucideIcons.sparkles), findsOneWidget);
    },
  );

  testWidgets('hides card when user already claimed today in SharedPreferences', (
    tester,
  ) async {
    final now = DateTime.now().toLocal();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    SharedPreferences.setMockInitialValues({
      'last_daily_mystery_claimed_date_user_123': todayStr,
    });

    await pumpCard(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('DAILY MYSTERY'), findsNothing);
  });

  testWidgets(
    'tapping CLAIM triggers audio, haptic, bloc dispatch, and collapse animation',
    (tester) async {
      await pumpCard(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('CLAIM'), findsOneWidget);

      await tester.tap(find.text('CLAIM'));
      await tester.pump();

      // Verify immediate celebration effects
      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCoinTally(count: 8)).called(1);

      // Verify EconomyBloc received the claim event
      verify(
        () => mockEconomyBloc.add(
          any(that: isA<EconomyClaimDailyChestRequested>()),
        ),
      ).called(1);

      // Verify victory text displays
      expect(find.text('COINS COLLECTED'), findsOneWidget);

      // Advance through victory delay (650ms) and collapse animation (380ms)
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Card is smoothly collapsed to 0dp / SizedBox.shrink()
      expect(find.text('DAILY MYSTERY'), findsNothing);
    },
  );

  testWidgets(
    'renders safely on small 320x568 mobile viewport without overflow',
    (tester) async {
      await pumpCard(tester, width: 320, height: 568);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(DailyMysteryChestCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('renders cleanly in Light Mode without errors', (tester) async {
    await pumpCard(tester, themeMode: ThemeMode.light);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(DailyMysteryChestCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
