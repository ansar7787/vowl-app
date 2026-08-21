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
///
/// ### Error messages
/// Every error — client-side validation as much as a server/network
/// [Failure] — flows through the same [AuthErrorHandler.getKey] lookup, so
/// [errorMessage] is always a stable code the presentation layer can
/// localize, never a hardcoded English sentence. Previously the client-side
/// validation checks below (empty email, invalid format, no network) set
/// [errorMessage] to raw English text directly, bypassing
/// [AuthErrorHandler] entirely — meaning those three specific messages could
/// never have been localized no matter what l10n infrastructure existed
/// elsewhere, even though the *other* half of this same method (an actual
/// [Failure] from [_forgotPassword]) was already doing it correctly.
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

  // ---------------------------------------------------------------------------
  // Rate Limiting (Spam protection)
  // ---------------------------------------------------------------------------
  DateTime? _lastSentTime;

  void emailChanged(String value) =>
      emit(state.copyWith(email: value, errorMessage: () => null));

  Future<void> sendPasswordResetEmail() async {
    if (state.isSubmitting) return;

    if (_lastSentTime != null && DateTime.now().difference(_lastSentTime!).inSeconds < 60) {
      final secondsLeft = 60 - DateTime.now().difference(_lastSentTime!).inSeconds;
      emit(
        state.copyWith(
          errorMessage: () => 'Please wait $secondsLeft seconds before requesting another email.',
        ),
      );
      return;
    }

    final trimmedEmail = state.email.trim();

    if (trimmedEmail.isEmpty) {
      emit(
        state.copyWith(
          errorMessage: () => AuthErrorHandler.getKey('email-empty'),
        ),
      );
      return;
    }
    if (!_emailRegex.hasMatch(trimmedEmail)) {
      emit(
        state.copyWith(
          errorMessage: () => AuthErrorHandler.getKey('email-invalid'),
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
          errorMessage: () => AuthErrorHandler.getKey(failure.message),
        ),
      ),
      (_) {
        _lastSentTime = DateTime.now();
        emit(
          state.copyWith(
            isSubmitting: false,
            isSuccess: true,
            successMessage: () => 'forgot_password.reset_link_sent',
          ),
        );
      },
    );
  }
}
