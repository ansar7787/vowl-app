import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/domain/usecases/delete_account.dart';
import 'package:vowl/features/auth/domain/usecases/forgot_password.dart';
import 'package:vowl/features/auth/domain/usecases/get_current_user.dart';
import 'package:vowl/features/auth/domain/usecases/get_user_stream.dart';
import 'package:vowl/features/auth/domain/usecases/log_out.dart';
import 'package:vowl/features/auth/domain/usecases/reload_user.dart';
import 'package:vowl/features/auth/domain/usecases/send_email_verification.dart';
import 'package:vowl/core/network/network_info.dart';

// ============================================================================
// EVENTS
// ============================================================================

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

/// Emitted by the internal user stream whenever the Firebase Auth state or
/// the Firestore profile changes.
class AuthUserChanged extends AuthEvent {
  final UserEntity? user;
  const AuthUserChanged(this.user);
  @override
  List<Object?> get props => [user];
}

/// Requests a sign-out from Firebase Auth (and Google provider if active).
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Forces a Firebase Auth user reload and re-emits the updated user via the
/// stream. Used after email verification or profile changes.
class AuthReloadUser extends AuthEvent {
  const AuthReloadUser();
}

/// One-shot Firestore fetch of the current user profile. Prefer [AuthReloadUser]
/// for post-change refreshes.
class AuthRefreshUser extends AuthEvent {
  const AuthRefreshUser();
}

/// Permanently deletes the authenticated user's account, Firestore document,
/// and all associated data.
class AuthDeleteAccountRequested extends AuthEvent {
  const AuthDeleteAccountRequested();
}

/// Dispatches a password-reset email for [email].
class AuthPasswordResetRequested extends AuthEvent {
  final String email;
  const AuthPasswordResetRequested(this.email);
  @override
  List<Object?> get props => [email];
}

/// Sends a verification email to the currently authenticated user's address.
/// The result is communicated via [AuthState.message]:
/// - success: `'auth.email_verification_sent'` (a localization key)
/// - failure: the raw [Failure.message]
class AuthSendEmailVerificationRequested extends AuthEvent {
  const AuthSendEmailVerificationRequested();
}

// ============================================================================
// STATE
// ============================================================================

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

  const AuthState.authenticated(UserEntity user)
    : this._(status: AuthStatus.authenticated, user: user);

  const AuthState.unauthenticated()
    : this._(status: AuthStatus.unauthenticated);

  /// Supports explicit [null] clearing of [message] via:
  /// `state.copyWith(message: () => null)`
  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? Function()? message,
    bool? isEmailVerified,
  }) {
    return AuthState._(
      status: status ?? this.status,
      user: user ?? this.user,
      message: message != null ? message() : this.message,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }

  @override
  List<Object?> get props => [status, user, message, isEmailVerified];
}

// ============================================================================
// BLOC
// ============================================================================

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetUserStream _getUserStream;
  final LogOut _logOut;
  final ReloadUser _reloadUser;
  final DeleteAccount _deleteAccount;
  final ForgotPassword _forgotPassword;
  final GetCurrentUser _getCurrentUser;
  final SendEmailVerification _sendEmailVerification;
  final NetworkInfo _networkInfo;

  StreamSubscription<UserEntity?>? _userSubscription;

  AuthBloc({
    required GetUserStream getUserStream,
    required LogOut logOut,
    required ReloadUser reloadUser,
    required DeleteAccount deleteAccount,
    required ForgotPassword forgotPassword,
    required GetCurrentUser getCurrentUser,
    required SendEmailVerification sendEmailVerification,
    required NetworkInfo networkInfo,
  }) : _getUserStream = getUserStream,
       _logOut = logOut,
       _reloadUser = reloadUser,
       _deleteAccount = deleteAccount,
       _forgotPassword = forgotPassword,
       _getCurrentUser = getCurrentUser,
       _sendEmailVerification = sendEmailVerification,
       _networkInfo = networkInfo,
       super(const AuthState.unknown()) {
    on<AuthUserChanged>(_onUserChanged);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthReloadUser>(_onReloadUser);
    on<AuthRefreshUser>(_onRefreshUser);
    on<AuthDeleteAccountRequested>(_onDeleteAccountRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthSendEmailVerificationRequested>(_onSendEmailVerification);

    _userSubscription = _getUserStream().listen(
      (user) => add(AuthUserChanged(user)),
      onError: (_) {},
    );
  }

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  void _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    _networkInfo.setPremiumOverride(event.user?.isPremium ?? false);
    
    if (event.user != null) {
      emit(AuthState.authenticated(event.user!));
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state.status == AuthStatus.loggingOut) return;
    emit(state.copyWith(status: AuthStatus.loggingOut));
    await _logOut(const NoParams());
    emit(const AuthState.unauthenticated());
  }

  Future<void> _onReloadUser(
    AuthReloadUser event,
    Emitter<AuthState> emit,
  ) async {
    await _reloadUser(const NoParams());
    // The user stream subscription receives the updated auth state
    // automatically — no explicit emit required here.
  }

  Future<void> _onRefreshUser(
    AuthRefreshUser event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _getCurrentUser(const NoParams());
    result.fold(
      (failure) => emit(state.copyWith(message: () => failure.message)),
      (user) {
        if (user != null) emit(AuthState.authenticated(user));
      },
    );
  }

  Future<void> _onDeleteAccountRequested(
    AuthDeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state.status == AuthStatus.loggingOut) return;
    emit(state.copyWith(status: AuthStatus.loggingOut));

    final result = await _deleteAccount(const NoParams());
    await result.fold(
      (failure) async {
        if (failure.message == 'requires-recent-login') {
          await _logOut(const NoParams());
          emit(
            state.copyWith(
              status: AuthStatus.unauthenticated,
              message: () => 'settings_dialogs.requires_recent_login_delete',
            ),
          );
        } else {
          emit(
            state.copyWith(
              status: AuthStatus.authenticated,
              message: () => failure.message,
            ),
          );
        }
      },
      (_) async {
        await _logOut(const NoParams());
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            message: () => 'settings_dialogs.account_deleted_success',
          ),
        );
      },
    );
  }

  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _forgotPassword(event.email);
    result.fold(
      (failure) => emit(state.copyWith(message: () => failure.message)),
      (_) => emit(state.copyWith(message: () => 'auth.password_reset_sent')),
    );
  }

  /// Sends a verification email to the currently authenticated user.
  ///
  /// On success emits [AuthState.message] = `'auth.email_verification_sent'`
  /// (a localization key). The global [BlocListener] in [main.dart] translates
  /// and shows this as a snackbar; the [VerifyEmailPage] listener uses it
  /// to restart the resend cooldown timer.
  Future<void> _onSendEmailVerification(
    AuthSendEmailVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _sendEmailVerification(const NoParams());
    result.fold(
      (failure) => emit(state.copyWith(message: () => failure.message)),
      (_) =>
          emit(state.copyWith(message: () => 'auth.email_verification_sent')),
    );
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}
