import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/utils/injection_container.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/forgot_password_cubit.dart';
import 'package:vowl/features/auth/presentation/pages/forgot_password_page.dart';

class MockForgotPasswordCubit extends MockCubit<ForgotPasswordState>
    implements ForgotPasswordCubit {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockThemeCubit extends MockCubit<ThemeState> implements ThemeCubit {}

void main() {
  late MockForgotPasswordCubit mockForgotPasswordCubit;
  late MockAuthBloc mockAuthBloc;
  late MockThemeCubit mockThemeCubit;

  setUp(() {
    mockForgotPasswordCubit = MockForgotPasswordCubit();
    mockAuthBloc = MockAuthBloc();
    mockThemeCubit = MockThemeCubit();

    sl.allowReassignment = true;
    sl.registerFactory<ForgotPasswordCubit>(() => mockForgotPasswordCubit);

    when(() => mockForgotPasswordCubit.state)
        .thenReturn(const ForgotPasswordState());
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
        child: const MaterialApp(home: ForgotPasswordPage()),
      ),
    );
  }

  testWidgets('should render all ForgotPasswordPage components cleanly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(ForgotPasswordPage), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('should show error snackbar when ForgotPasswordState has error', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    whenListen(
      mockForgotPasswordCubit,
      Stream.fromIterable([
        const ForgotPasswordState(errorMessage: 'Email not found in system'),
      ]),
      initialState: const ForgotPasswordState(),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Email not found in system'), findsOneWidget);
  });

  testWidgets('should trigger emailChanged on entering text', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final emailField = find.byType(TextFormField).first;
    await tester.enterText(emailField, 'reset@vowl.app');
    await tester.pump();

    verify(() => mockForgotPasswordCubit.emailChanged('reset@vowl.app'))
        .called(1);
  });
}

