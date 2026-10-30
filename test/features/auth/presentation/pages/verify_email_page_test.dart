import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/pages/verify_email_page.dart';
import 'package:vowl/features/auth/presentation/widgets/verify_email_widgets.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockThemeCubit extends MockCubit<ThemeState> implements ThemeCubit {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockThemeCubit mockThemeCubit;

  const testUser = UserEntity(
    id: 'user123',
    email: 'verify@vowl.app',
    displayName: 'Verification Tester',
    isEmailVerified: false,
  );

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockThemeCubit = MockThemeCubit();

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(testUser),
    );
    when(
      () => mockThemeCubit.state,
    ).thenReturn(ThemeState(themeMode: ThemeMode.system, isMidnight: false));
  });

  Widget createWidgetUnderTest() {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<ThemeCubit>.value(value: mockThemeCubit),
        ],
        child: const MaterialApp(home: VerifyEmailPage()),
      ),
    );
  }

  testWidgets('should render VerifyEmailPage components and email correctly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(VerifyEmailPage), findsOneWidget);
    expect(find.byType(VerifyEmailIconHeader), findsOneWidget);
    expect(find.byType(VerifyEmailStatusText), findsOneWidget);
    expect(find.text('verify@vowl.app'), findsOneWidget);
    expect(find.byType(OpenEmailAppButton), findsOneWidget);
    expect(find.byType(VerifyConfirmationButton), findsOneWidget);
    expect(find.byType(VerifyLogoutButton), findsOneWidget);
  });

  testWidgets('tapping I Have Verified button dispatches AuthReloadUser', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final verifyBtn = find.byType(VerifyConfirmationButton);
    expect(verifyBtn, findsOneWidget);
    await tester.ensureVisible(verifyBtn);

    await tester.tap(verifyBtn);
    await tester.pump();

    verify(() => mockAuthBloc.add(const AuthReloadUser())).called(greaterThanOrEqualTo(1));
  });

  testWidgets('tapping Logout button dispatches AuthLogoutRequested', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final logoutBtn = find.byType(VerifyLogoutButton);
    expect(logoutBtn, findsOneWidget);
    await tester.ensureVisible(logoutBtn);

    await tester.tap(logoutBtn);
    await tester.pump();

    verify(() => mockAuthBloc.add(const AuthLogoutRequested())).called(1);
  });
}
