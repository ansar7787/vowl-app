import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/profile/presentation/widgets/profile_quick_action_hud.dart';

class MockHapticService extends Mock implements HapticService {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHapticService mockHapticService;
  late MockAuthBloc mockAuthBloc;

  final today = DateTime.now();

  final freeUser = UserEntity(
    id: 'user_free',
    email: 'free@vowl.app',
    displayName: 'Free Learner',
    coins: 520,
    keys: 4,
    currentStreak: 12,
    isPremium: false,
    lastVipGiftDate: today,
  );

  final premiumUser = UserEntity(
    id: 'user_premium',
    email: 'vip@vowl.app',
    displayName: 'VIP Champion',
    coins: 15400,
    keys: 4,
    currentStreak: 45,
    isPremium: true,
    lastVipGiftDate: today,
  );

  setUp(() {
    VowlMotion.lowAnimationModeOverride.value = true;
    mockHapticService = MockHapticService();
    mockAuthBloc = MockAuthBloc();

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    di.sl.registerSingleton<HapticService>(mockHapticService);
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
  });

  Widget buildSubject({required UserEntity user}) {
    when(() => mockAuthBloc.state).thenReturn(AuthState.authenticated(user));

    return ScreenUtilInit(
      designSize: const Size(393, 852),
      builder: (context, _) => BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: MaterialApp(
          home: Scaffold(
            body: ProfileQuickActionHud(user: user),
          ),
        ),
      ),
    );
  }

  group('ProfileQuickActionHud Free vs Premium Tests', () {
    testWidgets('free user renders Keys pod with golden key icon and count', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(user: freeUser));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Pod 1: Coins
      expect(find.text('520'), findsOneWidget);
      expect(find.byIcon(Icons.monetization_on_rounded), findsOneWidget);

      // Pod 2: Keys visible, Store NOT visible for free users
      expect(find.text('4'), findsOneWidget);
      expect(find.byIcon(Icons.key_rounded), findsOneWidget);
      expect(find.byIcon(Icons.storefront_rounded), findsNothing);
      expect(find.text('Store'), findsNothing);

      // Pod 3: Streak
      expect(find.text('12d'), findsOneWidget);

      // Pod 4: VIP upgrade
      expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);

      // Tap Keys pod -> plays selection haptic
      await tester.tap(find.byIcon(Icons.key_rounded));
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets(
      'premium user hides Keys pod and renders Premium Store pod with storefront icon',
      (tester) async {
        await tester.pumpWidget(buildSubject(user: premiumUser));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Pod 1: Coins
        expect(find.text('15400'), findsOneWidget);
        expect(find.byIcon(Icons.monetization_on_rounded), findsOneWidget);

        // Pod 2: Keys NEVER shown, Store pod is shown instead!
        expect(find.byIcon(Icons.key_rounded), findsNothing);
        expect(find.text('4'), findsNothing);
        expect(find.byIcon(Icons.storefront_rounded), findsOneWidget);
        expect(find.text('Store'), findsOneWidget);

        // Pod 3: Streak
        expect(find.text('45d'), findsOneWidget);

        // Pod 4: VIP active
        expect(find.byIcon(Icons.verified_rounded), findsOneWidget);

        // Tap Store pod -> plays selection haptic
        await tester.tap(find.byIcon(Icons.storefront_rounded));
        verify(() => mockHapticService.selection()).called(1);
      },
    );
  });
}
