import 'package:vowl/core/error/failures.dart';
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
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
import 'package:vowl/core/utils/notification_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:flutter/painting.dart' show imageCache;
import 'package:shared_preferences/shared_preferences.dart';

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

/// Internal event carrying an error observed on the underlying user stream.
/// Not dispatched by the presentation layer.
class AuthStreamErrorOccurred extends AuthEvent {
  const AuthStreamErrorOccurred();
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

  /// [isEmailVerified] is always derived from [user] here, so every path
  /// that constructs an authenticated state — the live user-stream listener
  /// and the one-shot refresh — gets it for free. Previously this field was
  /// declared on [AuthState] but never actually set anywhere: every
  /// authenticated state kept it at its `false` default regardless of the
  /// user's real verification status, since callers only ever read it from
  /// `state.user?.isEmailVerified` while `state.isEmailVerified` quietly sat
  /// unused. Any code that *was* reading `state.isEmailVerified` directly
  /// (e.g. to gate a "please verify your email" banner) would have seen
  /// `false` forever, even for verified users.
  AuthState.authenticated(UserEntity user)
    : this._(
        status: AuthStatus.authenticated,
        user: user,
        isEmailVerified: user.isEmailVerified,
      );

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
    on<AuthStreamErrorOccurred>(_onStreamError);

    _userSubscription = _getUserStream().listen(
      (user) => add(AuthUserChanged(user)),
      // Previously `onError: (_) => const Right<Failure, void>(null)` — silently discarded every error from
      // the user stream with no logging and no signal to the UI. The
      // repository layer already filters out the one *expected* noisy case
      // (permission-denied immediately after logout) before it ever reaches
      // here, so anything that does arrive is a genuine, unexpected failure
      // worth knowing about. `onError` callbacks can't call `emit`
      // directly (only registered event handlers can), so this dispatches
      // an event instead, following the same pattern as the `onData` branch
      // right above it.
      onError: (_) => add(const AuthStreamErrorOccurred()),
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

  void _onStreamError(AuthStreamErrorOccurred event, Emitter<AuthState> emit) {
    if (kDebugMode) {
      debugPrint('AuthBloc: unexpected user-stream error.');
    }
    // Deliberately not forcing a logout or clearing `state.user` here — a
    // stream error (e.g. a transient Firestore hiccup) is not the same
    // signal as an explicit auth-state-changed(null) event, and treating it
    // as one could log a still-valid session out from under the user over
    // a blip that would have self-corrected on reconnection.
    emit(state.copyWith(message: () => 'auth.stream_error'));
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state.status == AuthStatus.loggingOut) return;
    emit(state.copyWith(status: AuthStatus.loggingOut));

    // Cancel all scheduled local notifications (streak reminders, weekly
    // motivation, etc.) so they don't fire for the NEXT user who logs in on
    // this device. Without this, User A's streak reminder could appear after
    // User B signs in — a privacy and UX violation.
    try {
      await di.sl<NotificationService>().cancelAllReminders();
    } catch (e) {
      if (kDebugMode) debugPrint('AuthBloc: notification cleanup failed: $e');
    }

    // Clear the in-memory image cache so stale profile photos / avatars from
    // the previous user don't flash on the next sign-in.
    imageCache.clear();
    imageCache.clearLiveImages();

    try {
      final prefs = await SharedPreferences.getInstance();

      final themeMode = prefs.getString('theme_mode');
      final isMidnight = prefs.getBool('is_midnight');
      final appLocale = prefs.getString('app_locale');
      final targetLanguage = prefs.getString('target_language');
      final soundEnabled = prefs.getBool('sound_enabled');
      final notificationsEnabled = prefs.getBool('notifications_enabled');
      final reduceComplexGestures = prefs.getBool('reduce_complex_gestures');
      final notificationCardDismissedTime = prefs.getInt(
        'notification_card_dismissed_time',
      );

      await prefs.clear();

      if (themeMode != null) {
        await prefs.setString('theme_mode', themeMode);
      }
      if (isMidnight != null) {
        await prefs.setBool('is_midnight', isMidnight);
      }
      if (appLocale != null) {
        await prefs.setString('app_locale', appLocale);
      }
      if (targetLanguage != null) {
        await prefs.setString('target_language', targetLanguage);
      }
      if (soundEnabled != null) {
        await prefs.setBool('sound_enabled', soundEnabled);
      }
      if (notificationsEnabled != null) {
        await prefs.setBool('notifications_enabled', notificationsEnabled);
      }
      if (reduceComplexGestures != null) {
        await prefs.setBool('reduce_complex_gestures', reduceComplexGestures);
      }
      if (notificationCardDismissedTime != null) {
        await prefs.setInt(
          'notification_card_dismissed_time',
          notificationCardDismissedTime,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthBloc: SharedPreferences cleanup failed: $e');
      }
    }

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

    try {
      await di.sl<NotificationService>().cancelAllReminders();
    } catch (e) {
      if (kDebugMode) debugPrint('AuthBloc: notification cleanup failed: $e');
    }

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
