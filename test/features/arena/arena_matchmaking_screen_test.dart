import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';
import 'package:vowl/features/arena/domain/repositories/arena_repository.dart';
import 'package:vowl/features/arena/presentation/pages/arena_matchmaking_screen.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

class MockArenaRepository extends Mock implements ArenaRepository {}

class MockHapticService extends Mock implements HapticService {}

class MockSoundService extends Mock implements SoundService {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockArenaRepository mockArenaRepo;
  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;
  late MockAuthBloc mockAuthBloc;
  late Completer<ArenaDuelSession> quickMatchCompleter;

  const testUser = UserEntity(
    id: 'challenger_123',
    email: 'challenger@vowl.app',
    displayName: 'Lexicon Champ',
    coins: 250,
  );

  setUpAll(() {
    registerFallbackValue(testUser);
  });

  setUp(() {
    VowlMotion.lowAnimationModeOverride.value = true;
    mockArenaRepo = MockArenaRepository();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    mockAuthBloc = MockAuthBloc();
    quickMatchCompleter = Completer<ArenaDuelSession>();

    when(
      () => mockArenaRepo.quickMatch(currentUser: any(named: 'currentUser')),
    ).thenAnswer((_) => quickMatchCompleter.future);
    when(
      () => mockArenaRepo.cancelMatchmaking(userId: any(named: 'userId')),
    ).thenAnswer((_) async {});
    when(
      () => mockArenaRepo.refundStake(userId: any(named: 'userId')),
    ).thenAnswer((_) async {});

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});
    when(() => mockSoundService.playArenaMatchFound()).thenAnswer((_) async {});
    when(() => mockSoundService.playArenaCountdown()).thenAnswer((_) async {});

    when(
      () => mockAuthBloc.state,
    ).thenReturn(AuthState.authenticated(testUser));

    if (di.sl.isRegistered<ArenaRepository>()) {
      di.sl.unregister<ArenaRepository>();
    }
    di.sl.registerSingleton<ArenaRepository>(mockArenaRepo);

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    di.sl.registerSingleton<HapticService>(mockHapticService);

    if (di.sl.isRegistered<SoundService>()) {
      di.sl.unregister<SoundService>();
    }
    di.sl.registerSingleton<SoundService>(mockSoundService);
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
    if (di.sl.isRegistered<ArenaRepository>()) {
      di.sl.unregister<ArenaRepository>();
    }
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<SoundService>()) {
      di.sl.unregister<SoundService>();
    }
  });

  Widget buildSubject() {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      builder: (context, _) => BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(
                      ctx,
                    ).push(ArenaMatchmakingScreen.route(user: testUser));
                  },
                  child: const Text('Launch Matchmaking'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('ArenaMatchmakingScreen Cancellation & Clean Exit Tests', () {
    testWidgets('renders searching radar, status messages and Cancel button', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.text('Launch Matchmaking'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Cancel Matchmaking'), findsOneWidget);
      expect(find.byIcon(LucideIcons.x), findsOneWidget);
      expect(find.text('Finding an opponent...'), findsOneWidget);
      expect(find.textContaining('Entry 30🪙'), findsOneWidget);
    });

    testWidgets(
      'tapping cancel (X) immediately invokes cancelMatchmaking and refundStake',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.tap(find.text('Launch Matchmaking'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Tap Cancel X icon
        await tester.tap(find.byIcon(LucideIcons.x));
        await tester.pumpAndSettle();

        // Verifies background ticket was purged and stake was restored
        verify(
          () => mockArenaRepo.cancelMatchmaking(userId: 'challenger_123'),
        ).called(1);
        verify(
          () => mockArenaRepo.refundStake(userId: 'challenger_123'),
        ).called(1);
        // Screen popped back to launcher
        expect(find.text('Launch Matchmaking'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping bottom Cancel Matchmaking button invokes cancelMatchmaking and refundStake',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.tap(find.text('Launch Matchmaking'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Tap Cancel button
        await tester.tap(find.text('Cancel Matchmaking'));
        await tester.pumpAndSettle();

        verify(
          () => mockArenaRepo.cancelMatchmaking(userId: 'challenger_123'),
        ).called(1);
        verify(
          () => mockArenaRepo.refundStake(userId: 'challenger_123'),
        ).called(1);
        expect(find.text('Launch Matchmaking'), findsOneWidget);
      },
    );

    testWidgets(
      'system back gesture invokes cancelMatchmaking and refundStake without dialog prompt',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.tap(find.text('Launch Matchmaking'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Find PopScope
        final popScopeFinder = find.byWidgetPredicate((w) => w is PopScope);
        expect(popScopeFinder, findsOneWidget);

        final popScopeWidget = tester.widget<PopScope>(popScopeFinder);
        expect(popScopeWidget.canPop, isFalse);

        // Invoke pop callback
        popScopeWidget.onPopInvokedWithResult?.call(false, null);
        await tester.pumpAndSettle();

        // Guaranteed atomic cancellation with NO blocking confirmation dialog
        verify(
          () => mockArenaRepo.cancelMatchmaking(userId: 'challenger_123'),
        ).called(1);
        verify(
          () => mockArenaRepo.refundStake(userId: 'challenger_123'),
        ).called(1);
        expect(find.text('Launch Matchmaking'), findsOneWidget);
      },
    );
  });
}
