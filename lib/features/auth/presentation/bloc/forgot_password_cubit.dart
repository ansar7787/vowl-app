import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/utils/auth_error_handler.dart';
import 'package:vowl/features/auth/domain/usecases/forgot_password.dart';

// ============================================================================
// STATE
// ============================================================================

class ForgotPasswordState extends Equatable {
  final String email;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;
  final String? successMessage;

  const ForgotPasswordState({
    this.email = '',
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
    this.successMessage,
  });

  ForgotPasswordState copyWith({
    String? email,
    bool? isSubmitting,
    bool? isSuccess,
    String? Function()? errorMessage,
    String? Function()? successMessage,
  }) {
    return ForgotPasswordState(
      email: email ?? this.email,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      successMessage: successMessage != null
          ? successMessage()
          : this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
    email,
    isSubmitting,
    isSuccess,
    errorMessage,
    successMessage,
  ];
}

// ============================================================================
// CUBIT
// ============================================================================

/// Manages the password-reset flow on the [ForgotPasswordPage].
///
/// Separated from [LoginCubit] to respect single-responsibility:
/// this cubit owns only the forgot-password submission lifecycle.
class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final ForgotPassword _forgotPassword;
  final NetworkInfo? _networkInfo;

  /// Compiled once — avoids per-keystroke [RegExp] allocation.
  /// `{2,}` accepts modern long-form TLDs (.academy, .international, etc.).
  static final _emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');

  ForgotPasswordCubit({
    required ForgotPassword forgotPassword,
    NetworkInfo? networkInfo,
  }) : _forgotPassword = forgotPassword,
       _networkInfo = networkInfo,
       super(const ForgotPasswordState());

  void emailChanged(String value) =>
      emit(state.copyWith(email: value, errorMessage: () => null));

  Future<void> sendPasswordResetEmail() async {
    if (state.isSubmitting) return;

    final trimmedEmail = state.email.trim();

    if (trimmedEmail.isEmpty) {
      emit(
        state.copyWith(
          errorMessage: () =>
              'Please enter your email address to receive reset links.',
        ),
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

    if (_networkInfo != null && !(await _networkInfo.isConnected)) {
      emit(
        state.copyWith(
          errorMessage: () =>
              'No internet connection. Please check your network.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isSubmitting: true,
        errorMessage: () => null,
        successMessage: () => null,
      ),
    );

    final result = await _forgotPassword(trimmedEmail);
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: () => AuthErrorHandler.getMessage(failure.message),
        ),
      ),
      (_) => emit(
        state.copyWith(
          isSubmitting: false,
          isSuccess: true,
          successMessage: () => 'Password reset link sent! Check your email.',
        ),
      ),
    );
  }
}
