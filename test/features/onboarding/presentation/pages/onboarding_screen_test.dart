import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/onboarding/onboarding_illustrations.dart';
import 'package:vowl/features/onboarding/onboarding_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildScreenHarness({
    required Size physicalSize,
    double textScale = 1.0,
    bool disableAnimations = false,
    VoidCallback? onSkip,
    VoidCallback? onGetStarted,
    VoidCallback? onLogin,
  }) {
    return MediaQuery(
      data: MediaQueryData(
        size: physicalSize,
        textScaler: TextScaler.linear(textScale),
        disableAnimations: disableAnimations,
      ),
      child: MaterialApp(
        home: OnboardingScreen(
          onSkip: onSkip ?? () {},
          onGetStarted: onGetStarted ?? () {},
          onLogin: onLogin ?? () {},
        ),
      ),
    );
  }

  group('OnboardingScreen Visual, Responsive & Accessibility Verification', () {
    setUp(() {
      VowlMotion.lowAnimationModeOverride.value = true;
    });

    tearDown(() {
      VowlMotion.lowAnimationModeOverride.value = false;
    });

    testWidgets(
      'small phone (360x640) text scale 1.0 renders all 4 slides with no overflow',
      (tester) async {
        tester.view.physicalSize = const Size(360 * 2, 640 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          buildScreenHarness(
            physicalSize: const Size(360, 640),
            textScale: 1.0,
            disableAnimations: true,
          ),
        );
        await tester.pump();

        // Slide 1
        expect(find.text('Learn English Through Games'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Advance to Slide 2
        await tester.tap(find.text('Continue'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Learn From What You See'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Advance to Slide 3
        await tester.tap(find.text('Continue'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Stay Motivated Every Day'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Advance to Slide 4
        await tester.tap(find.text('Continue'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Track Progress & Accents'), findsOneWidget);
        expect(find.text('Get Started'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'compact phone (320x568) text scale 1.0 (iPhone SE) renders all 4 slides with no overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320 * 2, 568 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          buildScreenHarness(
            physicalSize: const Size(320, 568),
            textScale: 1.0,
            disableAnimations: true,
          ),
        );
        await tester.pump();

        // Slide 1
        expect(find.text('Learn English Through Games'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Advance to Slide 2
        await tester.tap(find.text('Continue'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Learn From What You See'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Advance to Slide 3
        await tester.tap(find.text('Continue'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Stay Motivated Every Day'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Advance to Slide 4
        await tester.tap(find.text('Continue'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Track Progress & Accents'), findsOneWidget);
        expect(find.text('Get Started'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'standard iPhone (390x844) renders all 4 slides with no overflow',
      (tester) async {
        tester.view.physicalSize = const Size(390 * 3, 844 * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          buildScreenHarness(
            physicalSize: const Size(390, 844),
            textScale: 1.0,
            disableAnimations: true,
          ),
        );
        await tester.pump();

        expect(find.text('Learn English Through Games'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Continue'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Learn From What You See'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Continue'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Stay Motivated Every Day'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Continue'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Track Progress & Accents'), findsOneWidget);
        expect(find.text('Get Started'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'large phone (412x915) text scale 1.5 renders all 4 slides with no overflow',
      (tester) async {
        tester.view.physicalSize = const Size(412 * 3, 915 * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          buildScreenHarness(
            physicalSize: const Size(412, 915),
            textScale: 1.5,
            disableAnimations: true,
          ),
        );
        await tester.pump();

        expect(find.text('Learn English Through Games'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Continue'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Learn From What You See'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Continue'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Stay Motivated Every Day'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Continue'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Track Progress & Accents'), findsOneWidget);
        expect(find.text('Get Started'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'tall flagship (430x932) text scale 1.25 renders all 4 slides with no overflow',
      (tester) async {
        tester.view.physicalSize = const Size(430 * 3, 932 * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          buildScreenHarness(
            physicalSize: const Size(430, 932),
            textScale: 1.25,
            disableAnimations: true,
          ),
        );
        await tester.pump();

        expect(find.text('Learn English Through Games'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Continue'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Learn From What You See'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Continue'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Stay Motivated Every Day'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Continue'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Track Progress & Accents'), findsOneWidget);
        expect(find.text('Get Started'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'tablet / foldable (600x960) text scale 1.0 renders all 4 slides with no overflow',
      (tester) async {
        tester.view.physicalSize = const Size(600 * 2, 960 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          buildScreenHarness(
            physicalSize: const Size(600, 960),
            textScale: 1.0,
            disableAnimations: true,
          ),
        );
        await tester.pump();

        expect(find.text('Learn English Through Games'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Continue'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Learn From What You See'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Continue'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Stay Motivated Every Day'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Continue'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Track Progress & Accents'), findsOneWidget);
        expect(find.text('Get Started'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('illustrations expose correct accessibility semantic labels', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildScreenHarness(
          physicalSize: const Size(390, 844),
          disableAnimations: true,
        ),
      );
      await tester.pump();

      expect(
        find.bySemanticsLabel(OnboardingIllustration.labels[0]),
        findsOneWidget,
      );
    });

    testWidgets(
      'interactive controls meet minimum 48dp touch target requirements',
      (tester) async {
        await tester.pumpWidget(
          buildScreenHarness(
            physicalSize: const Size(390, 844),
            disableAnimations: true,
          ),
        );
        await tester.pump();

        // Skip button
        final skipButtonFinder = find.widgetWithText(ScaleButton, 'Skip');
        final skipSize = tester.getSize(skipButtonFinder);
        expect(skipSize.height, greaterThanOrEqualTo(48.0));
        expect(skipSize.width, greaterThanOrEqualTo(48.0));

        // Primary Continue button (height: 52dp)
        final primaryButtonFinder = find.widgetWithText(
          ScaleButton,
          'Continue',
        );
        final continueSize = tester.getSize(primaryButtonFinder);
        expect(continueSize.height, greaterThanOrEqualTo(48.0));
      },
    );

    testWidgets('callbacks fire on user interaction', (tester) async {
      bool skipFired = false;
      bool getStartedFired = false;

      await tester.pumpWidget(
        buildScreenHarness(
          physicalSize: const Size(390, 844),
          disableAnimations: true,
          onSkip: () => skipFired = true,
          onGetStarted: () => getStartedFired = true,
        ),
      );
      await tester.pump();

      // Tap skip
      await tester.tap(find.text('Skip'));
      await tester.pump(const Duration(milliseconds: 750));
      expect(skipFired, isTrue);

      // Navigate to slide 4 and tap Get Started
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Get Started'), findsOneWidget);
      await tester.tap(find.text('Get Started'));
      await tester.pump(const Duration(milliseconds: 750));
      expect(getStartedFired, isTrue);
    });
  });
}
