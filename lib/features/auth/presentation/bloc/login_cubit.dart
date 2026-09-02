import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/core/utils/auth_error_handler.dart';
import 'package:vowl/features/auth/domain/constants/auth_validators.dart';
import 'package:vowl/features/auth/domain/usecases/log_in_with_email.dart';
import 'package:vowl/features/auth/domain/usecases/log_in_with_google.dart';

// ============================================================================
// STATE
// ============================================================================

class LoginState extends Equatable {
  final String email;
  final String password;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;
  final String? successMessage;
  final bool isPasswordVisible;
  final bool isNewUser;

  const LoginState({
    this.email = '',
    this.password = '',
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
    this.successMessage,
    this.isPasswordVisible = false,
    this.isNewUser = false,
  });

  /// Uses the nullable-function pattern so callers can:
  /// - Preserve existing value: omit the parameter
  /// - Clear to null: `errorMessage: () => null`
  /// - Set new value: `errorMessage: () => 'some error'`
  ///
  /// This prevents `emit(state.copyWith(isSubmitting: true))` from
  /// accidentally clearing an existing [errorMessage].
  LoginState copyWith({
    String? email,
    String? password,
    bool? isSubmitting,
    bool? isSuccess,
    String? Function()? errorMessage,
    String? Function()? successMessage,
    bool? isPasswordVisible,
    bool? isNewUser,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      successMessage: successMessage != null
          ? successMessage()
          : this.successMessage,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isNewUser: isNewUser ?? this.isNewUser,
    );
  }

  @override
  List<Object?> get props => [
    email,
    password,
    isSubmitting,
    isSuccess,
    errorMessage,
    successMessage,
    isPasswordVisible,
    isNewUser,
  ];
}

// ============================================================================
// CUBIT
// ============================================================================

/// Manages the sign-in flow for email/password and Google authentication.
///
/// ### Responsibilities
/// - Client-side input validation before any network call
/// - Network-connectivity pre-check via optional [NetworkInfo]
/// - Delegation to [LogInWithEmail] and [LogInWithGoogle] use cases
///
/// ### Removed: ForgotPassword
/// Password-reset is the responsibility of [ForgotPasswordCubit] which has
/// its own dedicated page. The previous duplication (having [forgotPassword]
/// in both this cubit and [ForgotPasswordCubit]) has been removed.
///
/// ### Error messages
/// Every error, client-side validation included, now flows through
/// [AuthErrorHandler.getKey] — see [ForgotPasswordCubit]'s class doc for why
/// this changed (the validation checks below previously set [errorMessage]
/// to raw, unlocalizable English sentences directly).
class LoginCubit extends Cubit<LoginState> {
  final LogInWithEmail _logInWithEmail;
  final LogInWithGoogle _logInWithGoogle;
  final NetworkInfo? _networkInfo;

  LoginCubit({
    required LogInWithEmail logInWithEmail,
    required LogInWithGoogle logInWithGoogle,
    NetworkInfo? networkInfo,
  }) : _logInWithEmail = logInWithEmail,
       _logInWithGoogle = logInWithGoogle,
       _networkInfo = networkInfo,
       super(const LoginState());

  // ---------------------------------------------------------------------------
  // Rate Limiting (Brute-force protection)
  // ---------------------------------------------------------------------------
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  // ---------------------------------------------------------------------------
  // Field change handlers
  // ---------------------------------------------------------------------------

  void emailChanged(String value) =>
      emit(state.copyWith(email: value, errorMessage: () => null));

  void passwordChanged(String value) =>
      emit(state.copyWith(password: value, errorMessage: () => null));

  void togglePasswordVisibility() =>
      emit(state.copyWith(isPasswordVisible: !state.isPasswordVisible));

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> logInWithCredentials() async {
    if (state.isSubmitting) return;

    if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
      emit(
        state.copyWith(
          errorMessage: () => AuthErrorHandler.getKey('too-many-attempts'),
        ),
      );
      return;
    }

    // Client-side validation
    final trimmedEmail = state.email.trim();
    if (trimmedEmail.isEmpty) {
      emit(
        state.copyWith(
          errorMessage: () => AuthErrorHandler.getKey('email-empty'),
        ),
      );
      return;
    }
    if (!AuthValidators.emailRegex.hasMatch(trimmedEmail)) {
      emit(
        state.copyWith(
          errorMessage: () => AuthErrorHandler.getKey('email-invalid'),
        ),
      );
      return;
    }
    if (state.password.isEmpty) {
      emit(
        state.copyWith(
          errorMessage: () => AuthErrorHandler.getKey('password-empty'),
        ),
      );
      return;
    }
    if (state.password.length < 6) {
      emit(
        state.copyWith(
          errorMessage: () => AuthErrorHandler.getKey('password-too-short'),
        ),
      );
      return;
    }

    if (_networkInfo != null && !(await _networkInfo.isConnected)) {
      emit(
        state.copyWith(
          errorMessage: () => AuthErrorHandler.getKey('network-unreachable'),
        ),
      );
      return;
    }

    emit(state.copyWith(isSubmitting: true, errorMessage: () => null));
    final result = await _logInWithEmail(
      LogInParams(email: trimmedEmail, password: state.password),
    );
    if (isClosed) return;

    result.fold(
      (failure) {
        _failedAttempts++;
        if (_failedAttempts >= 5) {
          // Lockout duration grows: 1 min, 2 min, 3 min...
          _lockoutUntil = DateTime.now().add(
            Duration(minutes: _failedAttempts - 4),
          );
        }
        emit(
          state.copyWith(
            isSubmitting: false,
            errorMessage: () => AuthErrorHandler.getKey(failure.message),
          ),
        );
      },
      (_) {
        _failedAttempts = 0;
        _lockoutUntil = null;
        emit(state.copyWith(isSubmitting: false, isSuccess: true));
      },
    );
  }

  Future<void> logInWithGoogle() async {
    if (state.isSubmitting) return;

    if (_networkInfo != null && !(await _networkInfo.isConnected)) {
      emit(
        state.copyWith(
          errorMessage: () => AuthErrorHandler.getKey('network-unreachable'),
        ),
      );
      return;
    }

    emit(state.copyWith(isSubmitting: true, errorMessage: () => null));
    final result = await _logInWithGoogle(const NoParams());
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: () => AuthErrorHandler.getKey(failure.message),
        ),
      ),
      (isNewUser) => emit(
        state.copyWith(
          isSubmitting: false,
          isSuccess: true,
          isNewUser: isNewUser,
        ),
      ),
    );
  }
}
