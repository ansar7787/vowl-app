import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/utils/app_version_helper.dart';

void main() {
  group('AppVersionHelper', () {
    test('compare returns 0 for equal versions', () {
      expect(AppVersionHelper.compare('1.0.0', '1.0.0'), 0);
      expect(AppVersionHelper.compare('v1.0.0', '1.0.0'), 0);
      expect(AppVersionHelper.compare('1.0.0+3', '1.0.0+5'), 0);
      expect(AppVersionHelper.compare('v2.1.4+10', '2.1.4'), 0);
    });

    test('compare correctly identifies newer version', () {
      expect(AppVersionHelper.compare('1.0.1', '1.0.0'), greaterThan(0));
      expect(AppVersionHelper.compare('1.1.0', '1.0.9'), greaterThan(0));
      expect(AppVersionHelper.compare('2.0.0', '1.9.9'), greaterThan(0));
      expect(AppVersionHelper.compare('1.0.0.1', '1.0.0'), greaterThan(0));
    });

    test('compare correctly identifies older version', () {
      expect(AppVersionHelper.compare('1.0.0', '1.0.1'), lessThan(0));
      expect(AppVersionHelper.compare('1.0.9', '1.1.0'), lessThan(0));
      expect(AppVersionHelper.compare('1.9.9', '2.0.0'), lessThan(0));
    });

    test('isUpdateAvailable returns true only when remote is strictly newer', () {
      expect(AppVersionHelper.isUpdateAvailable('1.0.0', '1.0.1'), isTrue);
      expect(AppVersionHelper.isUpdateAvailable('1.0.0+3', '1.0.1+1'), isTrue);
      expect(AppVersionHelper.isUpdateAvailable('1.0.0', '1.0.0'), isFalse);
      expect(AppVersionHelper.isUpdateAvailable('1.1.0', '1.0.5'), isFalse);
      expect(AppVersionHelper.isUpdateAvailable('1.0.0', ''), isFalse);
    });

    test('isBelowMinVersion returns true only when current is strictly lower than min', () {
      expect(AppVersionHelper.isBelowMinVersion('1.0.0', '1.1.0'), isTrue);
      expect(AppVersionHelper.isBelowMinVersion('1.0.0', '1.0.1'), isTrue);
      expect(AppVersionHelper.isBelowMinVersion('1.0.1', '1.0.0'), isFalse);
      expect(AppVersionHelper.isBelowMinVersion('1.0.0', '1.0.0'), isFalse);
      expect(AppVersionHelper.isBelowMinVersion('1.0.0', ''), isFalse);
    });

    test('cleanDisplayVersion strips metadata and leading v', () {
      expect(AppVersionHelper.cleanDisplayVersion('v1.2.3'), '1.2.3');
      expect(AppVersionHelper.cleanDisplayVersion('V2.0.0+4'), '2.0.0');
      expect(AppVersionHelper.cleanDisplayVersion('1.0.0'), '1.0.0');
      expect(AppVersionHelper.cleanDisplayVersion(''), '0.0.0');
    });
  });
}

