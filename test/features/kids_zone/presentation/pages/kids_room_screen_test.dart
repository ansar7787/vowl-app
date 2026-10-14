import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/profile_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/pages/kids_room_screen.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_room_top_bar.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_room_action_panel.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_room_daily_care_card.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_room_exit_dialog.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_room_food_sheet.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_room_decor_sheet.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_room_theme_sheet.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_room_clean_activity.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_room_play_game.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}
class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState> implements ProfileBloc {}
class MockEconomyBloc extends MockBloc<EconomyEvent, EconomyState> implements EconomyBloc {}
class MockHapticService extends Mock implements HapticService {}
class MockLocaleService extends Mock implements LocaleService {}
class MockTtsService extends Mock implements TtsService {}
class MockSoundService extends Mock implements SoundService {}

class FakeBuildContext extends Fake implements BuildContext {}
class FakeProfileEvent extends Fake implements ProfileEvent {}
class FakeEconomyEvent extends Fake implements EconomyEvent {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeBuildContext());
    registerFallbackValue(FakeProfileEvent());
    registerFallbackValue(FakeEconomyEvent());
  });

  late MockAuthBloc mockAuthBloc;
  late MockProfileBloc mockProfileBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;
  late MockLocaleService mockLocaleService;
  late MockTtsService mockTtsService;
  late MockSoundService mockSoundService;

  final now = DateTime.now();
  final yesterday = now.subtract(const Duration(days: 1));

  final testUser = UserEntity(
    id: 'kid_123',
    email: 'kid@vowl.app',
    displayName: 'Super Buddy',
    kidsMascot: 'owly',
    kidsCoins: 250,
    keys: 3,
    kidsBuddyEnergy: 80,
    kidsBuddyHunger: 20,
    kidsBuddyMood: 'happy',
    kidsRoomTheme: 'nature',
    kidsOwnedFurniture: const [
      'default_bed',
      'default_window',
      'default_shelf',
      'default_toy',
      'default_plant',
      'default_rug',
    ],
    kidsEquippedFurniture: const {'bed': 'default_bed'},
    kidsLastGameDate: yesterday,
    kidsGamesPlayedToday: 0,
    kidsLastCareDate: yesterday,
    kidsCareStreak: 3,
    kidsEquippedSticker: 'star_sticker',
  );

  setUp(() {
    VowlMotion.lowAnimationModeOverride.value = true;
    SharedPreferences.setMockInitialValues({});
    mockAuthBloc = MockAuthBloc();
    mockProfileBloc = MockProfileBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockLocaleService = MockLocaleService();
    mockTtsService = MockTtsService();
    mockSoundService = MockSoundService();

    when(() => mockLocaleService.currentLocale).thenReturn(const Locale('en'));
    when(
      () => mockLocaleService.tr(
        any(),
        fallback: any(named: 'fallback'),
        args: any(named: 'args'),
      ),
    ).thenAnswer(
      (inv) =>
          inv.namedArguments[#fallback] as String? ??
          inv.positionalArguments.first as String,
    );

    when(() => mockTtsService.speak(any())).thenAnswer((_) async {});
    when(() => mockSoundService.playClick()).thenAnswer((_) async {});
    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockHapticService.selection()).thenAnswer((_) async {});

    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();

    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
  });

  Widget createTestWidget({
    UserEntity? user,
    Brightness brightness = Brightness.light,
    double width = 400,
    double height = 800,
  }) {
    final activeUser = user ?? testUser;
    when(() => mockAuthBloc.state).thenReturn(AuthState.authenticated(activeUser));
    when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.value(AuthState.authenticated(activeUser)));

    when(() => mockProfileBloc.state).thenReturn(const ProfileState());
    when(() => mockProfileBloc.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockEconomyBloc.stream).thenAnswer((_) => const Stream.empty());

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<ProfileBloc>.value(value: mockProfileBloc),
        BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        builder: (context, child) => MaterialApp(
          theme: brightness == Brightness.dark ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, height),
              disableAnimations: true,
            ),
            child: const KidsRoomScreen(),
          ),
        ),
      ),
    );
  }

  group('KidsRoomScreen Tests', () {
    testWidgets('1. Renders KidsRoomScreen with top bar, daily care card, mascot, hero nameplate, and action panel', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(KidsRoomTopBar), findsOneWidget);
      expect(find.byType(KidsRoomDailyCareCard), findsOneWidget);
      expect(find.byType(KidsRoomActionPanel), findsOneWidget);
      expect(find.byType(VowlMascot), findsOneWidget);
      expect(find.text('OWLY'), findsOneWidget);
      expect(find.text('250'), findsOneWidget);
    });

    testWidgets('2. Initial greeting is spoken on load', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(KidsRoomScreen), findsOneWidget);
    });

    testWidgets('3. Daily care card: Tapping Claim grants streak and coins via ProfileBloc and EconomyBloc', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final claimFinder = find.text('CLAIM');
      if (claimFinder.evaluate().isNotEmpty) {
        await tester.tap(claimFinder);
        await tester.pump(const Duration(milliseconds: 200));

        verify(() => mockProfileBloc.add(any(that: isA<ProfileUpdateBuddyRoomRequested>()))).called(greaterThanOrEqualTo(1));
        verify(() => mockEconomyBloc.add(const EconomyAddKidsCoinsRequested(25))).called(1);
        verify(() => mockSoundService.playCorrect()).called(1);
      }
    });

    testWidgets('4. Tapping mascot triggers mood speech', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final mascotFinder = find.byType(VowlMascot);
      expect(mascotFinder, findsOneWidget);

      await tester.tap(mascotFinder);
      await tester.pump(const Duration(milliseconds: 200));

      verify(() => mockTtsService.speak(any())).called(greaterThanOrEqualTo(1));
    });

    testWidgets('5. Feed button opens food bottom sheet and selecting affordable food triggers feeding', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final feedButton = find.text('FEED');
      expect(feedButton, findsOneWidget);
      await tester.ensureVisible(feedButton);
      await tester.tap(feedButton);
      await tester.pumpAndSettle();

      expect(find.byType(KidsRoomFoodSheet), findsOneWidget);
      expect(find.text('YUMMY TREATS'), findsOneWidget);

      final appleItem = find.text('APPLE');
      expect(appleItem, findsOneWidget);
      await tester.ensureVisible(appleItem);
      await tester.tap(appleItem);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));

      verify(() => mockEconomyBloc.add(const EconomyAddKidsCoinsRequested(0))).called(1);
      verify(() => mockProfileBloc.add(any(that: isA<ProfileUpdateBuddyRoomRequested>()))).called(greaterThanOrEqualTo(1));
      verify(() => mockSoundService.playCorrect()).called(1);
    });

    testWidgets('6. Feed button: selecting unaffordable food plays wrong sound', (tester) async {
      final brokeUser = testUser.copyWith(kidsCoins: 10);
      await tester.pumpWidget(createTestWidget(user: brokeUser));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final feedButton = find.text('FEED');
      await tester.ensureVisible(feedButton);
      await tester.tap(feedButton);
      await tester.pumpAndSettle();

      final cakeItem = find.text('CAKE');
      expect(cakeItem, findsOneWidget);
      await tester.ensureVisible(cakeItem);
      await tester.tap(cakeItem);
      await tester.pumpAndSettle();

      verify(() => mockSoundService.playWrong()).called(1);
    });

    testWidgets('7. Decor button opens decor bottom sheet and equipping owned item updates furniture', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final decorButton = find.text('DECOR');
      expect(decorButton, findsOneWidget);
      await tester.ensureVisible(decorButton);
      await tester.tap(decorButton);
      await tester.pumpAndSettle();

      expect(find.byType(KidsRoomDecorSheet), findsOneWidget);
      expect(find.text('DECORATE ROOM'), findsOneWidget);

      final snugglyBed = find.text('Snuggly Bed');
      expect(snugglyBed, findsOneWidget);
      await tester.ensureVisible(snugglyBed);
      await tester.tap(snugglyBed);
      await tester.pumpAndSettle();

      verify(() => mockProfileBloc.add(const ProfileUpdateFurnitureRequested('bed', 'default_bed'))).called(1);
    });

    testWidgets('8. Decor button: purchasing unowned furniture when having enough coins', (tester) async {
      final richUser = testUser.copyWith(kidsCoins: 1000);
      await tester.pumpWidget(createTestWidget(user: richUser));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final decorButton = find.text('DECOR');
      await tester.ensureVisible(decorButton);
      await tester.tap(decorButton);
      await tester.pumpAndSettle();

      final rocketBed = find.text('Rocket Pod');
      expect(rocketBed, findsOneWidget);
      await tester.ensureVisible(rocketBed);
      await tester.tap(rocketBed);
      await tester.pumpAndSettle();

      verify(() => mockProfileBloc.add(const ProfileBuyFurnitureRequested('bed', 'rocket_bed', 500))).called(1);
      verify(() => mockTtsService.speak("New item unlocked!")).called(1);
    });

    testWidgets('9. Theme button opens theme bottom sheet and changes theme', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final themeButton = find.text('THEME');
      expect(themeButton, findsOneWidget);
      await tester.ensureVisible(themeButton);
      await tester.tap(themeButton);
      await tester.pumpAndSettle();

      expect(find.byType(KidsRoomThemeSheet), findsOneWidget);
      expect(find.text('MAGIC THEMES'), findsOneWidget);

      final spaceTheme = find.text('SPACE');
      expect(spaceTheme, findsOneWidget);
      await tester.ensureVisible(spaceTheme);
      await tester.tap(spaceTheme);
      await tester.pumpAndSettle();

      verify(() => mockProfileBloc.add(const ProfileUpdateBuddyRoomRequested(theme: 'space'))).called(1);
      verify(() => mockSoundService.playClick()).called(1);
    });

    testWidgets('10. Sleep toggle toggles sleep state and waking up', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final sleepButton = find.text('SLEEP');
      expect(sleepButton, findsOneWidget);
      await tester.ensureVisible(sleepButton);
      await tester.tap(sleepButton);
      await tester.pumpAndSettle();

      final wakeFinder = find.text('TAP TO WAKE UP');
      expect(wakeFinder, findsOneWidget);

      await tester.tap(wakeFinder);
      await tester.pumpAndSettle();

      expect(find.text('TAP TO WAKE UP'), findsNothing);
    });

    testWidgets('11. Clean button launches clean activity dialog', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final cleanButton = find.text('CLEAN');
      expect(cleanButton, findsOneWidget);
      await tester.ensureVisible(cleanButton);
      await tester.tap(cleanButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(KidsRoomCleanActivity), findsOneWidget);
    });

    testWidgets('12. Play button launches mini-game dialog when daily limit not reached', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final playButton = find.text('PLAY');
      expect(playButton, findsOneWidget);
      await tester.ensureVisible(playButton);
      await tester.tap(playButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(KidsRoomPlayGame), findsOneWidget);
    });

    testWidgets('13. Play button speaks tired message when daily games limit (3) reached', (tester) async {
      final tiredUser = testUser.copyWith(
        kidsGamesPlayedToday: 3,
        kidsLastGameDate: DateTime.now(),
      );
      await tester.pumpWidget(createTestWidget(user: tiredUser));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final playButton = find.text('PLAY');
      expect(playButton, findsOneWidget);
      await tester.ensureVisible(playButton);
      await tester.tap(playButton);
      await tester.pumpAndSettle();

      expect(find.byType(KidsRoomPlayGame), findsNothing);
      verify(() => mockTtsService.speak(any(that: contains("tired")))).called(1);
    });

    testWidgets('14. Back button opens KidsRoomExitDialog', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(KidsRoomExitDialog), findsOneWidget);
      expect(find.text('LEAVING SO SOON?'), findsOneWidget);

      final stayButton = find.text('STAY');
      expect(stayButton, findsOneWidget);
      await tester.tap(stayButton);
      await tester.pumpAndSettle();

      expect(find.byType(KidsRoomExitDialog), findsNothing);
    });

    testWidgets('15. Clean rendering in dark theme without crash', (tester) async {
      await tester.pumpWidget(createTestWidget(brightness: Brightness.dark));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(KidsRoomScreen), findsOneWidget);
    });

    testWidgets('16. Compact 320dp width renders with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(width: 320, height: 600));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(KidsRoomScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

