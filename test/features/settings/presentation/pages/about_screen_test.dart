// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/settings/presentation/pages/about_screen.dart';

class MockLocaleService extends Mock implements LocaleService {}

class FakeUrlLauncher extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  String? lastLaunchedUrl;
  LaunchOptions? lastOptions;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastLaunchedUrl = url;
    lastOptions = options;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeUrlLauncher fakeUrlLauncher;
  late MockLocaleService mockLocale;

  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'Vowl',
      packageName: 'com.vowl.app',
      version: '2.4.0',
      buildNumber: '42',
      buildSignature: 'test_sig',
    );
  });

  setUp(() {
    fakeUrlLauncher = FakeUrlLauncher();
    UrlLauncherPlatform.instance = fakeUrlLauncher;

    mockLocale = MockLocaleService();
    when(() => mockLocale.currentLocale).thenReturn(const Locale('en'));
    when(
      () => mockLocale.tr(
        any(),
        args: any(named: 'args'),
        fallback: any(named: 'fallback'),
      ),
    ).thenAnswer((invocation) {
      final fallback = invocation.namedArguments[#fallback] as String?;
      return fallback ?? invocation.positionalArguments[0] as String;
    });

    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
    di.sl.registerLazySingleton<LocaleService>(() => mockLocale);
    initLocaleServiceReference(mockLocale);
  });

  tearDown(() {
    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
  });

  Widget buildAboutHarness({
    ThemeMode themeMode = ThemeMode.light,
    Size viewport = const Size(390, 844),
    double textScaleFactor = 1.0,
  }) {
    final router = GoRouter(
      initialLocation: '/settings/about',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('SETTINGS_SCREEN_REACHED')),
          ),
          routes: [
            GoRoute(
              path: 'about',
              builder: (context, state) => const AboutScreen(),
            ),
          ],
        ),
      ],
    );

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MediaQuery(
        data: MediaQueryData(
          size: viewport,
          textScaler: TextScaler.linear(textScaleFactor),
        ),
        child: MaterialApp.router(
          routerConfig: router,
          themeMode: themeMode,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
        ),
      ),
    );
  }

  // =========================================================================
  // GROUP 1: Initial Rendering & Branding Presentation
  // =========================================================================
  group('Group 1: Initial Rendering & Branding Presentation', () {
    testWidgets(
      'renders background, app bar, app logo, and PackageInfo version',
      (tester) async {
        tester.view.physicalSize = const Size(390 * 3, 844 * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildAboutHarness());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(MeshGradientBackground), findsOneWidget);
        expect(find.text('About'), findsOneWidget);
        expect(find.byIcon(Icons.school_rounded), findsOneWidget);
        expect(find.text('Vowl'), findsOneWidget);
        expect(find.text('English Language Learning App'), findsOneWidget);
        expect(find.text('Version 2.4.0'), findsOneWidget);
      },
    );
  });

  // =========================================================================
  // GROUP 2: Developer & Contact Info Tiles
  // =========================================================================
  group('Group 2: Developer & Contact Info Tiles', () {
    testWidgets(
      'displays developer and contact tiles, tapping contact launches email URL',
      (tester) async {
        tester.view.physicalSize = const Size(390 * 3, 844 * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildAboutHarness());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Developer'), findsOneWidget);
        expect(find.text('Vowl Team'), findsOneWidget);
        expect(find.byIcon(Icons.person_rounded), findsOneWidget);

        expect(find.text('Contact'), findsOneWidget);
        expect(find.text('support.vowl.app@gmail.com'), findsOneWidget);
        expect(find.byIcon(Icons.email_rounded), findsOneWidget);

        // Tap on the contact tile
        await tester.tap(find.text('support.vowl.app@gmail.com'));
        await tester.pump();

        expect(
          fakeUrlLauncher.lastLaunchedUrl,
          'mailto:support.vowl.app@gmail.com',
        );
        expect(
          fakeUrlLauncher.lastOptions?.mode,
          PreferredLaunchMode.externalApplication,
        );
      },
    );
  });

  // =========================================================================
  // GROUP 3: Legal & Open Source Action Buttons
  // =========================================================================
  group('Group 3: Legal & Open Source Action Buttons', () {
    testWidgets('tapping Privacy Policy launches web policy URL', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildAboutHarness());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final privacyFinder = find.text('Privacy Policy');
      expect(privacyFinder, findsOneWidget);

      await tester.tap(privacyFinder);
      await tester.pump();

      expect(
        fakeUrlLauncher.lastLaunchedUrl,
        'https://vowl-official.github.io/vowl-legal/privacy.html',
      );
      expect(
        fakeUrlLauncher.lastOptions?.mode,
        PreferredLaunchMode.externalApplication,
      );
    });

    testWidgets('tapping Terms of Service launches web terms URL', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildAboutHarness());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final termsFinder = find.text('Terms of Service');
      expect(termsFinder, findsOneWidget);

      await tester.tap(termsFinder);
      await tester.pump();

      expect(
        fakeUrlLauncher.lastLaunchedUrl,
        'https://vowl-official.github.io/vowl-legal/terms.html',
      );
      expect(
        fakeUrlLauncher.lastOptions?.mode,
        PreferredLaunchMode.externalApplication,
      );
    });

    testWidgets('tapping View Open Source Licenses opens LicensePage', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildAboutHarness());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final licensesFinder = find.text('View Open Source Licenses');
      expect(licensesFinder, findsOneWidget);

      await tester.tap(licensesFinder);
      await tester.pumpAndSettle();

      expect(find.byType(LicensePage), findsOneWidget);
    });
  });

  // =========================================================================
  // GROUP 4: App Bar & Navigation
  // =========================================================================
  group('Group 4: App Bar & Navigation', () {
    testWidgets('tapping back button pops route and returns to settings', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildAboutHarness());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.text('SETTINGS_SCREEN_REACHED'), findsOneWidget);
    });
  });

  // =========================================================================
  // GROUP 5: Responsive Viewports, Themes & Accessibility
  // =========================================================================
  group('Group 5: Responsive Viewports, Themes & Accessibility', () {
    testWidgets('compact mobile layout (320x568) renders without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320 * 2, 568 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildAboutHarness(viewport: const Size(320, 568)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      expect(find.text('Vowl'), findsOneWidget);
      expect(find.text('Version 2.4.0'), findsOneWidget);
    });

    testWidgets('tablet viewport (800x1280) renders without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800 * 1.5, 1280 * 1.5);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildAboutHarness(viewport: const Size(800, 1280)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      expect(find.text('Vowl'), findsOneWidget);
    });

    testWidgets('accessibility text scaling (1.3x) renders without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildAboutHarness(textScaleFactor: 1.3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      expect(find.text('English Language Learning App'), findsOneWidget);
    });

    testWidgets('dark theme adapts background and text contrast', (
      tester,
    ) async {
      await tester.pumpWidget(buildAboutHarness(themeMode: ThemeMode.dark));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppColors.slate900);
    });

    testWidgets('light theme adapts background and text contrast', (
      tester,
    ) async {
      await tester.pumpWidget(buildAboutHarness(themeMode: ThemeMode.light));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppColors.slate50);
    });
  });
}
