import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/features/auth/data/models/user_model.dart';

/// Contract for persisting and restoring the authenticated user's profile
/// locally on the device for 100% offline-first boot capability.
abstract class AuthLocalDataSource {
  /// Persists the user model to local disk storage.
  Future<void> cacheUser(UserModel user);

  /// Retrieves the cached user model from local storage if available.
  Future<UserModel?> getCachedUser();

  /// Clears the cached user profile upon sign-out or account deletion.
  Future<void> clearCachedUser();
}

/// Production implementation of [AuthLocalDataSource] backed by [SharedPreferences].
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const String _kCachedUserKey = 'cached_user_profile_json';

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(user.toJsonMap());
      await prefs.setString(_kCachedUserKey, jsonString);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthLocalDataSource: Failed to cache user: $e');
      }
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_kCachedUserKey);
      if (jsonString == null || jsonString.isEmpty) return null;
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return UserModel.fromMap(decoded);
      } else if (decoded is Map) {
        return UserModel.fromMap(Map<String, dynamic>.from(decoded));
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthLocalDataSource: Failed to load cached user: $e');
      }
      return null;
    }
  }

  @override
  Future<void> clearCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kCachedUserKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthLocalDataSource: Failed to clear cached user: $e');
      }
    }
  }
}
