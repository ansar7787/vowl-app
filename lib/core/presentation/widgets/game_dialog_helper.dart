import 'package:vowl/core/utils/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/widgets/modern_game_dialog.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/offline_play_gate_service.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/core/presentation/widgets/victory_flight_overlay.dart';
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/features/auth/data/repositories/gamification_repository_impl.dart';

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

    // ── Offline play quota tracking ──────────────────────────────────────
    // When a free user completes a level while offline, increment the gate
    // counter. After [OfflinePlayGateService.maxOfflineLevels] completions,
    // the ConnectivityWrapper will hard-block until reconnection — ensuring
    // ad revenue isn't permanently bypassed by airplane-mode abuse.
    // Premium users are unaffected: NetworkInfo.setPremiumOverride makes
    // their stream always report online, so this path never fires for them.
    // Fire-and-forget: showCompletion is synchronous void; the quota update
    // is registered before the next StreamBuilder rebuild in ConnectivityWrapper.
    di.sl<NetworkInfo>().isConnected.then((connected) {
      if (!connected) {
        OfflinePlayGateService.instance.recordOfflineLevel();
      }
    }).catchError((_) {
      // Network check failed — treat as offline to be safe
      OfflinePlayGateService.instance.recordOfflineLevel();
    });

    final authState = context.read<AuthBloc>().state;
    final userLevel = authState.user?.level ?? 1;
    final isPremium = authState.user?.isPremium ?? false;
    final hasMultiplier = userLevel >= 100 || isPremium;

    final resolvedTitle =
        title ??
        context.tr('games.level_complete', fallback: 'Level Complete!');
    final resolvedButtonText =
        buttonText ?? context.tr('common.ok', fallback: 'OK').toUpperCase();

    String coinDesc = context.tr(
      'games.reward_earned_title',
      args: ['$xp', '$coins'],
      fallback: 'You earned $xp XP and $coins Coins!',
    );
    if (hasMultiplier && coins > 0) {
      coinDesc +=
          '\n${context.tr('games.mastery_bonus_line', fallback: '✨ XP Level 100 Mastery: 2x Coin Bonus Applied!')}';
    } else if (!hasMultiplier) {
      coinDesc +=
          '\n${context.tr('games.triple_coins_line', args: ['${coins * 3}'], fallback: 'Watch an ad to TRIPLE your COINS to ${coins * 3}!')}';
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
      builder: (dialogCtx) => Stack(
        children: [
          ModernGameDialog(
            title: resolvedTitle,
            description: desc,
            buttonText: resolvedButtonText,
            starsListener: GamificationRepositoryImpl.lastEarnedStars,
            onButtonPressed: () {
              Navigator.of(dialogCtx).pop();
              if (context.mounted) {
                context.read<AuthBloc>().add(const AuthRefreshUser());
                Navigator.of(context).pop(popResult);
              }
            },
            onAdAction: enableDoubleUp
                ? () {
                    final adService = di.sl<AdService>();
                    if (!adService.isRewardedAdLoaded) {
                      showPremiumSnackBar(
                        context,
                        context.tr(
                          'games.ad_not_ready',
                          fallback: 'Ad not ready yet, try again soon.',
                        ),
                        icon: Icons.hourglass_empty_rounded,
                        color: Colors.orange,
                      );
                      return;
                    }

                    Navigator.of(dialogCtx).pop();
                    final isPrem =
                        context.read<AuthBloc>().state.user?.isPremium ?? false;

                    adService.showRewardedAd(
                      context: context,
                      isPremium: isPrem,
                      onUserEarnedReward: (_) {
                        if (!context.mounted) return;
                        context.read<EconomyBloc>().add(
                          EconomyTripleUpRewardsRequested(0, coins * 2),
                        );
                        showPremiumSnackBar(
                          context,
                          context.tr(
                            'games.coins_tripled',
                            fallback: 'Coins Tripled!',
                          ),
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
            adButtonText: context.tr(
              'games.triple_coins_button',
              fallback: 'TRIPLE COINS',
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(child: GameConfetti(shouldPop: false)),
            ),
          ),
        ],
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
    String? title,
    String? description,
    String? buttonText,
    VoidCallback? onRestore,
    String? adButtonText,
    VoidCallback? onTutorPass,
  }) {
    if (!context.mounted) return;
    // Removed _sound.playWrong() and _haptic.error() here to prevent double
    // negative feedback when transitioning from a wrong answer to Game Over.

    final resolvedTitle =
        title ?? context.tr('games.game_over_title', fallback: 'Game Over');
    final resolvedDescription =
        description ??
        context.tr(
          'games.game_over_desc',
          fallback: 'Out of hearts. Try again!',
        );
    final resolvedButtonText =
        buttonText ?? context.tr('games.give_up', fallback: 'GIVE UP');
    final resolvedAdButtonText =
        adButtonText ?? context.tr('games.watch_ad', fallback: 'WATCH AD');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => ModernGameDialog(
        title: resolvedTitle,
        description: resolvedDescription,
        buttonText: resolvedButtonText,
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
                    context.tr(
                      'games.ad_not_ready',
                      fallback: 'Ad not ready yet, try again soon.',
                    ),
                    icon: Icons.hourglass_empty_rounded,
                    color: Colors.orange,
                  );
                  return;
                }

                adService.showRewardedAd(
                  context: context,
                  isPremium: false,
                  onUserEarnedReward: (_) {
                    onRestore();
                    if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                  },
                  onDismissed: () {},
                );
              }
            : null,
        adButtonText: onRestore != null ? resolvedAdButtonText : null,
        onSecondaryPressed: onTutorPass != null
            ? () {
                Navigator.of(dialogCtx).pop();
                onTutorPass();
              }
            : null,
        secondaryButtonText: context.tr(
          'games.spoke_correctly_button',
          fallback: 'I SPOKE CORRECTLY! 🌟',
        ),
      ),
    );
  }

  // ─── Exit Confirmation ────────────────────────────────────────────────

  /// Confirms before abandoning a game session.
  static void showExitConfirmation(
    BuildContext context, {
    required VoidCallback onQuit,
    String? title,
    String? description,
  }) {
    final resolvedTitle =
        title ?? context.tr('games.quit_game_title', fallback: 'QUIT GAME?');
    final resolvedDescription =
        description ??
        context.tr(
          'games.quit_game_desc',
          fallback:
              'Your current progress for this level will be lost. Are you sure?',
        );
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => ModernGameDialog(
        title: resolvedTitle,
        description: resolvedDescription,
        buttonText: context.tr('games.keep_playing', fallback: 'KEEP PLAYING'),
        isSuccess: true,
        onButtonPressed: () => Navigator.of(dialogCtx).pop(),
        isExitConfirmation: true,
        adButtonText: context.tr('games.kids_quit_button', fallback: 'Quit'),
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
    final resolvedTitle =
        title ?? context.tr('games.hint', fallback: 'Hint').toUpperCase();
    showDialog(
      context: context,
      builder: (dialogCtx) => ModernGameDialog(
        title: resolvedTitle,
        description: hint,
        buttonText: context.tr('games.got_it', fallback: 'Got It!'),
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
    // BUG FIX: `icon`, `color`, and `duration` were accepted by this
    // method's signature but never forwarded to CustomSnackBar.show(),
    // which always received a hardcoded `type: CustomSnackBarType.info`
    // regardless of what the caller passed. Every call site in this file
    // requesting a warning/success-styled toast (e.g. "ad not ready" with
    // an orange hourglass icon, or "coins tripled" with a green sparkle
    // icon) was silently rendered as a generic blue "info" toast instead,
    // losing the caller's intended severity signal. CustomSnackBar's
    // public API themes by a fixed 4-value `type` enum rather than an
    // arbitrary icon/color pair, so this infers the closest matching type
    // from the requested `color` instead of changing this method's own
    // signature, which would be a breaking change for call sites outside
    // this file.
    CustomSnackBar.show(
      context: context,
      message: message,
      type: _inferSnackBarType(color),
      duration: duration,
    );
  }

  /// Maps a caller-provided accent [color] to the closest matching
  /// [CustomSnackBarType]. Falls back to [CustomSnackBarType.info] for
  /// `null` or any color that doesn't match one of the four semantic
  /// accent colors defined in `custom_snack_bar.dart`.
  static CustomSnackBarType _inferSnackBarType(Color? color) {
    if (color == null) return CustomSnackBarType.info;
    if (color == const Color(0xFF10B981) || color == Colors.green) {
      return CustomSnackBarType.success;
    }
    if (color == const Color(0xFFEF4444) || color == Colors.red) {
      return CustomSnackBarType.error;
    }
    if (color == Colors.orange || color == const Color(0xFFF59E0B)) {
      return CustomSnackBarType.warning;
    }
    return CustomSnackBarType.info;
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
        title: context.tr('games.hint_needed_title', fallback: 'NEED A HINT?'),
        description: context.tr(
          'games.hint_needed_desc',
          fallback:
              'You are out of hints! Watch a quick ad to get 1 Strategic Hint for free.',
        ),
        buttonText: context
            .tr('notification_card.not_now', fallback: 'Not Now')
            .toUpperCase(),
        onButtonPressed: () => Navigator.of(dialogCtx).pop(),
        onAdAction: () {
          final isPremium =
              context.read<AuthBloc>().state.user?.isPremium ?? false;
          final adService = di.sl<AdService>();

          if (!isPremium && !adService.isRewardedAdLoaded) {
            showPremiumSnackBar(
              context,
              context.tr(
                'games.ad_not_ready',
                fallback: 'Ad not ready yet, try again soon.',
              ),
              icon: Icons.hourglass_empty_rounded,
              color: Colors.orange,
            );
            return;
          }

          Navigator.of(dialogCtx).pop();
          adService.showHintRewardedAd(
            context: context,
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
                context.tr(
                  'games.hint_reward_earned',
                  fallback: 'REWARD EARNED: +1 Strategic Hint!',
                ),
                icon: Icons.lightbulb_rounded,
                color: const Color(0xFFF59E0B),
              );
            },
            onDismissed: () {},
          );
        },
        adButtonText: context.tr(
          'games.watch_ad_for_hint_button',
          fallback: 'WATCH AD FOR HINT',
        ),
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
      message: context.tr(
        'games.honesty_is_mastery',
        fallback: 'HONESTY IS MASTERY 🛡️',
      ),
      type: CustomSnackBarType.warning,
    );
  }
}
