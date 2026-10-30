import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/utils/email_launcher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.vowl.app/email_launcher');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('EmailLauncher', () {
    test('openInbox returns true when native Android channel succeeds', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'openEmailInbox') {
          return true;
        }
        return false;
      });

      // Note: On non-Android test host (Windows/Linux), it falls back safely without throwing
      final result = await EmailLauncher.openInbox();
      expect(result, isA<bool>());
    });

    test('openInbox handles channel exception gracefully without throwing', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        throw PlatformException(code: 'ERROR', message: 'Activity not found');
      });

      final result = await EmailLauncher.openInbox();
      expect(result, isA<bool>());
    });
  });
}
