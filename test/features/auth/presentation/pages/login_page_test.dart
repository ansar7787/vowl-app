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
import 'package:vowl/features/auth/presentation/pages/login_page.dart';

class MockLoginCubit extends MockCubit<LoginState> implements LoginCubit {}
class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}
class MockThemeCubit extends MockCubit<ThemeState> implements ThemeCubit {}

void main() {
  late MockLoginCubit mockLoginCubit;
  late MockAuthBloc mockAuthBloc;
  late MockThemeCubit mockThemeCubit;

  setUp(() {
    mockLoginCubit = MockLoginCubit();
    mockAuthBloc = MockAuthBloc();
    mockThemeCubit = MockThemeCubit();

    // Register in sl for LoginPage
    sl.allowReassignment = true;
    sl.registerFactory<LoginCubit>(() => mockLoginCubit);

    when(() => mockLoginCubit.state).thenReturn(const LoginState());
    when(() => mockAuthBloc.state).thenReturn(const AuthState.unknown());
    when(() => mockThemeCubit.state).thenReturn(ThemeState(themeMode: ThemeMode.system, isMidnight: false));
  });

  Widget createWidgetUnderTest() {
    // Force designSize to match physical size to prevent scaling artifacts in tests
    return ScreenUtilInit(
      designSize: const Size(800, 600),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<ThemeCubit>.value(value: mockThemeCubit),
        ],
        child: const MaterialApp(
          home: LoginPage(),
        ),
      ),
    );
  }

  testWidgets('should render login page components', (tester) async {
    // Standard test size
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Vowl'), findsOneWidget);
    expect(find.text('Login to continue your adventure'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });

  testWidgets('should show error message when LoginState has error', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    whenListen(
      mockLoginCubit,
      Stream.fromIterable([
        const LoginState(errorMessage: 'Invalid credentials'),
      ]),
      initialState: const LoginState(),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Invalid credentials'), findsOneWidget);
  });
}
