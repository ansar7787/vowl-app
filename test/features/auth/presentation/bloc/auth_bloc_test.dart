import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/domain/usecases/get_user_stream.dart';
import 'package:vowl/features/auth/domain/usecases/log_out.dart';
import 'package:vowl/features/auth/domain/usecases/reload_user.dart';
import 'package:vowl/features/auth/domain/usecases/delete_account.dart';
import 'package:vowl/features/auth/domain/usecases/forgot_password.dart';
import 'package:vowl/features/auth/domain/usecases/get_current_user.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

class MockGetUserStream extends Mock implements GetUserStream {}
class MockLogOut extends Mock implements LogOut {}
class MockReloadUser extends Mock implements ReloadUser {}
class MockDeleteAccount extends Mock implements DeleteAccount {}
class MockForgotPassword extends Mock implements ForgotPassword {}
class MockGetCurrentUser extends Mock implements GetCurrentUser {}

class FakeNoParams extends Fake implements NoParams {}

void main() {
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
  late StreamController<UserEntity?> userStreamController;

  final tUser = UserEntity(
    id: '1',
    email: 'test@vowl.com',
    displayName: 'Test User',
  );

  setUp(() {
    mockGetUserStream = MockGetUserStream();
    mockLogOut = MockLogOut();
    mockReloadUser = MockReloadUser();
    mockDeleteAccount = MockDeleteAccount();
    mockForgotPassword = MockForgotPassword();
    mockGetCurrentUser = MockGetCurrentUser();
    userStreamController = StreamController<UserEntity?>();

    when(() => mockGetUserStream()).thenAnswer((_) => userStreamController.stream);

    bloc = AuthBloc(
      getUserStream: mockGetUserStream,
      logOut: mockLogOut,
      reloadUser: mockReloadUser,
      deleteAccount: mockDeleteAccount,
      forgotPassword: mockForgotPassword,
      getCurrentUser: mockGetCurrentUser,
    );
  });

  tearDown(() {
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
      expect: () => [
        const AuthState.unauthenticated(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'should emit [authenticated] when user stream emits user',
      build: () => bloc,
      act: (bloc) => userStreamController.add(tUser),
      expect: () => [
        AuthState.authenticated(tUser),
      ],
    );
  });

  group('AuthLogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'should emit [loggingOut, unauthenticated] and call logOut',
      build: () {
        when(() => mockLogOut(any())).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => [
        isA<AuthState>().having((s) => s.status, 'status', AuthStatus.loggingOut),
        isA<AuthState>().having((s) => s.status, 'status', AuthStatus.unauthenticated),
      ],
      verify: (_) {
        verify(() => mockLogOut(any())).called(1);
      },
    );
  });
}
