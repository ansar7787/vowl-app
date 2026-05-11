import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/domain/usecases/sign_up.dart';
import 'package:vowl/features/auth/domain/usecases/send_email_verification.dart';
import 'package:vowl/core/utils/auth_error_handler.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/core/network/network_info.dart';

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
    String? errorMessage,
    bool? isPasswordVisible,
  }) {
    return SignUpState(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
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

class SignUpCubit extends Cubit<SignUpState> {
  final SignUp _signUp;
  final SendEmailVerification _sendEmailVerification;
  final NetworkInfo? _networkInfo;

  SignUpCubit({
    required SignUp signUp,
    required SendEmailVerification sendEmailVerification,
    NetworkInfo? networkInfo,
  }) : _signUp = signUp,
       _sendEmailVerification = sendEmailVerification,
       _networkInfo = networkInfo,
       super(const SignUpState());

  void nameChanged(String value) => emit(state.copyWith(name: value));
  void emailChanged(String value) => emit(state.copyWith(email: value));
  void passwordChanged(String value) => emit(state.copyWith(password: value));

  Future<void> signUp() async {
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
    final result = await _signUp(
      SignUpParams(
        name: state.name,
        email: state.email,
        password: state.password,
      ),
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
      (_) async {
        // Send verification email
        final verificationResult = await _sendEmailVerification(NoParams());
        if (isClosed) return;
        verificationResult.fold(
          (failure) => emit(
            state.copyWith(
              isSubmitting: false,
              isSuccess: true, // Still success, but maybe show warning?
              errorMessage:
                  "Account created, but failed to send verification email: ${failure.message}",
            ),
          ),
          (_) => emit(state.copyWith(isSubmitting: false, isSuccess: true)),
        );
      },
    );
  }

  void togglePasswordVisibility() {
    emit(state.copyWith(isPasswordVisible: !state.isPasswordVisible));
  }
}
