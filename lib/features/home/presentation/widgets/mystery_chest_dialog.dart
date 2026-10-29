import 'dart:async';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/home/presentation/widgets/mystery_chest_overlay.dart';

/// Dialog presenting the daily mystery chest unlock ceremony with celebratory animations.
class MysteryChestDialog extends StatefulWidget {
  /// Creates a [MysteryChestDialog].
  const MysteryChestDialog({super.key});

  @override
  State<MysteryChestDialog> createState() => _MysteryChestDialogState();
}

class _MysteryChestDialogState extends State<MysteryChestDialog> {
  late ConfettiController _confettiController;
  Timer? _autoCloseTimer;
  final ValueNotifier<bool> _chestOpened = ValueNotifier(false);
  final ValueNotifier<int> _rewardAmount = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _confettiController.dispose();
    _chestOpened.dispose();
    _rewardAmount.dispose();
    super.dispose();
  }

  Future<void> _openChest() async {
    if (_chestOpened.value || !mounted) return;

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

    // Set reward FIRST, then trigger open — so the overlay can show the
    // amount as soon as the reward card animates in.
    _rewardAmount.value = totalCoins;
    _chestOpened.value = true;

    context.read<EconomyBloc>().add(
      EconomyClaimDailyChestRequested(totalCoins),
    );

    // Wait for the snappy animation sequence + comfortable viewing time, then auto-close.
    // Stored so it can be cancelled if the dialog is dismissed early or user taps COLLECT.
    _autoCloseTimer?.cancel();
    _autoCloseTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;

    return ListenableBuilder(
      listenable: Listenable.merge([_chestOpened, _rewardAmount]),
      builder: (context, _) {
        return Material(
          color: Colors.transparent,
          child: MysteryChestOverlay(
            isOpened: _chestOpened.value,
            isPremium: isPremium,
            rewardAmount: _rewardAmount.value,
            onOpen: _openChest,
            onClose: () {
              _autoCloseTimer?.cancel();
              if (mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            confettiController: _confettiController,
          ),
        );
      },
    );
  }
}
