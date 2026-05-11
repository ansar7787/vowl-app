import 'package:haptic_feedback/haptic_feedback.dart';

class HapticService {
  bool? _canVibrate;

  Future<bool> _checkVibrate() async {
    _canVibrate ??= await Haptics.canVibrate();
    return _canVibrate!;
  }

  Future<void> success() async {
    if (await _checkVibrate()) {
      await Haptics.vibrate(HapticsType.success);
    }
  }

  Future<void> error() async {
    if (await _checkVibrate()) {
      await Haptics.vibrate(HapticsType.error);
    }
  }

  Future<void> selection() async {
    if (await _checkVibrate()) {
      await Haptics.vibrate(HapticsType.selection);
    }
  }

  Future<void> light() async {
    if (await _checkVibrate()) {
      await Haptics.vibrate(HapticsType.light);
    }
  }

  Future<void> warning() async {
    if (await _checkVibrate()) {
      await Haptics.vibrate(HapticsType.warning);
    }
  }

  Future<void> heavy() async {
    if (await _checkVibrate()) {
      await Haptics.vibrate(HapticsType.heavy);
    }
  }

  Future<void> rhythmicTick() async {
    if (await _checkVibrate()) {
      await Haptics.vibrate(HapticsType.light);
      await Future.delayed(const Duration(milliseconds: 100));
      await Haptics.vibrate(HapticsType.selection);
    }
  }
}
