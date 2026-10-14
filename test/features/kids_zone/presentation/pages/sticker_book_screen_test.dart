import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/profile_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/pages/sticker_book_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}
class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState> implements ProfileBloc {}
class MockHapticService extends Mock implements HapticService {}
class MockLocaleService extends Mock implements LocaleService {}
class MockSoundService extends Mock implements SoundService {}

class FakeBuildContext extends Fake implements BuildContext {}
class FakeProfileEvent extends Fake implements ProfileEvent {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeBuildContext());
    registerFallbackValue(FakeProfileEvent());

    // Mock platform channel for haptic_feedback to prevent MissingPluginException
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('haptic_feedback'),
      (MethodCall methodCall) async => true,
    );
  });

  late MockAuthBloc mockAuthBloc;
  late MockProfileBloc mockProfileBloc;
  late MockHapticService mockHapticService;
  late MockLocaleService mockLocaleService;
  late MockSoundService mockSoundService;

  final testUser = UserEntity(
    id: 'kid_stickers_123',
    email: 'kid@vowl.app',
    displayName: 'Sticker Collector',
    totalExp: 800,
    currentStreak: 7,
    kidsCoins: 400,
    kidsMascot: 'owly',
    kidsStickers: const [
      'sticker_alphabet', // level 10 alphabet (COMMON)
      'alphabet_sticker_50', // level 50 alphabet (RARE)
      'alphabet_sticker_100', // level 100 alphabet (EPIC)
      'alphabet_sticker_200', // level 200 alphabet (LEGENDARY)
      'sticker_numbers', // level 10 numbers
    ],
    kidsEquippedSticker: 'sticker_alphabet',
  );

  setUp(() async {
    VowlMotion.lowAnimationModeOverride.value = true;
    SharedPreferences.setMockInitialValues({});
    await di.sl.reset();

    mockAuthBloc = MockAuthBloc();
    mockProfileBloc = MockProfileBloc();
    mockHapticService = MockHapticService();
    mockLocaleService = MockLocaleService();
    mockSoundService = MockSoundService();

    when(() => mockLocaleService.currentLocale).thenReturn(const Locale('en'));
    when(
      () => mockLocaleService.tr(
        any(),
        fallback: any(named: 'fallback'),
        args: any(named: 'args'),
      ),
    ).thenAnswer(
      (inv) {
        final fallback = inv.namedArguments[#fallback] as String?;
        final args = inv.namedArguments[#args] as List<dynamic>?;
        if (fallback != null) {
          if (args != null && args.isNotEmpty) {
            var res = fallback;
            for (var i = 0; i < args.length; i++) {
              res = res.replaceAll('{}', args[i].toString());
            }
            return res;
          }
          return fallback;
        }
        return inv.positionalArguments.first as String;
      },
    );

    when(() => mockSoundService.playClick()).thenAnswer((_) async {});
    when(() => mockHapticService.selection()).thenAnswer((_) async {});

    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
  });

  void configureViewport(WidgetTester tester, {Size size = const Size(600, 1400)}) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget buildWidget({
    UserEntity? user,
    ThemeMode themeMode = ThemeMode.light,
    Size screenSize = const Size(600, 1400),
    GoRouter? customRouter,
  }) {
    final activeUser = user ?? testUser;
    when(() => mockAuthBloc.state).thenReturn(AuthState.authenticated(activeUser));
    when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.value(AuthState.authenticated(activeUser)));

    when(() => mockProfileBloc.state).thenReturn(const ProfileState());
    when(() => mockProfileBloc.stream).thenAnswer((_) => const Stream.empty());

    final router = customRouter ??
        GoRouter(
          initialLocation: '/stickers',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const Scaffold(body: Text('Home Screen Root')),
            ),
            GoRoute(
              path: '/stickers',
              builder: (context, state) => const StickerBookScreen(),
            ),
          ],
        );

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, child) => MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<ProfileBloc>.value(value: mockProfileBloc),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: true,
              size: screenSize,
            ),
            child: child!,
          ),
        ),
      ),
    );
  }

  group('StickerBookScreen Tests', () {
    testWidgets('1. Renders StickerBookScreen with album header, stats, and tabs', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('STICKER ALBUM'), findsOneWidget);
      expect(find.text('5 / 100'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('2. Displays earned count badges on category tabs', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Alphabet has 4 stickers earned
      expect(find.text('4'), findsWidgets);
      // Numbers has 1 sticker earned
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('3. Renders rarity labels and equipped checkmark for unlocked stickers', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // In Alphabet tab (the first tab), we have 4 stickers:
      expect(find.text('COMMON'), findsOneWidget);
      expect(find.text('RARE'), findsOneWidget);
      expect(find.text('EPIC'), findsOneWidget);
      expect(find.text('LEGENDARY'), findsOneWidget);

      // Checkmark for equipped sticker (sticker_alphabet)
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('4. Tapping an equipped unlocked sticker unequips it via ProfileEquipStickerRequested(null)', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // The equipped sticker is COMMON (level 10)
      final commonLabel = find.text('COMMON');
      expect(commonLabel, findsOneWidget);

      await tester.tap(commonLabel);
      await tester.pump();

      verify(() => mockProfileBloc.add(any(that: isA<ProfileEquipStickerRequested>().having(
        (e) => e.stickerId,
        'stickerId',
        isNull,
      )))).called(1);
    });

    testWidgets('5. Tapping an unequipped unlocked sticker equips it via ProfileEquipStickerRequested(id)', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // RARE sticker is alphabet_sticker_50, which is unequipped
      final rareLabel = find.text('RARE');
      expect(rareLabel, findsOneWidget);

      await tester.tap(rareLabel);
      await tester.pump();

      verify(() => mockProfileBloc.add(any(that: isA<ProfileEquipStickerRequested>().having(
        (e) => e.stickerId,
        'stickerId',
        'alphabet_sticker_50',
      )))).called(1);
    });

    testWidgets('6. Tapping a locked sticker shows a locked quest snackbar warning', (tester) async {
      configureViewport(tester);
      // User with no numbers stickers beyond level 10
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Switch to NUMBERS tab
      final numbersTab = find.textContaining('NUMBERS');
      await tester.ensureVisible(numbersTab);
      await tester.tap(numbersTab);
      await tester.pumpAndSettle();

      // In numbers, level 50, 100, 200 are locked
      final lockedLevelBadge = find.text('LVL 50');
      expect(lockedLevelBadge, findsOneWidget);

      await tester.tap(lockedLevelBadge);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Complete 50 quests'), findsOneWidget);
    });

    testWidgets('7. Tapping back button pops back to root screen', (tester) async {
      configureViewport(tester);
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: Text('Home Screen Root')),
          ),
          GoRoute(
            path: '/stickers',
            builder: (context, state) => const StickerBookScreen(),
          ),
        ],
      );

      await tester.pumpWidget(buildWidget(customRouter: router));
      await tester.pumpAndSettle();
      expect(find.text('Home Screen Root'), findsOneWidget);

      router.push('/stickers');
      await tester.pumpAndSettle();
      expect(find.text('STICKER ALBUM'), findsOneWidget);

      final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backBtn, findsOneWidget);

      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(find.text('Home Screen Root'), findsOneWidget);
    });

    testWidgets('8. Renders cleanly in dark theme mode', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildWidget(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      expect(find.text('STICKER ALBUM'), findsOneWidget);
      expect(find.text('COMMON'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('9. Renders on compact 320dp screen without overflow', (tester) async {
      configureViewport(tester, size: const Size(320, 700));
      await tester.pumpWidget(buildWidget(
        screenSize: const Size(320, 700),
      ));
      await tester.pumpAndSettle();

      expect(find.text('STICKER ALBUM'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

