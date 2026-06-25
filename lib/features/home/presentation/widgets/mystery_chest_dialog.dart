import 'dart:async';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/home/presentation/widgets/mystery_chest_overlay.dart';

class MysteryChestDialog extends StatefulWidget {
  const MysteryChestDialog({super.key});

  @override
  State<MysteryChestDialog> createState() => _MysteryChestDialogState();
}

class _MysteryChestDialogState extends State<MysteryChestDialog> {
  late ConfettiController _confettiController;
  Timer? _autoCloseTimer;
  bool _chestOpened = false;
  bool _confettiPlayed = false;
  int _rewardAmount = 0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _openChest() async {
    if (_chestOpened || !mounted) return;
    setState(() => _chestOpened = true);
    try {
      Haptics.vibrate(HapticsType.heavy);
    } catch (e) {
      // Haptics are a non-critical enhancement; some devices/emulators don't
      // support them. Swallow but keep a debug-only trace for diagnosis.
      if (kDebugMode) debugPrint('MysteryChestDialog: haptics unavailable: $e');
    }

    final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;

    // NOTE: this roll is computed client-side for the reveal animation only.
    // The authoritative reward MUST be validated/issued by the backend when
    // EconomyClaimDailyChestRequested is processed — never trust a
    // client-supplied amount as the source of truth for an economy mutation.
    final roll = Random().nextDouble();
    int totalCoins;
    if (roll < 0.05) {
      totalCoins = Random().nextInt(20) + 31; // 5%: 31-50 coins (jackpot)
    } else if (roll < 0.30) {
      totalCoins = Random().nextInt(15) + 16; // 25%: 16-30 coins
    } else {
      totalCoins = Random().nextInt(11) + 5; // 70%: 5-15 coins
    }

    if (isPremium) {
      // VIP Gifts stack on top of the 2x multiplier for massive drops!
      totalCoins = totalCoins * 3 + Random().nextInt(30);
    }

    if (!mounted) return;
    setState(() {
      _rewardAmount = totalCoins;
    });

    if (!_confettiPlayed) {
      _confettiPlayed = true;
      _confettiController.play();
    }
    context.read<EconomyBloc>().add(
      EconomyClaimDailyChestRequested(totalCoins),
    );

    // Wait for animation then close dialog. Stored so it can be cancelled if
    // the dialog is dismissed (e.g. by the system back button) before it fires.
    _autoCloseTimer?.cancel();
    _autoCloseTimer = Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;

    return Material(
      color: Colors.transparent,
      child: MysteryChestOverlay(
        isOpened: _chestOpened,
        isPremium: isPremium,
        rewardAmount: _rewardAmount,
        onOpen: _openChest,
        onClose: () {
          _autoCloseTimer?.cancel();
          Navigator.of(context).pop();
        },
        confettiController: _confettiController,
      ),
    );
  }
}
