import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/domain/usecases/get_user_stream.dart';
import 'package:vowl/features/auth/domain/usecases/log_out.dart';
import 'package:vowl/features/auth/domain/usecases/reload_user.dart';
import 'package:vowl/features/auth/domain/usecases/delete_account.dart';
import 'package:vowl/features/auth/domain/usecases/forgot_password.dart';
import 'package:vowl/features/auth/domain/usecases/get_current_user.dart';
import 'package:vowl/core/usecases/usecase.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthUserChanged extends AuthEvent {
  final UserEntity? user;
  const AuthUserChanged(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthReloadUser extends AuthEvent {
  const AuthReloadUser();
}

class AuthRefreshUser extends AuthEvent {
  const AuthRefreshUser();
}

class AuthDeleteAccountRequested extends AuthEvent {
  const AuthDeleteAccountRequested();
}

class AuthPasswordResetRequested extends AuthEvent {
  final String email;
  const AuthPasswordResetRequested(this.email);
  @override
  List<Object?> get props => [email];
}


// States
enum AuthStatus { authenticated, unauthenticated, unknown, loggingOut }

class AuthState extends Equatable {
  final AuthStatus status;
  final UserEntity? user;
  final String? message;
  final bool isEmailVerified;

  const AuthState._({
    this.status = AuthStatus.unknown,
    this.user,
    this.message,
    this.isEmailVerified = false,
  });

  const AuthState.unknown() : this._();

  const AuthState.authenticated(UserEntity user) : this._(status: AuthStatus.authenticated, user: user);

  const AuthState.unauthenticated() : this._(status: AuthStatus.unauthenticated);

  @override
  List<Object?> get props => [status, user, message, isEmailVerified];

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? message,
    bool? isEmailVerified,
  }) {
    return AuthState._(
      status: status ?? this.status,
      user: user ?? this.user,
      message: message ?? this.message,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetUserStream _getUserStream;
  final LogOut _logOut;
  final ReloadUser _reloadUser;
  final DeleteAccount _deleteAccount;
  final ForgotPassword _forgotPassword;
  final GetCurrentUser _getCurrentUser;

  StreamSubscription<UserEntity?>? _userSubscription;

  AuthBloc({
    required GetUserStream getUserStream,
    required LogOut logOut,
    required ReloadUser reloadUser,
    required DeleteAccount deleteAccount,
    required ForgotPassword forgotPassword,
    required GetCurrentUser getCurrentUser,
  })  : _getUserStream = getUserStream,
        _logOut = logOut,
        _reloadUser = reloadUser,
        _deleteAccount = deleteAccount,
        _forgotPassword = forgotPassword,
        _getCurrentUser = getCurrentUser,
        super(const AuthState.unknown()) {
    on<AuthUserChanged>(_onUserChanged);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthReloadUser>(_onReloadUser);
    on<AuthRefreshUser>(_onRefreshUser);
    on<AuthDeleteAccountRequested>(_onDeleteAccountRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);

    _userSubscription = _getUserStream().listen(
      (user) => add(AuthUserChanged(user)),
    );
  }

  void _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    if (event.user != null) {
      emit(AuthState.authenticated(event.user!));
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loggingOut));
    await _logOut(NoParams());
    emit(const AuthState.unauthenticated());
  }

  Future<void> _onReloadUser(AuthReloadUser event, Emitter<AuthState> emit) async {
    await _reloadUser(NoParams());
  }

  Future<void> _onRefreshUser(AuthRefreshUser event, Emitter<AuthState> emit) async {
    final result = await _getCurrentUser(NoParams());
    result.fold(
      (failure) => emit(state.copyWith(message: failure.message)),
      (user) {
        if (user != null) {
          emit(AuthState.authenticated(user));
        }
      },
    );
  }

  Future<void> _onDeleteAccountRequested(AuthDeleteAccountRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loggingOut));
    final result = await _deleteAccount(NoParams());
    result.fold(
      (failure) {
        String message = failure.message;
        if (message == 'requires-recent-login') {
          message = 'SECURITY: Please log out and log back in before deleting your account.';
        }
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          message: message,
        ));
      },
      (_) => add(const AuthLogoutRequested()),
    );
  }

  Future<void> _onPasswordResetRequested(AuthPasswordResetRequested event, Emitter<AuthState> emit) async {
    final result = await _forgotPassword(event.email);
    result.fold(
      (failure) => emit(state.copyWith(message: failure.message)),
      (_) => emit(state.copyWith(message: 'Reset email sent!')),
    );
  }


  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}
