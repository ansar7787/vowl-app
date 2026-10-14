import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/utils/injection_container.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/login_cubit.dart';
import 'package:vowl/features/auth/presentation/bloc/signup_cubit.dart';
import 'package:vowl/features/auth/presentation/pages/signup_page.dart';

class MockSignUpCubit extends MockCubit<SignUpState> implements SignUpCubit {}

class MockLoginCubit extends MockCubit<LoginState> implements LoginCubit {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockThemeCubit extends MockCubit<ThemeState> implements ThemeCubit {}

void main() {
  late MockSignUpCubit mockSignUpCubit;
  late MockLoginCubit mockLoginCubit;
  late MockAuthBloc mockAuthBloc;
  late MockThemeCubit mockThemeCubit;

  setUp(() {
    mockSignUpCubit = MockSignUpCubit();
    mockLoginCubit = MockLoginCubit();
    mockAuthBloc = MockAuthBloc();
    mockThemeCubit = MockThemeCubit();

    sl.allowReassignment = true;
    sl.registerFactory<SignUpCubit>(() => mockSignUpCubit);
    sl.registerFactory<LoginCubit>(() => mockLoginCubit);

    when(() => mockSignUpCubit.state).thenReturn(const SignUpState());
    when(() => mockLoginCubit.state).thenReturn(const LoginState());
    when(() => mockAuthBloc.state).thenReturn(const AuthState.unknown());
    when(
      () => mockThemeCubit.state,
    ).thenReturn(ThemeState(themeMode: ThemeMode.system, isMidnight: false));
  });

  Widget createWidgetUnderTest() {
    return ScreenUtilInit(
      designSize: const Size(800, 600),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<ThemeCubit>.value(value: mockThemeCubit),
        ],
        child: const MaterialApp(home: SignUpPage()),
      ),
    );
  }

  testWidgets('should render all SignUpPage components cleanly', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(SignUpPage), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);
    expect(find.text('Sign Up'), findsWidgets);
    expect(find.byType(Checkbox), findsOneWidget);
  });

  testWidgets('should show error snackbar when SignUpState has errorMessage', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    whenListen(
      mockSignUpCubit,
      Stream.fromIterable([
        const SignUpState(errorMessage: 'Sign up failed unexpectedly'),
      ]),
      initialState: const SignUpState(),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Sign up failed unexpectedly'), findsOneWidget);
  });

  testWidgets('should trigger nameChanged on text input in name field', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final nameField = find.byType(TextFormField).first;
    await tester.enterText(nameField, 'Jordan');
    await tester.pump();

    verify(() => mockSignUpCubit.nameChanged('Jordan')).called(1);
  });
}

