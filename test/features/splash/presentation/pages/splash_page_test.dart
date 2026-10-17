// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/splash/presentation/pages/splash_page.dart';

// ---------------------------------------------------------------------------
// Mocks & Test Doubles
// ---------------------------------------------------------------------------

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthBloc mockAuthBloc;
  late StreamController<AuthState> authStateController;

  final testUser = UserEntity(
    id: 'user_123',
    email: 'quester@vowl.app',
    displayName: 'Test Quester',
    isEmailVerified: true,
    isPremium: false,
    coins: 100,
  );

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    authStateController = StreamController<AuthState>.broadcast();
    whenListen(mockAuthBloc, authStateController.stream, initialState: const AuthState.unknown());
  });

  tearDown(() async {
    await authStateController.close();
  });

  Widget buildTestableSplash({
    required AuthBloc authBloc,
    required GoRouter router,
    ThemeMode themeMode = ThemeMode.light,
    Size screenSize = const Size(390, 844),
    WidgetTester? tester,
  }) {
    if (tester != null) {
      tester.view.physicalSize = Size(screenSize.width * 2.0, screenSize.height * 2.0);
      tester.view.devicePixelRatio = 2.0;
    }

    return BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: MaterialApp.router(
        routerConfig: router,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeMode,
      ),
    );
  }

  GoRouter createTestRouter({required void Function(String route) onRouteNavigated}) {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: AppRouter.homeRoute,
          builder: (context, state) {
            onRouteNavigated(AppRouter.homeRoute);
            return const Scaffold(body: Text('Home Screen'));
          },
        ),
      ],
    );
  }

  // =========================================================================
  // GROUP 1: Initial Post-Frame Navigation Checks
  // =========================================================================
  group('Group 1: Initial Post-Frame Navigation Checks', () {
    testWidgets('stays on splash page when AuthStatus is unknown on initial frame', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.unknown());
      String? navigatedRoute;
      final router = createTestRouter(onRouteNavigated: (r) => navigatedRoute = r);

      await tester.pumpWidget(
        buildTestableSplash(
          authBloc: mockAuthBloc,
          router: router,
          tester: tester,
        ),
      );
      await tester.pump();

      expect(find.byType(SplashPage), findsOneWidget);
      expect(navigatedRoute, isNull);
      expect(find.text('Home Screen'), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('immediately navigates to /home when AuthStatus is authenticated on first frame', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(AuthState.authenticated(testUser));
      String? navigatedRoute;
      final router = createTestRouter(onRouteNavigated: (r) => navigatedRoute = r);

      await tester.pumpWidget(
        buildTestableSplash(
          authBloc: mockAuthBloc,
          router: router,
          tester: tester,
        ),
      );
      await tester.pumpAndSettle();

      expect(navigatedRoute, equals(AppRouter.homeRoute));
      expect(find.text('Home Screen'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('immediately navigates to /home when AuthStatus is unauthenticated on first frame', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.unauthenticated());
      String? navigatedRoute;
      final router = createTestRouter(onRouteNavigated: (r) => navigatedRoute = r);

      await tester.pumpWidget(
        buildTestableSplash(
          authBloc: mockAuthBloc,
          router: router,
          tester: tester,
        ),
      );
      await tester.pumpAndSettle();

      expect(navigatedRoute, equals(AppRouter.homeRoute));
      expect(find.text('Home Screen'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });

  // =========================================================================
  // GROUP 2: BlocListener Dynamic State Transitions
  // =========================================================================
  group('Group 2: BlocListener Dynamic State Transitions', () {
    testWidgets('navigates to /home when AuthBloc transitions from unknown to authenticated', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.unknown());
      String? navigatedRoute;
      final router = createTestRouter(onRouteNavigated: (r) => navigatedRoute = r);

      await tester.pumpWidget(
        buildTestableSplash(
          authBloc: mockAuthBloc,
          router: router,
          tester: tester,
        ),
      );
      await tester.pump();
      expect(navigatedRoute, isNull);

      // Auth resolves to authenticated
      when(() => mockAuthBloc.state).thenReturn(AuthState.authenticated(testUser));
      authStateController.add(AuthState.authenticated(testUser));
      await tester.pumpAndSettle();

      expect(navigatedRoute, equals(AppRouter.homeRoute));
      expect(find.text('Home Screen'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('navigates to /home when AuthBloc transitions from unknown to unauthenticated', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.unknown());
      String? navigatedRoute;
      final router = createTestRouter(onRouteNavigated: (r) => navigatedRoute = r);

      await tester.pumpWidget(
        buildTestableSplash(
          authBloc: mockAuthBloc,
          router: router,
          tester: tester,
        ),
      );
      await tester.pump();
      expect(navigatedRoute, isNull);

      // Auth resolves to unauthenticated
      when(() => mockAuthBloc.state).thenReturn(const AuthState.unauthenticated());
      authStateController.add(const AuthState.unauthenticated());
      await tester.pumpAndSettle();

      expect(navigatedRoute, equals(AppRouter.homeRoute));
      expect(find.text('Home Screen'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('does not navigate if new state remains unknown or status unchanged', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.unknown());
      String? navigatedRoute;
      final router = createTestRouter(onRouteNavigated: (r) => navigatedRoute = r);

      await tester.pumpWidget(
        buildTestableSplash(
          authBloc: mockAuthBloc,
          router: router,
          tester: tester,
        ),
      );
      await tester.pump();

      // Emit another unknown state
      authStateController.add(const AuthState.unknown());
      await tester.pump();

      expect(navigatedRoute, isNull);
      expect(find.byType(SplashPage), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('prevents duplicate navigation when state transitions occur multiple times', (tester) async {
      int navigationCount = 0;
      final router = createTestRouter(onRouteNavigated: (_) => navigationCount++);

      when(() => mockAuthBloc.state).thenReturn(AuthState.authenticated(testUser));

      await tester.pumpWidget(
        buildTestableSplash(
          authBloc: mockAuthBloc,
          router: router,
          tester: tester,
        ),
      );
      await tester.pumpAndSettle();
      expect(navigationCount, equals(1));

      // Attempt to push another authenticated state
      authStateController.add(AuthState.authenticated(testUser));
      await tester.pumpAndSettle();

      // Navigation count remains 1 because _hasNavigated guards against duplicate routing
      expect(navigationCount, equals(1));

      await tester.pumpWidget(const SizedBox());
    });
  });

  // =========================================================================
  // GROUP 3: Theming, System UI Overlay & Viewports
  // =========================================================================
  group('Group 3: Theming, System UI Overlay & Viewports', () {
    testWidgets('renders white background and dark system overlay in Light theme mode', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.unknown());
      final router = createTestRouter(onRouteNavigated: (_) {});

      await tester.pumpWidget(
        buildTestableSplash(
          authBloc: mockAuthBloc,
          router: router,
          themeMode: ThemeMode.light,
          tester: tester,
        ),
      );
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.white));

      final annotatedRegion = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
      );
      expect(annotatedRegion.value.systemNavigationBarColor, equals(Colors.white));
      expect(annotatedRegion.value.statusBarIconBrightness, equals(Brightness.dark));

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('renders slate900 background and light system overlay in Dark theme mode', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.unknown());
      final router = createTestRouter(onRouteNavigated: (_) {});

      await tester.pumpWidget(
        buildTestableSplash(
          authBloc: mockAuthBloc,
          router: router,
          themeMode: ThemeMode.dark,
          tester: tester,
        ),
      );
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(AppColors.slate900));

      final annotatedRegion = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
      );
      expect(annotatedRegion.value.systemNavigationBarColor, equals(AppColors.slate900));
      expect(annotatedRegion.value.statusBarIconBrightness, equals(Brightness.light));

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('renders cleanly on compact mobile viewport (320x568) with zero overflow', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.unknown());
      final router = createTestRouter(onRouteNavigated: (_) {});

      await tester.pumpWidget(
        buildTestableSplash(
          authBloc: mockAuthBloc,
          router: router,
          screenSize: const Size(320, 568),
          tester: tester,
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(SplashPage), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('renders cleanly on large tablet viewport (800x1280) with zero overflow', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.unknown());
      final router = createTestRouter(onRouteNavigated: (_) {});

      await tester.pumpWidget(
        buildTestableSplash(
          authBloc: mockAuthBloc,
          router: router,
          screenSize: const Size(800, 1280),
          tester: tester,
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(SplashPage), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });
}

