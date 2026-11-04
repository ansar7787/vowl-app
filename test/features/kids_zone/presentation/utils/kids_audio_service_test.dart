import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_audio_service.dart';

class MockAppLogger extends Mock implements AppLogger {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
      'is_kids_sfx_enabled': true,
    });

    mockAppLogger = MockAppLogger();
    if (!di.sl.isRegistered<AppLogger>()) {
      di.sl.registerSingleton<AppLogger>(mockAppLogger);
    }
  });

  tearDown(() async {
    await Future.delayed(const Duration(milliseconds: 50));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      null,
    );
    if (di.sl.isRegistered<AppLogger>()) {
      di.sl.unregister<AppLogger>();
    }
  });

  group('KidsAudioService Tests', () {
    test('initializes with sfx enabled', () async {
      final service = KidsAudioService();
      expect(await service.isSfxEnabled(), isTrue);
    });

    test('setSfxEnabled toggles preference', () async {
      final service = KidsAudioService();
      await service.setSfxEnabled(false);
      expect(await service.isSfxEnabled(), isFalse);
    });

    test('plays all sfx triggers including playGameOverSFX without throwing', () async {
      final service = KidsAudioService();
      await expectLater(service.playSuccessSFX(comboStep: 1), completes);
      await expectLater(service.playSuccessSFX(comboStep: 2), completes);
      await expectLater(service.playSuccessSFX(comboStep: 3), completes);
      await expectLater(service.playSuccessSFX(comboStep: 4), completes);
      await expectLater(service.playFailureSFX(), completes);
      await expectLater(service.playLevelCompleteSFX(), completes);
      await expectLater(service.playGameOverSFX(), completes);
    });
  });
}
