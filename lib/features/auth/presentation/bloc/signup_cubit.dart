import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/core/utils/auth_error_handler.dart';
import 'package:vowl/features/auth/domain/usecases/send_email_verification.dart';
import 'package:vowl/features/auth/domain/usecases/sign_up.dart';

// ============================================================================
// STATE
// ============================================================================

class SignUpState extends Equatable {
  final String name;
  final String email;
  final String password;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;
  final bool isPasswordVisible;

  const SignUpState({
    this.name = '',
    this.email = '',
    this.password = '',
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
    this.isPasswordVisible = false,
  });

  SignUpState copyWith({
    String? name,
    String? email,
    String? password,
    bool? isSubmitting,
    bool? isSuccess,
    String? Function()? errorMessage,
    bool? isPasswordVisible,
  }) {
    return SignUpState(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
    );
  }

  @override
  List<Object?> get props => [
    name,
    email,
    password,
    isSubmitting,
    isSuccess,
    errorMessage,
    isPasswordVisible,
  ];
}

// ============================================================================
// CUBIT
// ============================================================================

class SignUpCubit extends Cubit<SignUpState> {
  final SignUp _signUp;
  final SendEmailVerification _sendEmailVerification;
  final NetworkInfo? _networkInfo;

  /// Compiled once — avoids per-keystroke [RegExp] allocation.
  static final _emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');

  SignUpCubit({
    required SignUp signUp,
    required SendEmailVerification sendEmailVerification,
    NetworkInfo? networkInfo,
  }) : _signUp = signUp,
       _sendEmailVerification = sendEmailVerification,
       _networkInfo = networkInfo,
       super(const SignUpState());

  void nameChanged(String value) =>
      emit(state.copyWith(name: value, errorMessage: () => null));

  void emailChanged(String value) =>
      emit(state.copyWith(email: value, errorMessage: () => null));

  void passwordChanged(String value) =>
      emit(state.copyWith(password: value, errorMessage: () => null));

  void togglePasswordVisibility() =>
      emit(state.copyWith(isPasswordVisible: !state.isPasswordVisible));

  Future<void> signUp() async {
    if (state.isSubmitting) return;

    final trimmedName = state.name.trim();
    if (trimmedName.isEmpty) {
      emit(state.copyWith(errorMessage: () => 'Name cannot be empty.'));
      return;
    }
    if (trimmedName.length < 2) {
      emit(
        state.copyWith(
          errorMessage: () => 'Name must be at least 2 characters long.',
        ),
      );
      return;
    }

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

    final result = await _signUp(
      SignUpParams(
        name: trimmedName,
        email: trimmedEmail,
        password: state.password,
      ),
    );
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            isSubmitting: false,
            errorMessage: () => AuthErrorHandler.getKey(failure.message),
          ),
        );
      },
      (_) async {
        // Best-effort verification email; account creation already succeeded.
        final verificationResult = await _sendEmailVerification(
          const NoParams(),
        );
        if (isClosed) return;

        verificationResult.fold(
          (failure) => emit(
            state.copyWith(
              isSubmitting: false,
              isSuccess: true,
              errorMessage: () =>
                  'Account created, but verification email failed: ${failure.message}',
            ),
          ),
          (_) => emit(state.copyWith(isSubmitting: false, isSuccess: true)),
        );
      },
    );
  }
}
