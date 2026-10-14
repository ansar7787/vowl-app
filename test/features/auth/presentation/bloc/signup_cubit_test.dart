import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/core/utils/auth_error_handler.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/domain/usecases/send_email_verification.dart';
import 'package:vowl/features/auth/domain/usecases/sign_up.dart';
import 'package:vowl/features/auth/presentation/bloc/signup_cubit.dart';

class MockSignUp extends Mock implements SignUp {}

class MockSendEmailVerification extends Mock implements SendEmailVerification {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late MockSignUp mockSignUp;
  late MockSendEmailVerification mockSendEmailVerification;
  late MockNetworkInfo mockNetworkInfo;
  late SignUpCubit cubit;

  setUpAll(() {
    registerFallbackValue(
      const SignUpParams(
        name: 'Test',
        email: 'test@example.com',
        password: 'password123',
      ),
    );
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    mockSignUp = MockSignUp();
    mockSendEmailVerification = MockSendEmailVerification();
    mockNetworkInfo = MockNetworkInfo();

    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    cubit = SignUpCubit(
      signUp: mockSignUp,
      sendEmailVerification: mockSendEmailVerification,
      networkInfo: mockNetworkInfo,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('SignUpCubit State Updates', () {
    test('initial state has default values', () {
      expect(cubit.state, equals(const SignUpState()));
    });

    blocTest<SignUpCubit, SignUpState>(
      'emits updated name and clears error',
      build: () => cubit,
      act: (c) => c.nameChanged('Alex'),
      expect: () => [const SignUpState(name: 'Alex')],
    );

    blocTest<SignUpCubit, SignUpState>(
      'emits updated email and clears error',
      build: () => cubit,
      act: (c) => c.emailChanged('alex@example.com'),
      expect: () => [const SignUpState(email: 'alex@example.com')],
    );

    blocTest<SignUpCubit, SignUpState>(
      'emits updated password and clears error',
      build: () => cubit,
      act: (c) => c.passwordChanged('secret123'),
      expect: () => [const SignUpState(password: 'secret123')],
    );

    blocTest<SignUpCubit, SignUpState>(
      'toggles password visibility correctly',
      build: () => cubit,
      act: (c) => c.togglePasswordVisibility(),
      expect: () => [const SignUpState(isPasswordVisible: true)],
    );
  });

  group('SignUpCubit Client-Side Validation', () {
    blocTest<SignUpCubit, SignUpState>(
      'emits error when name is empty',
      build: () => cubit,
      act: (c) => c.signUp(),
      expect: () => [
        SignUpState(errorMessage: AuthErrorHandler.getKey('name-empty')),
      ],
    );

    blocTest<SignUpCubit, SignUpState>(
      'emits error when name is too short',
      build: () => cubit,
      seed: () => const SignUpState(name: 'A'),
      act: (c) => c.signUp(),
      expect: () => [
        SignUpState(
          name: 'A',
          errorMessage: AuthErrorHandler.getKey('name-too-short'),
        ),
      ],
    );

    blocTest<SignUpCubit, SignUpState>(
      'emits error when email is empty',
      build: () => cubit,
      seed: () => const SignUpState(name: 'Alex'),
      act: (c) => c.signUp(),
      expect: () => [
        SignUpState(
          name: 'Alex',
          errorMessage: AuthErrorHandler.getKey('email-empty'),
        ),
      ],
    );

    blocTest<SignUpCubit, SignUpState>(
      'emits error when email format is invalid',
      build: () => cubit,
      seed: () => const SignUpState(name: 'Alex', email: 'invalid-email'),
      act: (c) => c.signUp(),
      expect: () => [
        SignUpState(
          name: 'Alex',
          email: 'invalid-email',
          errorMessage: AuthErrorHandler.getKey('email-invalid'),
        ),
      ],
    );

    blocTest<SignUpCubit, SignUpState>(
      'emits error when password is empty',
      build: () => cubit,
      seed: () => const SignUpState(name: 'Alex', email: 'alex@example.com'),
      act: (c) => c.signUp(),
      expect: () => [
        SignUpState(
          name: 'Alex',
          email: 'alex@example.com',
          errorMessage: AuthErrorHandler.getKey('password-empty'),
        ),
      ],
    );

    blocTest<SignUpCubit, SignUpState>(
      'emits error when password is shorter than 6 characters',
      build: () => cubit,
      seed: () => const SignUpState(
        name: 'Alex',
        email: 'alex@example.com',
        password: '123',
      ),
      act: (c) => c.signUp(),
      expect: () => [
        SignUpState(
          name: 'Alex',
          email: 'alex@example.com',
          password: '123',
          errorMessage: AuthErrorHandler.getKey('password-too-short'),
        ),
      ],
    );
  });

  group('SignUpCubit Execution & Network Flow', () {
    const validSeed = SignUpState(
      name: 'Alex',
      email: 'alex@example.com',
      password: 'password123',
    );

    blocTest<SignUpCubit, SignUpState>(
      'emits network unreachable when device is offline',
      build: () {
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        return cubit;
      },
      seed: () => validSeed,
      act: (c) => c.signUp(),
      expect: () => [
        validSeed.copyWith(isSubmitting: true),
        validSeed.copyWith(
          isSubmitting: false,
          errorMessage: () => AuthErrorHandler.getKey('network-unreachable'),
        ),
      ],
    );

    blocTest<SignUpCubit, SignUpState>(
      'emits success when signup and email verification succeed',
      build: () {
        when(
          () => mockSignUp(any()),
        ).thenAnswer(
          (_) async => const Right(
            UserEntity(id: 'u1', email: 'alex@example.com', displayName: 'Alex'),
          ),
        );
        when(
          () => mockSendEmailVerification(any()),
        ).thenAnswer((_) async => const Right(null));
        return cubit;
      },
      seed: () => validSeed,
      act: (c) => c.signUp(),
      expect: () => [
        validSeed.copyWith(isSubmitting: true),
        validSeed.copyWith(isSubmitting: false, isSuccess: true),
      ],
    );

    blocTest<SignUpCubit, SignUpState>(
      'emits success with warning message when verification email fails but account created',
      build: () {
        when(
          () => mockSignUp(any()),
        ).thenAnswer(
          (_) async => const Right(
            UserEntity(id: 'u1', email: 'alex@example.com', displayName: 'Alex'),
          ),
        );
        when(
          () => mockSendEmailVerification(any()),
        ).thenAnswer(
          (_) async => const Left(ServerFailure('email-send-fail')),
        );
        return cubit;
      },
      seed: () => validSeed,
      act: (c) => c.signUp(),
      expect: () => [
        validSeed.copyWith(isSubmitting: true),
        validSeed.copyWith(
          isSubmitting: false,
          isSuccess: true,
          errorMessage: () => 'signup.verification_email_failed',
        ),
      ],
    );

    blocTest<SignUpCubit, SignUpState>(
      'emits failure error when signup fails',
      build: () {
        when(
          () => mockSignUp(any()),
        ).thenAnswer(
          (_) async => const Left(ServerFailure('email-already-in-use')),
        );
        return cubit;
      },
      seed: () => validSeed,
      act: (c) => c.signUp(),
      expect: () => [
        validSeed.copyWith(isSubmitting: true),
        validSeed.copyWith(
          isSubmitting: false,
          errorMessage: () =>
              AuthErrorHandler.getKey('email-already-in-use'),
        ),
      ],
    );
  });
}
