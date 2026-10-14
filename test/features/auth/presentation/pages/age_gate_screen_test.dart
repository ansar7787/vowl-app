import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/age_gate_service.dart';
import 'package:vowl/features/auth/presentation/pages/age_gate_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createWidgetUnderTest() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const AgeGateScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const SizedBox(),
        ),
        GoRoute(
          path: '/kids_zone',
          builder: (context, state) => const SizedBox(),
        ),
      ],
    );

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('should render AgeGateScreen components cleanly', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(AgeGateScreen), findsOneWidget);
    expect(find.text('Before we begin'), findsOneWidget);
    expect(find.text("I'm 16 or older"), findsOneWidget);
    expect(find.text("I'm under 16"), findsOneWidget);
  });

  testWidgets('tapping adult button completes age gate as adult', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final adultBtn = find.text("I'm 16 or older");
    expect(adultBtn, findsOneWidget);

    await tester.tap(adultBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final isAdult = await AgeGateService.isAdult();
    expect(isAdult, isTrue);
  });

  testWidgets('tapping child button opens confirmation sheet', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final childBtn = find.text("I'm under 16");
    expect(childBtn, findsOneWidget);

    await tester.tap(childBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Wait, Are You Sure?'), findsOneWidget);
  });
}
