import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:vowl/features/auth/data/models/user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthLocalDataSourceImpl dataSource;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dataSource = AuthLocalDataSourceImpl();
  });

  group('AuthLocalDataSourceImpl', () {
    final testUser = UserModel(
      id: 'test_uid_123',
      email: 'test@example.com',
      displayName: 'Test User',
      photoUrl: 'https://example.com/photo.png',
      isEmailVerified: true,
      isPremium: true,
      lastLoginDate: DateTime(2026, 10, 24, 12, 0),
      currentStreak: 5,
      coins: 250,
      totalExp: 1500,
      unlockedLevels: const {'grammar': 14},
      completedLevels: const {
        'grammar': [1, 2],
      },
      dailyXpHistory: const {'2026-10-24': 100},
      recentActivities: const [],
    );

    test('getCachedUser returns null when no user is cached', () async {
      final user = await dataSource.getCachedUser();
      expect(user, isNull);
    });

    test(
      'cacheUser serializes and getCachedUser restores the full UserModel with premium & streak',
      () async {
        await dataSource.cacheUser(testUser);

        final restored = await dataSource.getCachedUser();
        expect(restored, isNotNull);
        expect(restored!.id, equals('test_uid_123'));
        expect(restored.email, equals('test@example.com'));
        expect(restored.displayName, equals('Test User'));
        expect(restored.isEmailVerified, isTrue);
        expect(restored.isPremium, isTrue);
        expect(restored.currentStreak, equals(5));
        expect(restored.coins, equals(250));
        expect(restored.unlockedLevels['grammar'], equals(14));
        expect(restored.completedLevels['grammar'], contains(1));
        expect(restored.lastLoginDate?.year, equals(2026));
      },
    );

    test(
      'clearCachedUser removes the stored user from SharedPreferences',
      () async {
        await dataSource.cacheUser(testUser);
        var cached = await dataSource.getCachedUser();
        expect(cached, isNotNull);

        await dataSource.clearCachedUser();
        cached = await dataSource.getCachedUser();
        expect(cached, isNull);
      },
    );

    test(
      'getCachedUser returns null gracefully when storage has corrupted string',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'cached_user_profile_json',
          'not_valid_json_string{',
        );

        final result = await dataSource.getCachedUser();
        expect(result, isNull);
      },
    );
  });
}
