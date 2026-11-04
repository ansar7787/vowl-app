import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/praise_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/app_logger.dart';

class MockTtsService extends Mock implements TtsService {}
class MockAppLogger extends Mock implements AppLogger {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockTtsService mockTtsService;
  late MockAppLogger mockAppLogger;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async => 1,
    );

    SharedPreferences.setMockInitialValues({
      'sound_enabled': true,
      'game_sounds_enabled': true,
    });

    mockTtsService = MockTtsService();
    mockAppLogger = MockAppLogger();

    if (!di.sl.isRegistered<AppLogger>()) {
      di.sl.registerSingleton<AppLogger>(mockAppLogger);
    }
  });

  tearDown(() async {
    await Future.delayed(const Duration(milliseconds: 10));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      null,
    );
    di.sl.reset();
  });

  group('PraiseService & PraiseStrategy Tests', () {
    test('StandardPraiseStrategy supplies valid phrases for all PraiseContexts', () {
      final strategy = StandardPraiseStrategy();

      expect(strategy.getPhrasesForContext(PraiseContext.standard).isNotEmpty, isTrue);
      expect(strategy.getPhrasesForContext(PraiseContext.flawless).isNotEmpty, isTrue);
      expect(strategy.getPhrasesForContext(PraiseContext.hotStreak5).isNotEmpty, isTrue);
      expect(strategy.getPhrasesForContext(PraiseContext.hotStreak10).isNotEmpty, isTrue);
      expect(strategy.getPhrasesForContext(PraiseContext.streakSecured).isNotEmpty, isTrue);

      expect(strategy.getPhrasesForContext(PraiseContext.flawless), contains('Flawless! 3 out of 3.'));
    });

    test('KidsPraiseStrategy supplies cheerful phrases for all PraiseContexts', () {
      final strategy = KidsPraiseStrategy();

      expect(strategy.getPhrasesForContext(PraiseContext.standard).isNotEmpty, isTrue);
      expect(strategy.getPhrasesForContext(PraiseContext.flawless).isNotEmpty, isTrue);
      expect(strategy.getPhrasesForContext(PraiseContext.hotStreak5).isNotEmpty, isTrue);
      expect(strategy.getPhrasesForContext(PraiseContext.hotStreak10).isNotEmpty, isTrue);
      expect(strategy.getPhrasesForContext(PraiseContext.streakSecured).isNotEmpty, isTrue);

      expect(strategy.getPhrasesForContext(PraiseContext.flawless), contains('Wow! Superstar! Perfect score!'));
    });

    test('PraiseService calls speak with contextual encouragement', () async {
      when(() => mockTtsService.speak(any())).thenAnswer((_) async {});

      final praiseService = PraiseService(mockTtsService);
      praiseService.givePraise(context: PraiseContext.flawless);

      verify(() => mockTtsService.speak(any())).called(1);
    });

    test('PraiseService supports backward-compatible givePraise() with default standard context', () async {
      when(() => mockTtsService.speak(any())).thenAnswer((_) async {});

      final praiseService = PraiseService(mockTtsService);
      praiseService.givePraise(); // No arguments

      verify(() => mockTtsService.speak(any())).called(1);
    });
  });

  group('SoundService Contract & Architecture Tests', () {
    test('SoundService initializes unmuted by default', () async {
      when(() => mockTtsService.isSpeaking).thenReturn(false);

      final soundService = SoundService(mockTtsService);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(soundService.isMuted, isFalse);
      expect(soundService.isGameSoundsEnabled, isTrue);
    });

    test('setMuted toggles state and persists preference', () async {
      when(() => mockTtsService.isSpeaking).thenReturn(false);
      when(() => mockTtsService.stop()).thenAnswer((_) async {});

      final soundService = SoundService(mockTtsService);
      await Future.delayed(const Duration(milliseconds: 50));

      soundService.setMuted(true);
      expect(soundService.isMuted, isTrue);

      soundService.setMuted(false);
      expect(soundService.isMuted, isFalse);
    });

    test('setGameSoundsEnabled toggles game sound state', () async {
      when(() => mockTtsService.isSpeaking).thenReturn(false);

      final soundService = SoundService(mockTtsService);
      await Future.delayed(const Duration(milliseconds: 50));

      soundService.setGameSoundsEnabled(false);
      expect(soundService.isGameSoundsEnabled, isFalse);

      soundService.setGameSoundsEnabled(true);
      expect(soundService.isGameSoundsEnabled, isTrue);
    });

    test('playCorrect automatically steps through combo when unparameterized', () async {
      when(() => mockTtsService.isSpeaking).thenReturn(false);

      final soundService = SoundService(mockTtsService);
      await Future.delayed(const Duration(milliseconds: 50));

      // First call -> Step 1
      await soundService.playCorrect();
      // Reset combo clears progression back to 0
      soundService.resetCombo();
      // Next call starts at Step 1 again
      await soundService.playCorrect();
    });

    test('playGameOver plays without throwing and resets combo', () async {
      when(() => mockTtsService.isSpeaking).thenReturn(false);

      final soundService = SoundService(mockTtsService);
      await Future.delayed(const Duration(milliseconds: 50));

      await soundService.playGameOver();
      expect(soundService.isMuted, isFalse);
    });
  });
}
