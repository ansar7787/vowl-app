import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/auth/data/models/user_model.dart';

void main() {
  group('UserModel displayName sanitization', () {
    test('preserves valid displayName', () {
      final model = UserModel.fromMap({
        'id': 'u1',
        'email': 'user@vowl.app',
        'displayName': 'John Doe',
      });
      expect(model.displayName, 'John Doe');
      expect(model.safeDisplayName, 'John Doe');
    });

    test('replaces "Unknown User" with clean name derived from email', () {
      final model = UserModel.fromMap({
        'id': 'u2',
        'email': 'susan.clark@vowl.app',
        'displayName': 'Unknown User',
      });
      expect(model.displayName, 'Susan Clark');
      expect(model.safeDisplayName, 'Susan Clark');
    });

    test('replaces "unknown" case-insensitively with clean email derivation', () {
      final model = UserModel.fromMap({
        'id': 'u3',
        'email': 'peter_parker@marvel.com',
        'displayName': 'UNKNOWN',
      });
      expect(model.displayName, 'Peter Parker');
      expect(model.safeDisplayName, 'Peter Parker');
    });

    test('replaces empty displayName with email derivation', () {
      final model = UserModel.fromMap({
        'id': 'u4',
        'email': 'tony.stark@avengers.com',
        'displayName': '   ',
      });
      expect(model.displayName, 'Tony Stark');
      expect(model.safeDisplayName, 'Tony Stark');
    });

    test('falls back gracefully when neither displayName nor email are valid', () {
      final model = UserModel.fromMap({
        'id': 'u5',
        'email': '',
        'displayName': 'Unknown User',
      });
      expect(model.displayName, isNull);
      expect(model.getSafeDisplayName(fallback: 'Anonymous Player'), 'Anonymous Player');
      expect(model.safeDisplayName, 'Vowl Learner');
    });
  });
}

