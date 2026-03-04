import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voxai_quest/core/presentation/widgets/modern_game_dialog.dart';
import 'package:voxai_quest/core/utils/ad_service.dart';
import 'package:voxai_quest/core/utils/haptic_service.dart';
import 'package:voxai_quest/core/utils/injection_container.dart' as di;
import 'package:voxai_quest/core/utils/sound_service.dart';
import 'package:voxai_quest/features/auth/presentation/bloc/auth_bloc.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  GameDialogHelper — Shared completion & game-over dialogs for ALL games
// ═══════════════════════════════════════════════════════════════════════════
//
//  Usage:
//    GameDialogHelper.showCompletion(context, xp: 5, coins: 10, title: 'Great!');
//    GameDialogHelper.showGameOver(context, onRestore: () => bloc.add(RestoreLife()));
//
// ═══════════════════════════════════════════════════════════════════════════

class GameDialogHelper {
  GameDialogHelper._(); // Prevent instantiation

  static final _sound = di.sl<SoundService>();
  static final _haptic = di.sl<HapticService>();

  // ─────────────────────────────────────────────────────────────────────
  //  Level Complete Dialog
  // ─────────────────────────────────────────────────────────────────────

  /// Shows the level completion dialog.
  ///
  /// [title] — headline text (e.g. "Phonetic Pro!", "Word Architect!")
  /// [description] — body text (e.g. "You earned 5 XP and 10 Coins!")
  /// [buttonText] — primary CTA (e.g. "OK", "GREAT", "AWESOME")
  /// [popResult] — optional result passed to `context.pop(result)`
  /// [enableDoubleUp] — if true, shows a "DOUBLE UP" ad button to 2× rewards
  static void showCompletion(
    BuildContext context, {
    required int xp,
    required int coins,
    String title = 'Level Complete!',
    String? description,
    String buttonText = 'OK',
    Object? popResult,
    bool enableDoubleUp = false,
  }) {
    _sound.playLevelComplete();
    _haptic.success();

    final desc = description ?? 'You earned $xp XP and $coins Coins!';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => ModernGameDialog(
        title: title,
        description: desc,
        buttonText: buttonText,
        onButtonPressed: () {
          Navigator.pop(c);
          context.pop(popResult);
        },
        onAdAction: enableDoubleUp
            ? () {
                Navigator.pop(c);
                final isPremium =
                    context.read<AuthBloc>().state.user?.isPremium ?? false;
                di.sl<AdService>().showRewardedAd(
                  isPremium: isPremium,
                  onUserEarnedReward: (_) {
                    context.read<AuthBloc>().add(
                      AuthDoubleUpRewardsRequested(xp, coins),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('REWARDS DOUBLED! 💎💎'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  },
                  onDismissed: () => context.pop(popResult),
                );
              }
            : null,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Game Over Dialog (with optional rescue-life via rewarded ad)
  // ─────────────────────────────────────────────────────────────────────

  /// Shows the game-over dialog.
  ///
  /// [title] — headline (e.g. "Frequency Lost", "Reading Interrupted")
  /// [description] — body text
  /// [buttonText] — quit/give-up button text
  /// [onRestore] — if provided, adds "WATCH AD TO CONTINUE" rescue button.
  ///               The callback should dispatch `RestoreLife()` to the BLoC.
  /// [adButtonText] — customize the ad button label
  static void showGameOver(
    BuildContext context, {
    String title = 'Game Over',
    String description = 'Out of hearts. Try again!',
    String buttonText = 'GIVE UP',
    VoidCallback? onRestore,
    String adButtonText = 'WATCH AD',
  }) {
    _haptic.error();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => ModernGameDialog(
        title: title,
        description: description,
        buttonText: buttonText,
        isSuccess: false,
        isRescueLife: onRestore != null,
        onButtonPressed: () {
          Navigator.pop(c);
          context.pop();
        },
        onAdAction: onRestore != null
            ? () {
                final isPremium =
                    context.read<AuthBloc>().state.user?.isPremium ?? false;
                if (isPremium) {
                  onRestore();
                  Navigator.pop(c);
                } else {
                  di.sl<AdService>().showRewardedAd(
                    isPremium: false,
                    onUserEarnedReward: (_) {
                      onRestore();
                      Navigator.pop(c);
                    },
                    onDismissed: () {},
                  );
                }
              }
            : null,
        adButtonText: onRestore != null ? adButtonText : null,
      ),
    );
  }
}
