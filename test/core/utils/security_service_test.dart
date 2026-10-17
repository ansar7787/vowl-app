import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_device/safe_device.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/production_guard.dart';
import 'package:vowl/core/utils/security_service.dart';

class MockAppLogger extends Mock implements AppLogger {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAppLogger mockLogger;
  const channel = MethodChannel('safe_device');

  var mockIsJailBroken = false;
  var mockIsRealDevice = true;
  var mockIsDevMode = false;
  var shouldThrowPlatformError = false;

  setUp(() {
    mockLogger = MockAppLogger();
    mockIsJailBroken = false;
    mockIsRealDevice = true;
    mockIsDevMode = false;
    shouldThrowPlatformError = false;
    SafeDevice.isInitiated = false;

    when(() => mockLogger.debug(any(), tag: any(named: 'tag'))).thenReturn(null);
    when(() => mockLogger.warning(any(), tag: any(named: 'tag'))).thenReturn(null);
    when(() => mockLogger.error(
      any(),
      error: any(named: 'error'),
      stackTrace: any(named: 'stackTrace'),
      tag: any(named: 'tag'),
    )).thenReturn(null);

    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
    di.sl.registerLazySingleton<AppLogger>(() => mockLogger);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'init') {
        return null;
      }
      if (shouldThrowPlatformError) {
        throw PlatformException(
          code: 'UNAVAILABLE',
          message: 'SafeDevice channel failed',
        );
      }
      switch (call.method) {
        case 'isJailBroken':
          return mockIsJailBroken;
        case 'isRealDevice':
          return mockIsRealDevice;
        case 'isDevelopmentModeEnable':
          return mockIsDevMode;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
    dotenv.clean();
  });

  // =========================================================================
  // GROUP 1: Contract & Factory Instantiation
  // =========================================================================
  group('Group 1: Contract & Factory Instantiation', () {
    test('factory constructor returns concrete SecurityServiceImpl instance', () {
      final service = SecurityService();
      expect(service, isA<SecurityServiceImpl>());
    });

    test('static convenience methods delegate correctly to implementation', () async {
      mockIsJailBroken = false;
      mockIsRealDevice = true;
      mockIsDevMode = false;

      final isSecure = await SecurityService.isDeviceSecure();
      expect(isSecure, isTrue);

      final isDev = await SecurityService.isDeveloperModeEnabled();
      expect(isDev, isFalse);
    });
  });

  // =========================================================================
  // GROUP 2: Device Security Verification Flow
  // =========================================================================
  group('Group 2: Device Security Verification Flow', () {
    test('returns true when device is genuine, not rooted and not jailbroken', () async {
      mockIsJailBroken = false;
      mockIsRealDevice = true;

      final service = SecurityService();
      final result = await service.checkDeviceSecurity();

      expect(result, isTrue);
    });

    test('returns false when device is rooted or jailbroken', () async {
      mockIsJailBroken = true;
      mockIsRealDevice = true;

      final service = SecurityService();
      final result = await service.checkDeviceSecurity();

      expect(result, isFalse);
    });

    test('fails open when safe_device plugin platform channel throws an exception', () async {
      shouldThrowPlatformError = true;

      final service = SecurityService();
      final result = await service.checkDeviceSecurity();

      // Fails open (returns true) to prevent false-positive lockouts
      expect(result, isTrue);
    });
  });

  // =========================================================================
  // GROUP 3: Developer Mode Verification Flow
  // =========================================================================
  group('Group 3: Developer Mode Verification Flow', () {
    test('returns true when developer mode options are enabled', () async {
      mockIsDevMode = true;

      final service = SecurityService();
      final result = await service.checkDeveloperMode();

      expect(result, isTrue);
    });

    test('returns false when developer mode options are disabled', () async {
      mockIsDevMode = false;

      final service = SecurityService();
      final result = await service.checkDeveloperMode();

      expect(result, isFalse);
    });

    test('returns false when developer mode check throws platform exception', () async {
      shouldThrowPlatformError = true;

      final service = SecurityService();
      final result = await service.checkDeveloperMode();

      expect(result, isFalse);
    });
  });

  // =========================================================================
  // GROUP 4: ProductionGuard Configuration Integrity
  // =========================================================================
  group('Group 4: ProductionGuard Configuration Integrity', () {
    test('checkConfiguration in debug mode logs debug info when test key present', () {
      dotenv.loadFromString(envString: 'RAZORPAY_KEY_ID=rzp_test_12345678');

      ProductionGuard.checkConfiguration();

      verify(() => mockLogger.debug(
        'Using test keys (expected in debug mode).',
        tag: 'ProductionGuard',
      )).called(1);
    });

    test('checkConfiguration completes without error when key is null in test/debug', () {
      dotenv.loadFromString(envString: '', isOptional: true);

      expect(ProductionGuard.checkConfiguration, returnsNormally);
    });

    test('checkConfiguration completes without error with live key in test/debug', () {
      dotenv.loadFromString(envString: 'RAZORPAY_KEY_ID=rzp_live_production123');

      expect(ProductionGuard.checkConfiguration, returnsNormally);
    });
  });
}
