import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/onboarding_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/onboarding/presentation/pages/onboarding_page.dart';

class MockHapticService extends Mock implements HapticService {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHapticService mockHaptic;
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    VowlMotion.lowAnimationModeOverride.value = true;
    SharedPreferences.setMockInitialValues({});
    mockHaptic = MockHapticService();
    mockAuthBloc = MockAuthBloc();

    when(() => mockHaptic.selection()).thenAnswer((_) async {});
    when(() => mockHaptic.light()).thenAnswer((_) async {});
    when(() => mockHaptic.success()).thenAnswer((_) async {});
    when(() => mockAuthBloc.state).thenReturn(const AuthState.unknown());

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    di.sl.registerSingleton<HapticService>(mockHaptic);

    if (di.sl.isRegistered<AuthBloc>()) {
      di.sl.unregister<AuthBloc>();
    }
    di.sl.registerSingleton<AuthBloc>(mockAuthBloc);
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<AuthBloc>()) {
      di.sl.unregister<AuthBloc>();
    }
  });

  Widget buildTestableWidget() {
    return BlocProvider<AuthBloc>.value(
      value: mockAuthBloc,
      child: const MaterialApp(home: OnboardingPage()),
    );
  }

  group('OnboardingPage Widget Tests', () {
    testWidgets('renders first slide headline, step count, Skip and Continue', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('Learn English Through Games'), findsOneWidget);
      expect(find.text('1 of 4'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('skip button completes onboarding', (tester) async {
      await OnboardingService.resetOnboarding();
      expect(OnboardingService.isCompletedCached, isFalse);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      final skipFinder = find.text('Skip');
      expect(skipFinder, findsOneWidget);

      await tester.tap(skipFinder);
      await tester.pump(const Duration(milliseconds: 750));

      expect(OnboardingService.isCompletedCached, isTrue);
    });

    testWidgets(
      'tapping Continue steps through all 4 slides and completes on Get Started',
      (tester) async {
        await OnboardingService.resetOnboarding();
        expect(OnboardingService.isCompletedCached, isFalse);

        await tester.pumpWidget(buildTestableWidget());
        await tester.pump();

        // Slide 1
        expect(find.text('1 of 4'), findsOneWidget);
        await tester.tap(find.text('Continue'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Slide 2
        expect(find.text('2 of 4'), findsOneWidget);
        expect(find.text('Learn From What You See'), findsOneWidget);
        await tester.tap(find.text('Continue'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Slide 3
        expect(find.text('3 of 4'), findsOneWidget);
        expect(find.text('Stay Motivated Every Day'), findsOneWidget);
        await tester.tap(find.text('Continue'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Slide 4
        expect(find.text('4 of 4'), findsOneWidget);
        expect(find.text('Track Progress & Accents'), findsOneWidget);
        expect(find.text('Get Started'), findsOneWidget);

        // Tap Get Started
        await tester.tap(find.text('Get Started'));
        await tester.pump(const Duration(milliseconds: 750));

        expect(OnboardingService.isCompletedCached, isTrue);
      },
    );
  });
}
