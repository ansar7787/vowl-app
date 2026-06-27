import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/core/utils/auth_error_handler.dart';
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
class LoginCubit extends Cubit<LoginState> {
  final LogInWithEmail _logInWithEmail;
  final LogInWithGoogle _logInWithGoogle;
  final NetworkInfo? _networkInfo;

  /// Compiled once per class — avoids a new [RegExp] allocation on every
  /// validation call. The `{2,}` TLD pattern accepts modern long-form TLDs
  /// such as `.academy`, `.international`, etc.
  static final _emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');

  LoginCubit({
    required LogInWithEmail logInWithEmail,
    required LogInWithGoogle logInWithGoogle,
    NetworkInfo? networkInfo,
  }) : _logInWithEmail = logInWithEmail,
       _logInWithGoogle = logInWithGoogle,
       _networkInfo = networkInfo,
       super(const LoginState());

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

    // Client-side validation
    final trimmedEmail = state.email.trim();
    if (trimmedEmail.isEmpty) {
      emit(
        state.copyWith(errorMessage: () => 'Email address cannot be empty.'),
      );
      return;
    }
    if (!_emailRegex.hasMatch(trimmedEmail)) {
      emit(
        state.copyWith(
          errorMessage: () => 'Please enter a valid email address.',
        ),
      );
      return;
    }
    if (state.password.isEmpty) {
      emit(state.copyWith(errorMessage: () => 'Password cannot be empty.'));
      return;
    }
    if (state.password.length < 6) {
      emit(
        state.copyWith(
          errorMessage: () => 'Password must be at least 6 characters long.',
        ),
      );
      return;
    }

    if (_networkInfo != null && !(await _networkInfo.isConnected)) {
      emit(
        state.copyWith(
          errorMessage: () =>
              'No internet connection. Please check your network.',
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
      (failure) => emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: () => AuthErrorHandler.getKey(failure.message),
        ),
      ),
      (_) => emit(state.copyWith(isSubmitting: false, isSuccess: true)),
    );
  }

  Future<void> logInWithGoogle() async {
    if (state.isSubmitting) return;

    if (_networkInfo != null && !(await _networkInfo.isConnected)) {
      emit(
        state.copyWith(
          errorMessage: () =>
              'No internet connection. Please check your network.',
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
      (isNewUser) => emit(state.copyWith(
        isSubmitting: false, 
        isSuccess: true,
        isNewUser: isNewUser,
      )),
    );
  }
}
