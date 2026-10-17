import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/onboarding/presentation/pages/hatching_page.dart';

class MockHapticService extends Mock implements HapticService {}

class MockTtsService extends Mock implements TtsService {}

class MockLocaleService extends Mock implements LocaleService {}

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHapticService mockHaptic;
  late MockTtsService mockTts;
  late MockLocaleService mockLocale;
  late MockAuthBloc mockAuthBloc;

  const testUser = UserEntity(
    id: 'user_aria',
    email: 'aria@vowl.app',
    displayName: 'Aria',
  );

  setUpAll(() {
    registerFallbackValue(const Locale('en'));
  });

  setUp(() {
    mockHaptic = MockHapticService();
    mockTts = MockTtsService();
    mockLocale = MockLocaleService();
    mockAuthBloc = MockAuthBloc();

    // Default mock behaviors
    when(() => mockHaptic.selection()).thenAnswer((_) async {});
    when(() => mockHaptic.success()).thenAnswer((_) async {});
    when(() => mockTts.speak(
      any(),
      rate: any(named: 'rate'),
      locale: any(named: 'locale'),
      pauseMarkers: any(named: 'pauseMarkers'),
      forcedPreset: any(named: 'forcedPreset'),
      isKids: any(named: 'isKids'),
    )).thenAnswer((_) async {});
    when(() => mockTts.stop()).thenAnswer((_) async {});
    when(() => mockLocale.currentLocale).thenReturn(const Locale('en'));
    when(() => mockLocale.tr(
      any(),
      args: any(named: 'args'),
      fallback: any(named: 'fallback'),
    )).thenAnswer((invocation) {
      final fallback = invocation.namedArguments[#fallback] as String?;
      final args = invocation.namedArguments[#args] as List<String>? ?? [];
      var res = fallback ?? invocation.positionalArguments[0] as String;
      for (var i = 0; i < args.length; i++) {
        res = res.replaceAll('{$i}', args[i]);
      }
      return res;
    });

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(testUser),
    );
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

    // Register into di.sl
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    di.sl.registerLazySingleton<HapticService>(() => mockHaptic);

    if (di.sl.isRegistered<TtsService>()) {
      di.sl.unregister<TtsService>();
    }
    di.sl.registerLazySingleton<TtsService>(() => mockTts);

    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
    di.sl.registerLazySingleton<LocaleService>(() => mockLocale);

    initLocaleServiceReference(mockLocale);
  });

  tearDown(() {
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
  });

  Widget buildHatchingHarness({
    String userName = 'Aria',
    ThemeMode themeMode = ThemeMode.light,
    Size viewport = const Size(390, 844),
  }) {
    final router = GoRouter(
      initialLocation: '/hatching',
      routes: [
        GoRoute(
          path: '/hatching',
          builder: (context, state) => HatchingPage(userName: userName),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('HOME_SCREEN_REACHED')),
          ),
        ),
      ],
    );

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
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
  // GROUP 1: Initial Rendering & Stage 0 (Egg Display)
  // =========================================================================
  group('Group 1: Initial Rendering & Stage 0 (Egg Display)', () {
    testWidgets('renders MeshGradientBackground and stylized egg container', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildHatchingHarness());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(MeshGradientBackground), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.text('Tap to begin'), findsOneWidget);

      // Verify Semantics for initial egg state
      final semanticsFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == 'An egg is hatching',
      );
      expect(semanticsFinder, findsOneWidget);

      // Start learning button should NOT be present in stage 0
      expect(find.text('Start Learning!'), findsNothing);
      expect(find.byType(VowlMascot), findsNothing);
    });
  });

  // =========================================================================
  // GROUP 2: Egg Tapping & Cracking State (Stage 0 -> Stage 1)
  // =========================================================================
  group('Group 2: Egg Tapping & Cracking State (Stage 0 -> Stage 1)', () {
    testWidgets('tapping egg triggers selection haptic and transitions to cracking stage', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildHatchingHarness());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap on the egg
      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pump();

      // Selection haptic should fire immediately
      verify(() => mockHaptic.selection()).called(1);

      // Text updates to cracking message
      expect(find.text('Something is happening...'), findsOneWidget);

      // EggCrackPainter is active
      expect(find.byType(CustomPaint), findsWidgets);
      final hasCrackPainter = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is EggCrackPainter,
      );
      expect(hasCrackPainter, findsOneWidget);

      // Tapping again during stage 1 does not re-trigger selection haptics
      await tester.tap(find.byIcon(Icons.auto_awesome), warnIfMissed: false);
      await tester.pump();
      verifyNever(() => mockHaptic.selection());

      // Settle pending timer
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump(const Duration(milliseconds: 200));
    });
  });

  // =========================================================================
  // GROUP 3: Hatching Animation, Mascot Reveal & Audio (Stage 1 -> Stage 2)
  // =========================================================================
  group('Group 3: Hatching Animation, Mascot Reveal & Audio (Stage 1 -> Stage 2)', () {
    testWidgets('advancing timer hatches companion, triggers confetti, TTS and reveals Owly', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildHatchingHarness(userName: 'Aria'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap egg to start cracking
      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pump();

      // Advance through 1500ms hatch timer
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump();

      // Success haptic fires on hatch
      verify(() => mockHaptic.success()).called(1);

      // Mascot is now revealed
      expect(find.byType(VowlMascot), findsOneWidget);

      // Speech synthesis is triggered with userName embedded
      verify(() => mockTts.speak(
        any(that: contains('Aria')),
        locale: 'en-US',
        rate: 0.5,
      )).called(1);

      // Owly dialogue box is shown
      expect(find.text('Owly'), findsOneWidget);
      expect(find.byIcon(Icons.format_quote_rounded), findsOneWidget);

      // Pump typewriter text animation and button animation
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 600));

      // Start Learning button becomes visible
      expect(find.text('Start Learning!'), findsOneWidget);

      // Clean up before test completes
      await tester.pump(const Duration(seconds: 3));
    });
  });

  // =========================================================================
  // GROUP 4: Locale & TTS Language Mapping Matrix
  // =========================================================================
  group('Group 4: Locale & TTS Language Mapping Matrix', () {
    testWidgets('Spanish locale correctly sets es-ES TTS language', (tester) async {
      when(() => mockLocale.currentLocale).thenReturn(const Locale('es'));

      await tester.pumpWidget(buildHatchingHarness());
      await tester.pump();
      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1600));

      verify(() => mockTts.speak(any(), locale: 'es-ES', rate: 0.5)).called(1);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('Hindi locale correctly sets hi-IN TTS language', (tester) async {
      when(() => mockLocale.currentLocale).thenReturn(const Locale('hi'));

      await tester.pumpWidget(buildHatchingHarness());
      await tester.pump();
      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1600));

      verify(() => mockTts.speak(any(), locale: 'hi-IN', rate: 0.5)).called(1);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('Japanese locale correctly sets ja-JP TTS language', (tester) async {
      when(() => mockLocale.currentLocale).thenReturn(const Locale('ja'));

      await tester.pumpWidget(buildHatchingHarness());
      await tester.pump();
      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1600));

      verify(() => mockTts.speak(any(), locale: 'ja-JP', rate: 0.5)).called(1);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('Unsupported locale code falls back to en-US TTS language', (tester) async {
      when(() => mockLocale.currentLocale).thenReturn(const Locale('xx'));

      await tester.pumpWidget(buildHatchingHarness());
      await tester.pump();
      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1600));

      verify(() => mockTts.speak(any(), locale: 'en-US', rate: 0.5)).called(1);
      await tester.pump(const Duration(seconds: 3));
    });
  });

  // =========================================================================
  // GROUP 5: CTA Button Interaction & Navigation Flow
  // =========================================================================
  group('Group 5: CTA Button Interaction & Navigation Flow', () {
    testWidgets('tapping Start Learning stops TTS and navigates to /home', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildHatchingHarness());
      await tester.pump();

      // Tap egg and hatch
      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump(const Duration(milliseconds: 800));

      // Find CTA button
      final ctaFinder = find.widgetWithText(ScaleButton, 'Start Learning!');
      expect(ctaFinder, findsOneWidget);

      await tester.tap(ctaFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // TTS stop should be called
      verify(() => mockTts.stop()).called(1);

      // Home screen reached
      expect(find.text('HOME_SCREEN_REACHED'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
    });
  });

  // =========================================================================
  // GROUP 6: Responsive Viewports, Themes & Safe Disposal
  // =========================================================================
  group('Group 6: Responsive Viewports, Themes & Safe Disposal', () {
    testWidgets('compact mobile layout (320x568) renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(320 * 2, 568 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildHatchingHarness(viewport: const Size(320, 568)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      expect(find.text('Tap to begin'), findsOneWidget);
    });

    testWidgets('tablet viewport (800x1280) renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(800 * 1.5, 1280 * 1.5);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildHatchingHarness(viewport: const Size(800, 1280)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      expect(find.text('Tap to begin'), findsOneWidget);
    });

    testWidgets('dark theme renders with dark background palette', (tester) async {
      await tester.pumpWidget(buildHatchingHarness(themeMode: ThemeMode.dark));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppColors.slate900);
    });

    testWidgets('light theme renders with light background palette', (tester) async {
      await tester.pumpWidget(buildHatchingHarness(themeMode: ThemeMode.light));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppColors.slate50);
    });

    testWidgets('disposing widget stops TTS and clears timer safely', (tester) async {
      await tester.pumpWidget(buildHatchingHarness());
      await tester.pump();

      // Trigger cracking timer
      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pump(const Duration(milliseconds: 200));

      // Unmount page prior to timer expiration
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));

      // Verify TTS stop was called on disposal
      verify(() => mockTts.stop()).called(1);
      expect(tester.takeException(), isNull);
    });
  });
}
