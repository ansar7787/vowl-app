import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/onboarding_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OnboardingService', () {
    test('initial state before loadCached is false', () async {
      await OnboardingService.resetOnboarding();
      expect(OnboardingService.isCompletedCached, isFalse);
    });

    test('loadCached correctly reads existing SharedPreferences true value', () async {
      SharedPreferences.setMockInitialValues({
        OnboardingService.prefsKeyHasSeenOnboarding: true,
      });

      await OnboardingService.loadCached();
      expect(OnboardingService.isCompletedCached, isTrue);
    });

    test('completeOnboarding updates cache and persists true', () async {
      SharedPreferences.setMockInitialValues({});
      await OnboardingService.loadCached();
      expect(OnboardingService.isCompletedCached, isFalse);

      await OnboardingService.completeOnboarding();
      expect(OnboardingService.isCompletedCached, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(OnboardingService.prefsKeyHasSeenOnboarding), isTrue);
    });

    test('evaluateUserProgress completes onboarding if levels > 0', () async {
      SharedPreferences.setMockInitialValues({});
      await OnboardingService.resetOnboarding();
      expect(OnboardingService.isCompletedCached, isFalse);

      await OnboardingService.evaluateUserProgress(5);
      expect(OnboardingService.isCompletedCached, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(OnboardingService.prefsKeyHasSeenOnboarding), isTrue);
    });

    test('evaluateUserProgress does not complete onboarding if levels == 0', () async {
      SharedPreferences.setMockInitialValues({});
      await OnboardingService.resetOnboarding();
      expect(OnboardingService.isCompletedCached, isFalse);

      await OnboardingService.evaluateUserProgress(0);
      expect(OnboardingService.isCompletedCached, isFalse);
    });

    test('resetOnboarding clears cache and removes preference', () async {
      SharedPreferences.setMockInitialValues({
        OnboardingService.prefsKeyHasSeenOnboarding: true,
      });
      await OnboardingService.loadCached();
      expect(OnboardingService.isCompletedCached, isTrue);

      await OnboardingService.resetOnboarding();
      expect(OnboardingService.isCompletedCached, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(OnboardingService.prefsKeyHasSeenOnboarding), isFalse);
    });
  });
}

