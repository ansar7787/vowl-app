import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/domain/usecases/log_in_with_email.dart';
import 'package:vowl/features/auth/domain/usecases/log_in_with_google.dart';
import 'package:vowl/features/auth/domain/usecases/forgot_password.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/core/utils/auth_error_handler.dart';
import 'package:vowl/core/network/network_info.dart';

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

    if (_networkInfo != null && !(await _networkInfo.isConnected)) {
      emit(
        state.copyWith(
          errorMessage: "No internet connection. Please check your network.",
        ),
      );
      return;
    }

    emit(state.copyWith(isSubmitting: true));
    final result = await _logInWithEmail(
      LogInParams(email: state.email, password: state.password),
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

    if (_networkInfo != null && !(await _networkInfo.isConnected)) {
      emit(
        state.copyWith(
          errorMessage: "No internet connection. Please check your network.",
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

    if (_networkInfo != null && !(await _networkInfo.isConnected)) {
      emit(
        state.copyWith(
          errorMessage: "No internet connection. Please check your network.",
        ),
      );
      return;
    }

    emit(state.copyWith(isSubmitting: true));
    final result = await _forgotPassword(email);
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
