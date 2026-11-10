import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/utils/toll_gate_helper.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
  });

  group('TollGateHelper Unit Tests', () {
    test('isTollGate returns false when user is null', () {
      expect(
        TollGateHelper.isTollGate(
          user: null,
          gameType: 'sentenceBuilder',
          level: 4,
        ),
        isFalse,
      );
    });

    test('isTollGate returns false when user is premium regardless of level', () {
      const premiumUser = UserEntity(
        id: 'u_prem',
        email: 'prem@vowl.app',
        isPremium: true,
        unlockedLevels: {'sentenceBuilder': 3},
      );

      expect(
        TollGateHelper.isTollGate(
          user: premiumUser,
          gameType: 'sentenceBuilder',
          level: 4,
        ),
        isFalse,
      );
      expect(
        TollGateHelper.isTollGate(
          user: premiumUser,
          gameType: 'sentenceBuilder',
          level: 100,
        ),
        isFalse,
      );
    });

    test('isTollGate returns false when level <= unlockedLevels for free user', () {
      const freeUser = UserEntity(
        id: 'u_free',
        email: 'free@vowl.app',
        isPremium: false,
        unlockedLevels: {'sentenceBuilder': 3},
      );

      expect(
        TollGateHelper.isTollGate(
          user: freeUser,
          gameType: 'sentenceBuilder',
          level: 1,
        ),
        isFalse,
      );
      expect(
        TollGateHelper.isTollGate(
          user: freeUser,
          gameType: 'sentenceBuilder',
          level: 3,
        ),
        isFalse,
      );
    });

    test('isTollGate returns true when level > unlockedLevels for free user', () {
      const freeUser = UserEntity(
        id: 'u_free',
        email: 'free@vowl.app',
        isPremium: false,
        unlockedLevels: {'sentenceBuilder': 3},
      );

      expect(
        TollGateHelper.isTollGate(
          user: freeUser,
          gameType: 'sentenceBuilder',
          level: 4,
        ),
        isTrue,
      );
    });

    test('isTollGate defaults to unlockedLevel 1 if gameType is not in user map', () {
      const freeUser = UserEntity(
        id: 'u_free',
        email: 'free@vowl.app',
        isPremium: false,
        unlockedLevels: {},
      );

      expect(
        TollGateHelper.isTollGate(
          user: freeUser,
          gameType: 'unrecordedGame',
          level: 1,
        ),
        isFalse,
      );
      expect(
        TollGateHelper.isTollGate(
          user: freeUser,
          gameType: 'unrecordedGame',
          level: 2,
        ),
        isTrue,
      );
    });
  });

  group('TollGateHelper Widget Tests', () {
    testWidgets('handleTollGateIfNeeded shows TollGateBottomSheet and returns true when at toll gate', (tester) async {
      const freeUser = UserEntity(
        id: 'u_free',
        email: 'free@vowl.app',
        isPremium: false,
        unlockedLevels: {'sentenceBuilder': 3},
        keys: 1,
      );
      when(() => mockAuthBloc.state).thenReturn(AuthState.authenticated(freeUser));

      bool? handled;
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(393, 852),
          builder: (context, _) => BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (ctx) => Center(
                    child: ElevatedButton(
                      onPressed: () {
                        handled = TollGateHelper.handleTollGateIfNeeded(
                          context: ctx,
                          user: freeUser,
                          gameType: 'sentenceBuilder',
                          level: 4,
                        );
                      },
                      child: const Text('Check Toll Gate'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Check Toll Gate'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(handled, isTrue);
      // TollGateBottomSheet should be visible on the screen
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('handleTollGateIfNeeded does nothing and returns false when level is playable', (tester) async {
      const freeUser = UserEntity(
        id: 'u_free',
        email: 'free@vowl.app',
        isPremium: false,
        unlockedLevels: {'sentenceBuilder': 5},
      );
      when(() => mockAuthBloc.state).thenReturn(AuthState.authenticated(freeUser));

      bool? handled;
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(393, 852),
          builder: (context, _) => BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (ctx) => Center(
                    child: ElevatedButton(
                      onPressed: () {
                        handled = TollGateHelper.handleTollGateIfNeeded(
                          context: ctx,
                          user: freeUser,
                          gameType: 'sentenceBuilder',
                          level: 4,
                        );
                      },
                      child: const Text('Check Toll Gate'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Check Toll Gate'));
      await tester.pumpAndSettle();

      expect(handled, isFalse);
      expect(find.byType(BottomSheet), findsNothing);
    });
  });
}
