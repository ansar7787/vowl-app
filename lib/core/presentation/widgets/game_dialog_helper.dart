import 'package:vowl/core/utils/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/widgets/modern_game_dialog.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/core/presentation/widgets/victory_flight_overlay.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';

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
  /// [buttonText] — primary CTA (e.g. context.tr('common.ok'), "GREAT", "AWESOME")
  /// [popResult] — optional result passed to `context.pop(result)`
  /// [enableDoubleUp] — if true, shows a "DOUBLE UP" ad button to 2× rewards
  static void showCompletion(
    BuildContext context, {
    required int xp,
    required int coins,
    String? title,
    String? description,
    String? buttonText,
    Object? popResult = true,
    bool enableDoubleUp = false,
  }) {
    _sound.playLevelComplete();
    _haptic.success();

    final resolvedTitle = title ?? context.tr('games.level_complete');
    final authState = context.read<AuthBloc>().state;
    final userLevel = authState.user?.level ?? 1;
    final isPremium = authState.user?.isPremium ?? false;
    final hasMultiplier = userLevel >= 100 || isPremium;

    String coinDesc = 'You earned $xp XP and $coins Coins!';
    if (hasMultiplier && coins > 0) {
      coinDesc += '\n✨ XP Level 100 Mastery: 2x Coin Bonus Applied!';
    }
    if (!hasMultiplier) {
      coinDesc += '\nWatch an ad to TRIPLE your COINS to ${coins * 3}!';
    }

    final desc = description ?? coinDesc;
    final resolvedButtonText = buttonText ?? context.tr('common.ok').toUpperCase();

    // Trigger Victory Flight centrally
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => VictoryFlightOverlay(
        level: userLevel,
        accessoryId: authState.user?.vowlEquippedAccessory,
        onFinished: () => entry.remove(),
      ),
    );
    Overlay.of(context).insert(entry);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => ModernGameDialog(
        title: resolvedTitle,
        description: desc,
        buttonText: resolvedButtonText,
        onButtonPressed: () {
          Navigator.pop(c);
          if (context.mounted) {
            Navigator.of(context).pop(popResult);
          }
        },
        onAdAction: enableDoubleUp
            ? () {
                final adService = di.sl<AdService>();
                if (!adService.isRewardedAdLoaded) {
                  showPremiumSnackBar(
                    context, 
                    "Ad not ready yet. Please try again in a few seconds! ⏳",
                    icon: Icons.hourglass_empty_rounded,
                    color: Colors.orange,
                  );
                  // Don't pop the dialog, let them try again
                  return;
                }

                Navigator.pop(c);
                final isPremium =
                    context.read<AuthBloc>().state.user?.isPremium ?? false;
                adService.showRewardedAd(
                  isPremium: isPremium,
                  onUserEarnedReward: (_) {
                    if (!context.mounted) return;
                    context.read<EconomyBloc>().add(
                      EconomyTripleUpRewardsRequested(0, coins * 2),
                    );
                    showPremiumSnackBar(
                      context,
                      'COINS TRIPLED! 💎💎💎',
                      icon: Icons.auto_awesome_rounded,
                      color: const Color(0xFF10B981),
                    );
                    Navigator.of(context).pop(popResult);
                  },
                  onDismissed: () {
                    if (context.mounted) {
                      Navigator.of(context).pop(popResult);
                    }
                  },
                );
              }
            : null,
        adButtonText: 'TRIPLE COINS',
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
    VoidCallback? onTutorPass,
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
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
        onAdAction: onRestore != null
            ? () {
                final isPremium =
                    context.read<AuthBloc>().state.user?.isPremium ?? false;
                if (isPremium) {
                  onRestore();
                  Navigator.pop(c);
                } else {
                  final adService = di.sl<AdService>();
                  if (!adService.isRewardedAdLoaded) {
                    showPremiumSnackBar(
                      context, 
                      "Ad not ready yet. Please try again in a few seconds! ⏳",
                      icon: Icons.hourglass_empty_rounded,
                      color: Colors.orange,
                    );
                    return;
                  }

                  adService.showRewardedAd(
                    isPremium: false,
                    onUserEarnedReward: (_) {
                      onRestore();
                      if (c.mounted) {
                        Navigator.pop(c);
                      }
                    },
                    onDismissed: () {},
                  );
                }
              }
            : null,
        adButtonText: onRestore != null ? adButtonText : null,
        onSecondaryPressed: onTutorPass != null 
          ? () {
            Navigator.pop(c);
            onTutorPass();
          } 
          : null,
        secondaryButtonText: 'I SPOKE CORRECTLY! 🌟',
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Exit Confirmation Dialog
  // ─────────────────────────────────────────────────────────────────────

  /// Shows a confirmation dialog before exiting a game session.
  ///
  /// [onQuit] — callback executed if the user confirms quitting.
  static void showExitConfirmation(
    BuildContext context, {
    required VoidCallback onQuit,
    String title = 'QUIT GAME?',
    String description = 'Your current progress for this level will be lost. Are you sure you want to quit?',
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (c) => ModernGameDialog(
        title: title,
        description: description,
        buttonText: 'KEEP PLAYING',
        isSuccess: true, // Use positive styling for "staying"
        onButtonPressed: () => Navigator.pop(c),
        isExitConfirmation: true, 
        adButtonText: context.tr('games.kids_quit_button'),
        onAdAction: () {
          Navigator.pop(c);
          onQuit();
        },
      ),
    );
  }

  /// Shows a premium hint dialog.
  static void showHintDialog(
    BuildContext context, {
    required String hint,
    String? title,
  }) {
    final resolvedTitle = title ?? context.tr('games.hint').toUpperCase();
    showDialog(
      context: context,
      builder: (c) => ModernGameDialog(
        title: resolvedTitle,
        description: hint,
        buttonText: context.tr('games.got_it'),
        onButtonPressed: () => Navigator.pop(c),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Premium SnackBar
  // ─────────────────────────────────────────────────────────────────────

  /// Shows a premium, floating snackbar.
  static void showPremiumSnackBar(
    BuildContext context,
    String message, {
    IconData icon = Icons.info_outline_rounded,
    Color? color,
    Duration duration = const Duration(seconds: 3),
  }) {
    // final primaryColor removed

    CustomSnackBar.show(
      context: context,
      message: message,
      type: CustomSnackBarType.info,
    );
  }

  static void showHintAdDialog(
    BuildContext context, {
    VoidCallback? onHintEarned,
    bool persistToAccount = true,
  }) {

    showDialog(
      context: context,
      builder: (ctx) => ModernGameDialog(
        title: 'NEED A HINT?',
        description:
            'You are out of hints! Watch a quick ad to get 1 Strategic Hint for free.',
        buttonText: context.tr('notification_card.not_now').toUpperCase(),
        onButtonPressed: () => Navigator.pop(ctx),
        onAdAction: () {
          final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;
          final adService = di.sl<AdService>();
          
          if (!isPremium && !adService.isRewardedAdLoaded) {
            showPremiumSnackBar(
              context, 
              "Ad not ready yet. Please try again in a few seconds! ⏳",
              icon: Icons.hourglass_empty_rounded,
              color: Colors.orange,
            );
            return;
          }

          Navigator.pop(ctx);
          adService.showHintRewardedAd(
            isPremium: isPremium,
            onHintEarned: () {
              onHintEarned?.call();
              if (!context.mounted) return;
              
              if (persistToAccount) {
                // Also persist to account
                context.read<EconomyBloc>().add(
                  const EconomyPurchaseHintRequested(0, hintAmount: 1),
                );
              }
              
              // Show success feedback
              showPremiumSnackBar(
                context, 
                "REWARD EARNED: +1 Strategic Hint!",
                icon: Icons.lightbulb_rounded,
                color: const Color(0xFFF59E0B), // Amber color for hints
              );
            },
            onDismissed: () {},
          );
        },
        adButtonText: 'WATCH AD FOR HINT',
        isRescueLife: true, // This makes the "Not Now" button grey and secondary
        customIcon: Icon(
          Icons.lightbulb_rounded,
          color: const Color(0xFFF59E0B),
          size: 48.r,
        ),
      ),
    );
  }
  static void showHonestyNudge(BuildContext context) {
    CustomSnackBar.show(
      context: context,
      message: "HONESTY IS MASTERY 🛡️",
      type: CustomSnackBarType.warning,
    );
  }
}
