import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/arena/presentation/pages/arena_stats_screen.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/profile/presentation/widgets/profile_arena_card.dart';

class MockHapticService extends Mock implements HapticService {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHapticService mockHapticService;
  late MockAuthBloc mockAuthBloc;

  final userWithStats = UserEntity(
    id: 'user_gladiator',
    email: 'gladiator@vowl.app',
    displayName: 'Gladiator',
    coins: 100,
    duelWins: 14,
    duelLosses: 6,
    dailyDuelsPlayedToday: 3,
  );

  final userLowCoins = UserEntity(
    id: 'user_broke',
    email: 'broke@vowl.app',
    displayName: 'Learner',
    coins: 10,
    duelWins: 2,
    duelLosses: 1,
    dailyDuelsPlayedToday: 1,
  );

  setUp(() {
    VowlMotion.lowAnimationModeOverride.value = true;
    mockHapticService = MockHapticService();
    mockAuthBloc = MockAuthBloc();

    when(() => mockHapticService.selection()).thenAnswer((_) async {});

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
          home: Scaffold(body: ProfileArenaCard(user: user)),
        ),
      ),
    );
  }

  group('ProfileArenaCard Brand & Visual Tests', () {
    testWidgets(
      'renders Lucide swords icon, human copy, and statistics accurately',
      (tester) async {
        await tester.pumpWidget(buildSubject(user: userWithStats));
        await tester.pumpAndSettle();

        // Official brand icon
        expect(find.byIcon(LucideIcons.swords), findsOneWidget);

        // Human vocabulary game copy
        expect(find.text('1V1 WORD ARENA'), findsOneWidget);
        expect(find.text('Live Vocabulary Duels'), findsOneWidget);

        // Zero-division math: 14 wins / (14 + 6) = 70% win rate
        expect(find.text('14'), findsOneWidget);
        expect(find.text('6'), findsOneWidget);
        expect(find.text('70%'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
      },
    );

    testWidgets('tapping card navigates to ArenaStatsScreen', (tester) async {
      await tester.pumpWidget(buildSubject(user: userLowCoins));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ProfileArenaCard));
      await tester.pumpAndSettle();

      // Verifies navigation to detailed ArenaStatsScreen instead of immediate matchmaking
      expect(find.byType(ArenaStatsScreen), findsOneWidget);
    });
  });
}
