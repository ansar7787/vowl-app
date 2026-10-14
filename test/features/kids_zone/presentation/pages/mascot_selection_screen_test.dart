import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
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
import 'package:vowl/features/kids_zone/presentation/pages/mascot_selection_screen.dart';

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
  });

  late MockAuthBloc mockAuthBloc;
  late MockProfileBloc mockProfileBloc;
  late MockHapticService mockHapticService;
  late MockLocaleService mockLocaleService;
  late MockSoundService mockSoundService;

  final testUser = UserEntity(
    id: 'kid_test_123',
    email: 'kid@vowl.app',
    displayName: 'Buddy Champion',
    totalExp: 500,
    currentStreak: 4,
    kidsCoins: 250,
    kidsMascot: 'owly',
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
    when(() => mockSoundService.playMascotInteraction()).thenAnswer((_) async {});
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
          initialLocation: '/mascot',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const Scaffold(body: Text('Home Screen Root')),
            ),
            GoRoute(
              path: '/mascot',
              builder: (context, state) => const MascotSelectionScreen(),
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

  group('MascotSelectionScreen Tests', () {
    testWidgets('1. Renders MascotSelectionScreen with title, subtitle, and all 3 mascots', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Choose Your Buddy!'), findsOneWidget);
      expect(find.text('Which friend will join your quest?'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      expect(find.text('Owly'), findsOneWidget);
      expect(find.text('Wise and Helpful'), findsOneWidget);

      expect(find.text('Foxie'), findsOneWidget);
      expect(find.text('Playful and Fast'), findsOneWidget);

      expect(find.text('Dino'), findsOneWidget);
      expect(find.text('Strong and Brave'), findsOneWidget);
    });

    testWidgets('2. Shows SELECTED for currently active mascot (owly) and SELECT for others', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildWidget(
        user: testUser.copyWith(kidsMascot: 'owly'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('SELECTED'), findsOneWidget);
      expect(find.text('SELECT'), findsNWidgets(2));
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('3. Shows SELECTED for foxie when user has foxie equipped', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildWidget(
        user: testUser.copyWith(kidsMascot: 'foxie'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('SELECTED'), findsOneWidget);
      expect(find.text('SELECT'), findsNWidgets(2));
    });

    testWidgets('4. Shows SELECTED for dino when user has dino equipped', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildWidget(
        user: testUser.copyWith(kidsMascot: 'dino'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('SELECTED'), findsOneWidget);
      expect(find.text('SELECT'), findsNWidgets(2));
    });

    testWidgets('5. Tapping Try me! button plays mascot sound interaction', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      final tryMeButtons = find.text('Try me!');
      expect(tryMeButtons, findsNWidgets(3));

      await tester.tap(tryMeButtons.first);
      await tester.pump();

      verify(() => mockSoundService.playMascotInteraction()).called(1);

      // Advance clock past the 2-second cooldown timer so no timer remains pending
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('6. Tapping SELECT on unselected mascot (Foxie) updates profile and shows snackbar', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildWidget(
        user: testUser.copyWith(kidsMascot: 'owly'),
      ));
      await tester.pumpAndSettle();

      final selectButtons = find.text('SELECT');
      expect(selectButtons, findsNWidgets(2));

      // Tap the first SELECT button (which corresponds to Foxie)
      await tester.tap(selectButtons.first);
      await tester.pump();

      verify(() => mockProfileBloc.add(any(that: isA<ProfileUpdateMascotRequested>().having(
        (e) => e.mascotId,
        'mascotId',
        'foxie',
      )))).called(1);

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('Foxie is now your buddy!'), findsOneWidget);
    });

    testWidgets('7. Tapping SELECT on Dino updates profile with dino', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildWidget(
        user: testUser.copyWith(kidsMascot: 'owly'),
      ));
      await tester.pumpAndSettle();

      final selectButtons = find.text('SELECT');
      expect(selectButtons, findsNWidgets(2));

      // Tap the second SELECT button (which corresponds to Dino)
      await tester.tap(selectButtons.at(1));
      await tester.pump();

      verify(() => mockProfileBloc.add(any(that: isA<ProfileUpdateMascotRequested>().having(
        (e) => e.mascotId,
        'mascotId',
        'dino',
      )))).called(1);

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('Dino is now your buddy!'), findsOneWidget);
    });

    testWidgets('8. Tapping back button pops route to root screen', (tester) async {
      configureViewport(tester);
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: Text('Home Screen Root')),
          ),
          GoRoute(
            path: '/mascot',
            builder: (context, state) => const MascotSelectionScreen(),
          ),
        ],
      );

      await tester.pumpWidget(buildWidget(customRouter: router));
      await tester.pumpAndSettle();
      expect(find.text('Home Screen Root'), findsOneWidget);

      router.push('/mascot');
      await tester.pumpAndSettle();
      expect(find.text('Choose Your Buddy!'), findsOneWidget);

      final backButton = find.byIcon(Icons.arrow_back_rounded);
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.text('Home Screen Root'), findsOneWidget);
    });

    testWidgets('9. Renders in dark mode with dark styling', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildWidget(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      expect(find.text('Choose Your Buddy!'), findsOneWidget);
      expect(find.text('Owly'), findsOneWidget);
      expect(find.text('Foxie'), findsOneWidget);
      expect(find.text('Dino'), findsOneWidget);
    });

    testWidgets('10. Renders on compact 320dp screen without overflow', (tester) async {
      configureViewport(tester, size: const Size(320, 700));
      await tester.pumpWidget(buildWidget(
        screenSize: const Size(320, 700),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Choose Your Buddy!'), findsOneWidget);
      expect(find.text('Owly'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

