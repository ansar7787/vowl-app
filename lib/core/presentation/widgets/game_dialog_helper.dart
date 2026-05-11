import 'package:vowl/core/utils/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/widgets/modern_game_dialog.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/victory_flight_overlay.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    Object? popResult = true,
    bool enableDoubleUp = false,
  }) {
    _sound.playLevelComplete();
    _haptic.success();

    final desc = description ??
        'You earned $xp XP and $coins Coins!\nWatch an ad to TRIPLE your COINS to ${coins * 3}!';

    // Trigger Victory Flight centrally
    final authState = context.read<AuthBloc>().state;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => VictoryFlightOverlay(
        level: authState.user?.level ?? 1,
        accessoryId: authState.user?.vowlEquippedAccessory,
        onFinished: () => entry.remove(),
      ),
    );
    Overlay.of(context).insert(entry);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => ModernGameDialog(
        title: title,
        description: desc,
        buttonText: buttonText,
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
                    context.read<EconomyBloc>().add(
                      EconomyTripleUpRewardsRequested(0, coins * 2),
                    );
                    showPremiumSnackBar(
                      context,
                      'COINS TRIPLED! 💎💎💎',
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
                      Navigator.pop(c);
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
        adButtonText: 'QUIT',
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
    String title = 'HINT',
  }) {
    showDialog(
      context: context,
      builder: (c) => ModernGameDialog(
        title: title,
        description: hint,
        buttonText: 'GOT IT',
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
    final primaryColor = color ?? const Color(0xFF6366F1); // Indigo default

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20.r),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryColor.withValues(alpha: 0.9),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        margin: EdgeInsets.all(20.r),
        duration: duration,
      ),
    );
  }

  static void showHintAdDialog(
    BuildContext context, {
    VoidCallback? onHintEarned,
  }) {

    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 32.w),
          child: ModernGameDialog(
            title: 'NEED A HINT?',
            description:
                'You are out of hints! Watch a quick ad to get 1 Strategic Hint for free.',
            buttonText: 'NOT NOW',
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
                  // Also persist to account
                  context.read<EconomyBloc>().add(
                    const EconomyPurchaseHintRequested(0, hintAmount: 1),
                  );
                  
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
            isSuccess: false,
          ),
        ),
      ),
    );
  }
  static void showHonestyNudge(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        content: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber[700]!, Colors.orange[900]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28.r),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "HONESTY IS MASTERY 🛡️",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13.sp,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "Your education is our key, not false use or lie. Practice honestly to truly master English! ✨",
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: 11.sp,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
