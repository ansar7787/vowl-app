import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/features/auth/domain/usecases/get_user_stream.dart';
import 'package:vowl/features/auth/domain/usecases/log_out.dart';
import 'package:vowl/features/auth/domain/usecases/reload_user.dart';
import 'package:vowl/features/auth/domain/usecases/delete_account.dart';
import 'package:vowl/features/auth/domain/usecases/forgot_password.dart';
import 'package:vowl/features/auth/domain/usecases/get_current_user.dart';
import 'package:vowl/features/auth/domain/usecases/send_email_verification.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockGetUserStream extends Mock implements GetUserStream {}

class MockLogOut extends Mock implements LogOut {}

class MockReloadUser extends Mock implements ReloadUser {}

class MockDeleteAccount extends Mock implements DeleteAccount {}

class MockForgotPassword extends Mock implements ForgotPassword {}

class MockGetCurrentUser extends Mock implements GetCurrentUser {}

class MockSendEmailVerification extends Mock implements SendEmailVerification {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockNotificationService extends Mock implements NotificationService {}

class FakeNoParams extends Fake implements NoParams {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  late AuthBloc bloc;
  late MockGetUserStream mockGetUserStream;
  late MockLogOut mockLogOut;
  late MockReloadUser mockReloadUser;
  late MockDeleteAccount mockDeleteAccount;
  late MockForgotPassword mockForgotPassword;
  late MockGetCurrentUser mockGetCurrentUser;
  late MockSendEmailVerification mockSendEmailVerification;
  late MockNetworkInfo mockNetworkInfo;
  late MockNotificationService mockNotificationService;
  late StreamController<UserEntity?> userStreamController;

  final tUser = UserEntity(
    id: '1',
    email: 'test@vowl.com',
    displayName: 'Test User',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockNotificationService = MockNotificationService();
    when(() => mockNotificationService.cancelAllReminders()).thenAnswer((_) async {});
    when(() => mockNotificationService.unregisterUserOnLogout()).thenAnswer((_) async {});
    if (di.sl.isRegistered<NotificationService>()) {
      di.sl.unregister<NotificationService>();
    }
    di.sl.registerLazySingleton<NotificationService>(() => mockNotificationService);

    mockNetworkInfo = MockNetworkInfo();
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
    when(() => mockNetworkInfo.hasRealConnection).thenAnswer((_) async => true);
    mockGetUserStream = MockGetUserStream();
    mockLogOut = MockLogOut();
    mockReloadUser = MockReloadUser();
    mockDeleteAccount = MockDeleteAccount();
    mockForgotPassword = MockForgotPassword();
    mockGetCurrentUser = MockGetCurrentUser();
    mockSendEmailVerification = MockSendEmailVerification();

    userStreamController = StreamController<UserEntity?>();

    when(() => mockNetworkInfo.setPremiumOverride(any())).thenReturn(null);

    when(
      () => mockGetUserStream(),
    ).thenAnswer((_) => userStreamController.stream);

    bloc = AuthBloc(
      getUserStream: mockGetUserStream,
      logOut: mockLogOut,
      reloadUser: mockReloadUser,
      deleteAccount: mockDeleteAccount,
      forgotPassword: mockForgotPassword,
      getCurrentUser: mockGetCurrentUser,
      sendEmailVerification: mockSendEmailVerification,
      networkInfo: mockNetworkInfo,
    );
  });

  tearDown(() {
    if (di.sl.isRegistered<NotificationService>()) {
      di.sl.unregister<NotificationService>();
    }
    userStreamController.close();
    bloc.close();
  });

  test('initial state should be unknown', () {
    expect(bloc.state, const AuthState.unknown());
  });

  group('AuthUserChanged', () {
    blocTest<AuthBloc, AuthState>(
      'should emit [unauthenticated] when user stream emits null',
      build: () => bloc,
      act: (bloc) => userStreamController.add(null),
      expect: () => [const AuthState.unauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'should emit [authenticated] when user stream emits user',
      build: () => bloc,
      act: (bloc) => userStreamController.add(tUser),
      expect: () => [AuthState.authenticated(tUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'should preserve optimistic level progress when user stream emits update',
      build: () => bloc,
      seed: () => AuthState.authenticated(
        tUser.copyWith(
          completedLevels: {
            'trueFalseReading': [1],
          },
          unlockedLevels: {
            'trueFalseReading': 2,
          },
        ),
      ),
      act: (bloc) => userStreamController.add(tUser),
      expect: () => [
        isA<AuthState>().having(
          (s) => s.user?.unlockedLevels['trueFalseReading'],
          'unlockedLevels',
          2,
        ).having(
          (s) => s.user?.completedLevels['trueFalseReading'],
          'completedLevels',
          [1],
        ),
      ],
    );
  });

  group('AuthLogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'should emit [loggingOut, unauthenticated] and call logOut',
      build: () {
        when(
          () => mockLogOut(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => [
        isA<AuthState>().having(
          (s) => s.status,
          'status',
          AuthStatus.loggingOut,
        ),
        isA<AuthState>().having(
          (s) => s.status,
          'status',
          AuthStatus.unauthenticated,
        ),
      ],
      verify: (_) {
        verify(() => mockLogOut(any())).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'should emit [loggingOut, authenticated] with network-unreachable if offline',
      build: () {
        when(() => mockNetworkInfo.hasRealConnection).thenAnswer((_) async => false);
        return bloc;
      },
      seed: () => AuthState.authenticated(tUser),
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => [
        isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loggingOut),
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.authenticated)
            .having((s) => s.message, 'message', 'auth.error.network_unreachable'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'should ignore intermediate AuthUserChanged events while status is loggingOut',
      build: () {
        when(() => mockLogOut(any())).thenAnswer((_) async {
          // Simulate slow logout during which an asynchronous Firestore snapshot arrives
          bloc.add(AuthUserChanged(tUser));
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return const Right(null);
        });
        return bloc;
      },
      seed: () => AuthState.authenticated(tUser),
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<AuthState>().having(
          (s) => s.status,
          'status',
          AuthStatus.loggingOut,
        ),
        isA<AuthState>().having(
          (s) => s.status,
          'status',
          AuthStatus.unauthenticated,
        ),
      ],
    );
  });

  group('AuthDeleteAccountRequested', () {
    blocTest<AuthBloc, AuthState>(
      'should emit [loggingOut, unauthenticated] with success message when delete succeeds',
      build: () {
        when(() => mockDeleteAccount(any())).thenAnswer(
          (_) async => const Right<Failure, void>(null) as Either<Failure, void>,
        );
        when(() => mockLogOut(any())).thenAnswer(
          (_) async => const Right<Failure, void>(null) as Either<Failure, void>,
        );
        return bloc;
      },
      seed: () => AuthState.authenticated(tUser),
      act: (bloc) => bloc.add(const AuthDeleteAccountRequested()),
      expect: () => [
        isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loggingOut),
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.unauthenticated)
            .having((s) => s.message, 'message', 'settings_dialogs.account_deleted_success'),
      ],
      verify: (_) {
        verify(() => mockDeleteAccount(any())).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'should emit [loggingOut, authenticated] with network-unreachable when offline',
      build: () {
        when(() => mockNetworkInfo.hasRealConnection).thenAnswer((_) async => false);
        return bloc;
      },
      seed: () => AuthState.authenticated(tUser),
      act: (bloc) => bloc.add(const AuthDeleteAccountRequested()),
      expect: () => [
        isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loggingOut),
        isA<AuthState>()
            .having((s) => s.status, 'status', AuthStatus.authenticated)
            .having((s) => s.message, 'message', 'auth.error.network_unreachable'),
      ],
    );
  });

  group('AuthLevelCompletedOptimistic', () {
    blocTest<AuthBloc, AuthState>(
      'should optimistically add level to completedLevels and increment unlockedLevels',
      build: () => bloc,
      seed: () => AuthState.authenticated(tUser),
      act: (bloc) => bloc.add(
        const AuthLevelCompletedOptimistic(
          gameType: 'trueFalseReading',
          level: 1,
        ),
      ),
      expect: () => [
        isA<AuthState>().having(
          (s) => s.user?.completedLevels['trueFalseReading'],
          'completedLevels',
          [1],
        ).having(
          (s) => s.user?.unlockedLevels['trueFalseReading'],
          'unlockedLevels',
          2,
        ),
      ],
    );
  });

  group('AuthRefreshUser', () {
    blocTest<AuthBloc, AuthState>(
      'should refresh user and preserve optimistic level unlocks',
      build: () {
        when(() => mockGetCurrentUser(any()))
            .thenAnswer((_) async => Right(tUser));
        return bloc;
      },
      seed: () => AuthState.authenticated(
        tUser.copyWith(
          completedLevels: {
            'trueFalseReading': [1],
          },
          unlockedLevels: {
            'trueFalseReading': 2,
          },
        ),
      ),
      act: (bloc) => bloc.add(const AuthRefreshUser()),
      expect: () => [
        isA<AuthState>().having(
          (s) => s.user?.unlockedLevels['trueFalseReading'],
          'unlockedLevels',
          2,
        ).having(
          (s) => s.user?.completedLevels['trueFalseReading'],
          'completedLevels',
          [1],
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthClearMessage clears the transient message in AuthState',
      build: () => bloc,
      seed: () => AuthState.authenticated(tUser).copyWith(
        message: () => 'auth.error.network_unreachable',
      ),
      act: (bloc) => bloc.add(const AuthClearMessage()),
      expect: () => [
        isA<AuthState>().having((s) => s.message, 'message', isNull),
      ],
    );
  });
}
