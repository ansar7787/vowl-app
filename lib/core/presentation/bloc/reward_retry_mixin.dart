import 'package:flutter/foundation.dart';

/// Mixin providing exponential-backoff retry logic for saving game rewards.
///
/// Used by game BLoCs to ensure reward persistence survives transient
/// network failures. Without this, a brief network drop during reward
/// save causes permanent reward loss for the user.
///
/// ### Usage
/// ```dart
/// class MyGameBloc extends Bloc<MyEvent, MyState> with RewardRetryMixin {
///   Future<void> _saveRewards() async {
///     await saveWithRetry(
///       action: () => updateUserRewards(...),
///       onFinalFailure: () => add(const RewardSaveFailedEvent()),
///       tag: 'MyGameBloc',
///     );
///   }
/// }
/// ```
mixin RewardRetryMixin {
  static const _kMaxRetries = 3;

  /// Executes [action] with up to [_kMaxRetries] attempts using exponential
  /// backoff (1s, 2s, 4s). Calls [onFinalFailure] if all attempts fail.
  Future<void> saveWithRetry({
    required Future<void> Function() action,
    required VoidCallback onFinalFailure,
    String tag = 'RewardRetry',
  }) async {
    for (int attempt = 1; attempt <= _kMaxRetries; attempt++) {
      try {
        await action();
        return;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[$tag] Save attempt $attempt/$_kMaxRetries failed: $e');
        }
        if (attempt < _kMaxRetries) {
          await Future.delayed(Duration(seconds: 1 << (attempt - 1)));
        }
      }
    }
    onFinalFailure();
  }
}
