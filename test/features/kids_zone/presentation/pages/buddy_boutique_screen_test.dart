import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/profile_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/pages/buddy_boutique_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}
class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState> implements ProfileBloc {}
class MockEconomyBloc extends MockBloc<EconomyEvent, EconomyState> implements EconomyBloc {}
class MockHapticService extends Mock implements HapticService {}
class MockLocaleService extends Mock implements LocaleService {}
class MockSoundService extends Mock implements SoundService {}
class MockAdService extends Mock implements AdService {}

class FakeBuildContext extends Fake implements BuildContext {}
class FakeProfileEvent extends Fake implements ProfileEvent {}
class FakeEconomyEvent extends Fake implements EconomyEvent {}
class FakeRewardItem extends Fake implements RewardItem {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeBuildContext());
    registerFallbackValue(FakeProfileEvent());
    registerFallbackValue(FakeEconomyEvent());
    registerFallbackValue(FakeRewardItem());
  });

  late MockAuthBloc mockAuthBloc;
  late MockProfileBloc mockProfileBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;
  late MockLocaleService mockLocaleService;
  late MockSoundService mockSoundService;
  late MockAdService mockAdService;

  final testUser = UserEntity(
    id: 'kid_boutique_123',
    email: 'kid@vowl.app',
    displayName: 'Boutique Explorer',
    totalExp: 1100, // level 12
    currentStreak: 5,
    kidsCoins: 150,
    kidsMascot: 'mascot_sprout',
    kidsOwnedAccessories: const ['cape_red', 'mascot_star'],
    kidsEquippedAccessory: 'cape_red',
  );

  setUp(() async {
    VowlMotion.lowAnimationModeOverride.value = true;
    SharedPreferences.setMockInitialValues({});
    await di.sl.reset();

    mockAuthBloc = MockAuthBloc();
    mockProfileBloc = MockProfileBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockLocaleService = MockLocaleService();
    mockSoundService = MockSoundService();
    mockAdService = MockAdService();

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

    when(() => mockSoundService.playClick()).thenAnswer((_) async {});
    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockHapticService.selection()).thenAnswer((_) async {});

    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<AdService>(mockAdService);
  });

  tearDown(() async {
    VowlMotion.lowAnimationModeOverride.value = false;
    await di.sl.reset();
  });

  void configureViewport(WidgetTester tester, [Size size = const Size(600, 1400)]) {
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
  }) {
    final activeUser = user ?? testUser;
    when(() => mockAuthBloc.state).thenReturn(AuthState.authenticated(activeUser));
    when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.value(AuthState.authenticated(activeUser)));

    when(() => mockProfileBloc.state).thenReturn(const ProfileState());
    when(() => mockProfileBloc.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockEconomyBloc.stream).thenAnswer((_) => const Stream.empty());

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, child) => MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<ProfileBloc>.value(value: mockProfileBloc),
          BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
        ],
        child: MaterialApp(
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
          home: const BuddyBoutiqueScreen(),
        ),
      ),
    );
  }

  group('BuddyBoutiqueScreen Widget Tests', () {
    testWidgets('1. Renders BuddyBoutiqueScreen with all core sections', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Buddy Boutique'), findsOneWidget);
      expect(find.text('BUDDY PASSPORT'), findsOneWidget);
      expect(find.text('Holographic Identity'), findsOneWidget);
      expect(find.text('KIDS COINS'), findsOneWidget);
      expect(find.text('150'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Clothes'), findsOneWidget);
      expect(find.text('Toys'), findsOneWidget);
      expect(find.text('Magic'), findsOneWidget);
      expect(find.text('Buddies'), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('2. Displays buddy passport preview stats correctly', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // level 12 -> "STAR BUDDY ⭐"
      expect(find.text('STAR BUDDY ⭐'), findsOneWidget);
      expect(find.text('STREAK: 5'), findsOneWidget);
      expect(find.text('LVL: 12'), findsOneWidget);
    });

    testWidgets('3a. Displays legendary rank for level >= 50', (tester) async {
      configureViewport(tester);
      final highLevelUser = testUser.copyWith(totalExp: 5400); // level 55
      await tester.pumpWidget(buildWidget(user: highLevelUser));
      await tester.pumpAndSettle();

      expect(find.text('LEGENDARY HERO 👑'), findsOneWidget);
    });

    testWidgets('3b. Displays sprouty rank for level < 10', (tester) async {
      configureViewport(tester);
      final beginnerUser = testUser.copyWith(totalExp: 200); // level 3
      await tester.pumpWidget(buildWidget(user: beginnerUser));
      await tester.pumpAndSettle();

      expect(find.text('SPROUTY BUDDY 🌱'), findsOneWidget);
    });

    testWidgets('4. Category tabs filter shop items', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Initially on "All" tab: Tiny Cape is visible
      expect(find.text('Tiny Cape'), findsOneWidget);

      // Tap "Toys" tab
      await tester.ensureVisible(find.text('Toys'));
      await tester.tap(find.text('Toys'));
      await tester.pumpAndSettle();

      // Toys items should be visible
      expect(find.text('Golden Bell'), findsOneWidget);
      // Clothes items should NOT be visible in Toys
      expect(find.text('Tiny Cape'), findsNothing);

      // Tap "Magic" tab
      await tester.ensureVisible(find.text('Magic'));
      await tester.tap(find.text('Magic'));
      await tester.pumpAndSettle();
      expect(find.text('Magic Wand'), findsOneWidget);
      expect(find.text('Golden Bell'), findsNothing);

      // Tap back to "All" tab
      await tester.ensureVisible(find.text('All'));
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(find.text('Tiny Cape'), findsOneWidget);
    });

    testWidgets('5. Unequipping an already equipped accessory dispatches ProfileEquipAccessoryRequested(null)', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // 'cape_red' is equipped, status is "EQUIPPED"
      expect(find.text('EQUIPPED'), findsOneWidget);

      // Tap the equipped item
      await tester.tap(find.text('Tiny Cape'));
      await tester.pump();

      verify(() => mockProfileBloc.add(const ProfileEquipAccessoryRequested(null))).called(1);
    });

    testWidgets('6. Equipping an unequipped owned accessory dispatches ProfileEquipAccessoryRequested(itemId)', (tester) async {
      configureViewport(tester);
      // User owns 'shades_cool' but it's not equipped
      final userWithShades = testUser.copyWith(
        kidsOwnedAccessories: ['cape_red', 'shades_cool'],
        kidsEquippedAccessory: 'cape_red',
      );
      await tester.pumpWidget(buildWidget(user: userWithShades));
      await tester.pumpAndSettle();

      // Find Cool Shades item card and tap it
      expect(find.text('Cool Shades'), findsOneWidget);
      await tester.tap(find.text('Cool Shades'));
      await tester.pump();

      verify(() => mockProfileBloc.add(const ProfileEquipAccessoryRequested('shades_cool'))).called(1);
    });

    testWidgets('7. Equipping an owned mascot dispatches ProfileUpdateMascotRequested', (tester) async {
      configureViewport(tester);
      final userWithMascots = testUser.copyWith(
        kidsOwnedAccessories: ['cape_red', 'mascot_robot'],
        kidsMascot: 'mascot_sprout',
        kidsEquippedAccessory: 'cape_red',
      );
      await tester.pumpWidget(buildWidget(user: userWithMascots));
      await tester.pumpAndSettle();

      // Switch to Buddies tab
      await tester.ensureVisible(find.text('Buddies'));
      await tester.tap(find.text('Buddies'));
      await tester.pumpAndSettle();

      // Find Sparky Robot (id: mascot_robot)
      expect(find.text('Sparky Robot'), findsOneWidget);
      await tester.tap(find.text('Sparky Robot'));
      await tester.pump();

      verify(() => mockProfileBloc.add(const ProfileUpdateMascotRequested('mascot_robot'))).called(1);
    });

    testWidgets('8. Tapping unowned item when coins < price plays wrong sound and shows warning', (tester) async {
      configureViewport(tester);
      // User has only 10 coins, 'bell_gold' costs 200
      final poorUser = testUser.copyWith(kidsCoins: 10);
      await tester.pumpWidget(buildWidget(user: poorUser));
      await tester.pumpAndSettle();

      // Tap Toys tab to find Golden Bell
      await tester.tap(find.text('Toys'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Golden Bell'));
      await tester.pump();

      verify(() => mockSoundService.playWrong()).called(1);
      expect(find.text('Keep playing to earn more coins!'), findsOneWidget);
    });

    testWidgets('9. Tapping unowned item when coins >= price opens purchase confirmation sheet', (tester) async {
      configureViewport(tester);
      // User has 150 coins, 'Cool Shades' costs 30 and is unowned
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Tap Cool Shades
      await tester.tap(find.text('Cool Shades'));
      await tester.pumpAndSettle();

      // Bottom sheet should open with purchase confirmation
      expect(find.text('Buy for 30 coins?'), findsOneWidget);
      expect(find.text('Not Now'), findsOneWidget);
      expect(find.text('Buy Now!'), findsOneWidget);

      // Dismiss via "Not Now"
      await tester.tap(find.text('Not Now'));
      await tester.pumpAndSettle();

      // Bottom sheet dismissed, no buy event dispatched
      expect(find.text('Buy for 30 coins?'), findsNothing);
      verifyNever(() => mockProfileBloc.add(any(that: isA<ProfileBuyAccessoryRequested>())));
    });

    testWidgets('10. Confirming purchase via Buy Now! dispatches ProfileBuyAccessoryRequested, equips item and plays correct sound', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Tap Cool Shades
      await tester.tap(find.text('Cool Shades'));
      await tester.pumpAndSettle();

      // Tap Buy Now!
      await tester.tap(find.text('Buy Now!'));
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockProfileBloc.add(const ProfileBuyAccessoryRequested('shades_cool', 30))).called(1);
      verify(() => mockProfileBloc.add(const ProfileEquipAccessoryRequested('shades_cool'))).called(1);
      expect(find.text('Awesome! New item unlocked! ✨'), findsOneWidget);
    });

    testWidgets('11. Purchasing a mascot equips it via ProfileUpdateMascotRequested', (tester) async {
      configureViewport(tester);
      // User has 5000 coins to buy Sparky Robot (price 3500)
      final richUser = testUser.copyWith(
        kidsCoins: 5000,
        kidsOwnedAccessories: const ['cape_red'],
      );
      await tester.pumpWidget(buildWidget(user: richUser));
      await tester.pumpAndSettle();

      // Switch to Buddies tab
      await tester.ensureVisible(find.text('Buddies'));
      await tester.tap(find.text('Buddies'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sparky Robot'));
      await tester.pumpAndSettle();

      expect(find.text('Buy for 3500 coins?'), findsOneWidget);
      await tester.tap(find.text('Buy Now!'));
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockProfileBloc.add(const ProfileBuyAccessoryRequested('mascot_robot', 3500))).called(1);
      verify(() => mockProfileBloc.add(const ProfileUpdateMascotRequested('mascot_robot'))).called(1);
    });

    testWidgets('12. Watch & Earn triggers AdService.showRewardedAd and awards 10 kids coins', (tester) async {
      configureViewport(tester);
      when(() => mockAdService.showRewardedAd(
        context: any(named: 'context'),
        isPremium: any(named: 'isPremium'),
        childSafe: any(named: 'childSafe'),
        onUserEarnedReward: any(named: 'onUserEarnedReward'),
        onDismissed: any(named: 'onDismissed'),
      )).thenAnswer((invocation) async {
        final onReward = invocation.namedArguments[#onUserEarnedReward] as Function(RewardItem);
        onReward(FakeRewardItem());
        final onDismiss = invocation.namedArguments[#onDismissed] as VoidCallback;
        onDismiss();
      });

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('WATCH & EARN'),
        500.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('WATCH & EARN'), findsOneWidget);
      await tester.tap(find.text('WATCH & EARN'));
      await tester.pump();

      verify(() => mockAdService.showRewardedAd(
        context: any(named: 'context'),
        isPremium: false,
        childSafe: true,
        onUserEarnedReward: any(named: 'onUserEarnedReward'),
        onDismissed: any(named: 'onDismissed'),
      )).called(1);

      verify(() => mockEconomyBloc.add(const EconomyAddKidsCoinsRequested(10))).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
    });

    testWidgets('13. Back button navigates back via Navigator.pop', (tester) async {
      configureViewport(tester);
      when(() => mockAuthBloc.state).thenReturn(AuthState.authenticated(testUser));
      when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.value(AuthState.authenticated(testUser)));
      when(() => mockProfileBloc.state).thenReturn(const ProfileState());
      when(() => mockProfileBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
      when(() => mockEconomyBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          builder: (context, child) => MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              BlocProvider<ProfileBloc>.value(value: mockProfileBloc),
              BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
            ],
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  disableAnimations: true,
                  size: const Size(390, 1400),
                ),
                child: child!,
              ),
              home: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BuddyBoutiqueScreen()),
                    );
                  },
                  child: const Text('Go To Boutique'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Go To Boutique'));
      await tester.pumpAndSettle();

      expect(find.byType(BuddyBoutiqueScreen), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(BuddyBoutiqueScreen), findsNothing);
      expect(find.text('Go To Boutique'), findsOneWidget);
    });

    testWidgets('14. Renders cleanly in dark theme mode', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildWidget(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      expect(find.text('Buddy Boutique'), findsOneWidget);
      expect(find.text('BUDDY PASSPORT'), findsOneWidget);
    });

    testWidgets('15. Compact 320dp width renders without RenderFlex overflow', (tester) async {
      configureViewport(tester, const Size(320, 600));
      await tester.pumpWidget(buildWidget(screenSize: const Size(320, 600)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Buddy Boutique'), findsOneWidget);
    });
  });
}
