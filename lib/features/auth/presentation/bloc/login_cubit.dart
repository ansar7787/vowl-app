import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/domain/usecases/log_in_with_email.dart';
import 'package:vowl/features/auth/domain/usecases/log_in_with_google.dart';
import 'package:vowl/features/auth/domain/usecases/forgot_password.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/core/utils/auth_error_handler.dart';
import 'package:vowl/core/network/network_info.dart';

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

  const LoginState({
    this.email = '',
    this.password = '',
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
    this.successMessage,
    this.isPasswordVisible = false,
  });

  LoginState copyWith({
    String? email,
    String? password,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    String? successMessage,
    bool? isPasswordVisible,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
      successMessage: successMessage,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
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
  ];
}

// ============================================================================
// CUBIT
// ============================================================================
class LoginCubit extends Cubit<LoginState> {
  final LogInWithEmail _logInWithEmail;
  final LogInWithGoogle _logInWithGoogle;
  final ForgotPassword _forgotPassword;
  final NetworkInfo? _networkInfo;

  LoginCubit({
    required LogInWithEmail logInWithEmail,
    required LogInWithGoogle logInWithGoogle,
    required ForgotPassword forgotPassword,
    NetworkInfo? networkInfo,
  }) : _logInWithEmail = logInWithEmail,
       _logInWithGoogle = logInWithGoogle,
       _forgotPassword = forgotPassword,
       _networkInfo = networkInfo,
       super(const LoginState());

  void emailChanged(String value) => emit(state.copyWith(email: value));
  void passwordChanged(String value) => emit(state.copyWith(password: value));

  Future<void> logInWithCredentials() async {
    if (state.isSubmitting) return;

    // Client-side Input Validations
    final trimmedEmail = state.email.trim();
    if (trimmedEmail.isEmpty) {
      emit(state.copyWith(errorMessage: 'Email address cannot be empty.'));
      return;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(trimmedEmail)) {
      emit(state.copyWith(errorMessage: 'Please enter a valid email address.'));
      return;
    }
    if (state.password.isEmpty) {
      emit(state.copyWith(errorMessage: 'Password cannot be empty.'));
      return;
    }
    if (state.password.length < 6) {
      emit(state.copyWith(errorMessage: 'Password must be at least 6 characters long.'));
      return;
    }

    // Network Connectivity Verification
    if (_networkInfo != null && !(await _networkInfo.isConnected)) {
      emit(
        state.copyWith(
          errorMessage: 'No internet connection. Please check your network.',
        ),
      );
      return;
    }

    emit(state.copyWith(isSubmitting: true));
    final result = await _logInWithEmail(
      LogInParams(email: trimmedEmail, password: state.password),
    );
    
    result.fold(
      (failure) {
        if (isClosed) return;
        emit(
          state.copyWith(
            isSubmitting: false,
            errorMessage: AuthErrorHandler.getMessage(failure.message),
          ),
        );
      },
      (_) {
        if (isClosed) return;
        emit(state.copyWith(isSubmitting: false, isSuccess: true));
      },
    );
  }

  Future<void> logInWithGoogle() async {
    if (state.isSubmitting) return;

    // Network Connectivity Verification
    if (_networkInfo != null && !(await _networkInfo.isConnected)) {
      emit(
        state.copyWith(
          errorMessage: 'No internet connection. Please check your network.',
        ),
      );
      return;
    }

    emit(state.copyWith(isSubmitting: true));
    final result = await _logInWithGoogle(NoParams());
    
    result.fold(
      (failure) {
        if (isClosed) return;
        emit(
          state.copyWith(
            isSubmitting: false,
            errorMessage: AuthErrorHandler.getMessage(failure.message),
          ),
        );
      },
      (_) {
        if (isClosed) return;
        emit(state.copyWith(isSubmitting: false, isSuccess: true));
      },
    );
  }

  Future<void> forgotPassword(String email) async {
    if (state.isSubmitting) return;

    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      emit(state.copyWith(errorMessage: 'Please enter your email address to receive reset links.'));
      return;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(trimmedEmail)) {
      emit(state.copyWith(errorMessage: 'Please enter a valid email address.'));
      return;
    }

    // Network Connectivity Verification
    if (_networkInfo != null && !(await _networkInfo.isConnected)) {
      emit(
        state.copyWith(
          errorMessage: 'No internet connection. Please check your network.',
        ),
      );
      return;
    }

    emit(state.copyWith(isSubmitting: true));
    final result = await _forgotPassword(trimmedEmail);
    
    result.fold(
      (failure) {
        if (isClosed) return;
        emit(
          state.copyWith(
            isSubmitting: false,
            errorMessage: AuthErrorHandler.getMessage(failure.message),
          ),
        );
      },
      (_) {
        if (isClosed) return;
        emit(
          state.copyWith(
            isSubmitting: false,
            successMessage: 'Password reset link sent! Check your email.',
          ),
        );
      },
    );
  }

  void togglePasswordVisibility() {
    emit(state.copyWith(isPasswordVisible: !state.isPasswordVisible));
  }
}
