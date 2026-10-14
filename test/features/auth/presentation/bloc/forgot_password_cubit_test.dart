import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/utils/auth_error_handler.dart';
import 'package:vowl/features/auth/domain/usecases/forgot_password.dart';
import 'package:vowl/features/auth/presentation/bloc/forgot_password_cubit.dart';

class MockForgotPassword extends Mock implements ForgotPassword {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late MockForgotPassword mockForgotPassword;
  late MockNetworkInfo mockNetworkInfo;
  late ForgotPasswordCubit cubit;

  setUp(() {
    mockForgotPassword = MockForgotPassword();
    mockNetworkInfo = MockNetworkInfo();

    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    cubit = ForgotPasswordCubit(
      forgotPassword: mockForgotPassword,
      networkInfo: mockNetworkInfo,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('ForgotPasswordCubit State & Input', () {
    test('initial state has default empty values', () {
      expect(cubit.state, equals(const ForgotPasswordState()));
    });

    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'emits updated email and clears error',
      build: () => cubit,
      act: (c) => c.emailChanged('reset@example.com'),
      expect: () => [const ForgotPasswordState(email: 'reset@example.com')],
    );
  });

  group('ForgotPasswordCubit Validation', () {
    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'emits error when email is empty',
      build: () => cubit,
      act: (c) => c.sendPasswordResetEmail(),
      expect: () => [
        ForgotPasswordState(
          errorMessage: AuthErrorHandler.getKey('email-empty'),
        ),
      ],
    );

    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'emits error when email format is invalid',
      build: () => cubit,
      seed: () => const ForgotPasswordState(email: 'invalid-email-address'),
      act: (c) => c.sendPasswordResetEmail(),
      expect: () => [
        ForgotPasswordState(
          email: 'invalid-email-address',
          errorMessage: AuthErrorHandler.getKey('email-invalid'),
        ),
      ],
    );
  });

  group('ForgotPasswordCubit Execution & Network Flow', () {
    const validSeed = ForgotPasswordState(email: 'reset@example.com');

    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'emits network unreachable when device is offline',
      build: () {
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        return cubit;
      },
      seed: () => validSeed,
      act: (c) => c.sendPasswordResetEmail(),
      expect: () => [
        validSeed.copyWith(isSubmitting: true),
        validSeed.copyWith(
          isSubmitting: false,
          errorMessage: () => AuthErrorHandler.getKey('network-unreachable'),
        ),
      ],
    );

    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'emits success when password reset email is sent successfully',
      build: () {
        when(
          () => mockForgotPassword('reset@example.com'),
        ).thenAnswer((_) async => const Right(null));
        return cubit;
      },
      seed: () => validSeed,
      act: (c) => c.sendPasswordResetEmail(),
      expect: () => [
        validSeed.copyWith(isSubmitting: true),
        validSeed.copyWith(
          isSubmitting: false,
          isSuccess: true,
          successMessage: () => 'forgot_password.reset_link_sent',
        ),
      ],
    );

    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'emits error when server returns failure',
      build: () {
        when(
          () => mockForgotPassword('reset@example.com'),
        ).thenAnswer(
          (_) async => const Left(ServerFailure('user-not-found')),
        );
        return cubit;
      },
      seed: () => validSeed,
      act: (c) => c.sendPasswordResetEmail(),
      expect: () => [
        validSeed.copyWith(isSubmitting: true),
        validSeed.copyWith(
          isSubmitting: false,
          errorMessage: () => AuthErrorHandler.getKey('user-not-found'),
        ),
      ],
    );

    test('rate limits consecutive reset requests within 60 seconds', () async {
      when(
        () => mockForgotPassword('reset@example.com'),
      ).thenAnswer((_) async => const Right(null));

      cubit.emailChanged('reset@example.com');
      await cubit.sendPasswordResetEmail();

      expect(cubit.state.isSuccess, isTrue);

      // Trigger second time immediately
      await cubit.sendPasswordResetEmail();

      expect(
        cubit.state.errorMessage,
        equals(AuthErrorHandler.getKey('rate-limited')),
      );
    });
  });
}

