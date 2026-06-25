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
//  GameDialogHelper — Shared completion & game-over dialogs for ALL games.
//
//  Usage:
//    GameDialogHelper.showCompletion(context, xp: 5, coins: 10);
//    GameDialogHelper.showGameOver(context, onRestore: () => bloc.add(...));
// ═══════════════════════════════════════════════════════════════════════════

class GameDialogHelper {
  GameDialogHelper._();

  // Lazy getters resolve from DI at call-time (not class-load time).
  // This keeps the helper fully testable via DI overrides and avoids
  // hidden initialisation-order dependencies.
  static SoundService get _sound => di.sl<SoundService>();
  static HapticService get _haptic => di.sl<HapticService>();

  // ─── Level Complete ───────────────────────────────────────────────────

  /// Shows the level-completion dialog with optional "TRIPLE COINS" ad action.
  ///
  /// [enableDoubleUp] — when true, adds an ad button that triples coins.
  /// [popResult] — value passed to `Navigator.pop()` when the CTA is pressed.
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
    if (!context.mounted) return;

    _sound.playLevelComplete();
    _haptic.success();

    final authState = context.read<AuthBloc>().state;
    final userLevel = authState.user?.level ?? 1;
    final isPremium = authState.user?.isPremium ?? false;
    final hasMultiplier = userLevel >= 100 || isPremium;

    final resolvedTitle = title ?? context.tr('games.level_complete');
    final resolvedButtonText =
        buttonText ?? context.tr('common.ok').toUpperCase();

    String coinDesc = 'You earned $xp XP and $coins Coins!';
    if (hasMultiplier && coins > 0) {
      coinDesc += '\n✨ XP Level 100 Mastery: 2x Coin Bonus Applied!';
    } else if (!hasMultiplier) {
      coinDesc += '\nWatch an ad to TRIPLE your COINS to ${coins * 3}!';
    }
    final desc = description ?? coinDesc;

    // ── Victory fly-over overlay ─────────────────────────────────────────
    // Hold a reference to safely remove the entry from inside the callback.
    OverlayEntry? overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (_) => VictoryFlightOverlay(
        level: userLevel,
        accessoryId: authState.user?.vowlEquippedAccessory,
        onFinished: () {
          // Guard: entry may already be removed if context disposed mid-flight.
          if (overlayEntry?.mounted == true) {
            overlayEntry!.remove();
          }
        },
      ),
    );

    if (context.mounted) {
      Overlay.of(context).insert(overlayEntry);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => ModernGameDialog(
        title: resolvedTitle,
        description: desc,
        buttonText: resolvedButtonText,
        onButtonPressed: () {
          Navigator.of(dialogCtx).pop();
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
                    context.tr('games.ad_not_ready'),
                    icon: Icons.hourglass_empty_rounded,
                    color: Colors.orange,
                  );
                  return;
                }

                Navigator.of(dialogCtx).pop();
                final isPrem =
                    context.read<AuthBloc>().state.user?.isPremium ?? false;

                adService.showRewardedAd(
                  isPremium: isPrem,
                  onUserEarnedReward: (_) {
                    if (!context.mounted) return;
                    context.read<EconomyBloc>().add(
                      EconomyTripleUpRewardsRequested(0, coins * 2),
                    );
                    showPremiumSnackBar(
                      context,
                      context.tr('games.coins_tripled'),
                      icon: Icons.auto_awesome_rounded,
                      color: const Color(0xFF10B981),
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop(popResult);
                    }
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

  // ─── Game Over ────────────────────────────────────────────────────────

  /// Shows the game-over dialog with an optional rewarded-ad rescue button.
  ///
  /// [onRestore] — when provided, shows "WATCH AD TO CONTINUE". The callback
  ///   should dispatch a `RestoreLife` event to the feature's BLoC.
  static void showGameOver(
    BuildContext context, {
    String title = 'Game Over',
    String description = 'Out of hearts. Try again!',
    String buttonText = 'GIVE UP',
    VoidCallback? onRestore,
    String adButtonText = 'WATCH AD',
    VoidCallback? onTutorPass,
  }) {
    if (!context.mounted) return;
    _haptic.error();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => ModernGameDialog(
        title: title,
        description: description,
        buttonText: buttonText,
        isSuccess: false,
        isRescueLife: onRestore != null,
        onButtonPressed: () {
          Navigator.of(dialogCtx).pop();
          if (context.mounted) Navigator.of(context).pop();
        },
        onAdAction: onRestore != null
            ? () {
                final isPremium =
                    context.read<AuthBloc>().state.user?.isPremium ?? false;
                if (isPremium) {
                  onRestore();
                  Navigator.of(dialogCtx).pop();
                  return;
                }

                final adService = di.sl<AdService>();
                if (!adService.isRewardedAdLoaded) {
                  showPremiumSnackBar(
                    context,
                    context.tr('games.ad_not_ready'),
                    icon: Icons.hourglass_empty_rounded,
                    color: Colors.orange,
                  );
                  return;
                }

                adService.showRewardedAd(
                  isPremium: false,
                  onUserEarnedReward: (_) {
                    onRestore();
                    if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                  },
                  onDismissed: () {},
                );
              }
            : null,
        adButtonText: onRestore != null ? adButtonText : null,
        onSecondaryPressed: onTutorPass != null
            ? () {
                Navigator.of(dialogCtx).pop();
                onTutorPass();
              }
            : null,
        secondaryButtonText: 'I SPOKE CORRECTLY! 🌟',
      ),
    );
  }

  // ─── Exit Confirmation ────────────────────────────────────────────────

  /// Confirms before abandoning a game session.
  static void showExitConfirmation(
    BuildContext context, {
    required VoidCallback onQuit,
    String title = 'QUIT GAME?',
    String description =
        'Your current progress for this level will be lost. Are you sure?',
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => ModernGameDialog(
        title: title,
        description: description,
        buttonText: 'KEEP PLAYING',
        isSuccess: true,
        onButtonPressed: () => Navigator.of(dialogCtx).pop(),
        isExitConfirmation: true,
        adButtonText: context.tr('games.kids_quit_button'),
        onAdAction: () {
          Navigator.of(dialogCtx).pop();
          onQuit();
        },
      ),
    );
  }

  // ─── Hint dialog ──────────────────────────────────────────────────────

  /// Shows a hint card with the provided [hint] string.
  static void showHintDialog(
    BuildContext context, {
    required String hint,
    String? title,
  }) {
    final resolvedTitle = title ?? context.tr('games.hint').toUpperCase();
    showDialog(
      context: context,
      builder: (dialogCtx) => ModernGameDialog(
        title: resolvedTitle,
        description: hint,
        buttonText: context.tr('games.got_it'),
        onButtonPressed: () => Navigator.of(dialogCtx).pop(),
      ),
    );
  }

  // ─── Premium SnackBar ─────────────────────────────────────────────────

  /// Displays a floating app-wide snack bar notification.
  static void showPremiumSnackBar(
    BuildContext context,
    String message, {
    IconData icon = Icons.info_outline_rounded,
    Color? color,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;
    CustomSnackBar.show(
      context: context,
      message: message,
      type: CustomSnackBarType.info,
    );
  }

  // ─── Hint Ad Dialog ───────────────────────────────────────────────────

  /// Prompts the user to watch an ad to earn a free strategic hint.
  static void showHintAdDialog(
    BuildContext context, {
    VoidCallback? onHintEarned,
    bool persistToAccount = true,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) => ModernGameDialog(
        title: 'NEED A HINT?',
        description:
            'You are out of hints! Watch a quick ad to get 1 Strategic Hint for free.',
        buttonText: context.tr('notification_card.not_now').toUpperCase(),
        onButtonPressed: () => Navigator.of(dialogCtx).pop(),
        onAdAction: () {
          final isPremium =
              context.read<AuthBloc>().state.user?.isPremium ?? false;
          final adService = di.sl<AdService>();

          if (!isPremium && !adService.isRewardedAdLoaded) {
            showPremiumSnackBar(
              context,
              context.tr('games.ad_not_ready'),
              icon: Icons.hourglass_empty_rounded,
              color: Colors.orange,
            );
            return;
          }

          Navigator.of(dialogCtx).pop();
          adService.showHintRewardedAd(
            isPremium: isPremium,
            onHintEarned: () {
              if (!context.mounted) return;
              if (persistToAccount) {
                context.read<EconomyBloc>().add(
                  const EconomyPurchaseHintRequested(0, hintAmount: 1),
                );
              }
              showPremiumSnackBar(
                context,
                'REWARD EARNED: +1 Strategic Hint!',
                icon: Icons.lightbulb_rounded,
                color: const Color(0xFFF59E0B),
              );
            },
            onDismissed: () {},
          );
        },
        adButtonText: 'WATCH AD FOR HINT',
        isRescueLife: true,
        customIcon: Icon(
          Icons.lightbulb_rounded,
          color: const Color(0xFFF59E0B),
          size: 48.r,
        ),
      ),
    );
  }

  // ─── Honesty nudge ────────────────────────────────────────────────────

  static void showHonestyNudge(BuildContext context) {
    if (!context.mounted) return;
    CustomSnackBar.show(
      context: context,
      message: 'HONESTY IS MASTERY 🛡️',
      type: CustomSnackBarType.warning,
    );
  }
}
