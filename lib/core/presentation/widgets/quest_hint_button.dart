import 'package:vowl/core/utils/hint_utility.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Interactive hint button providing TTS-enabled hints, ad-backed rewarded
/// hints, and visual status badges.
///
/// Uses [BlocSelector] to rebuild only when [hintCount] changes — not on
/// every [AuthState] update.
class QuestHintButton extends StatelessWidget {
  final bool used;
  final Color primaryColor;
  final String? hintText;
  final VoidCallback onTap;
  final SoundService soundService;

  const QuestHintButton({
    super.key,
    required this.used,
    required this.primaryColor,
    this.hintText,
    required this.onTap,
    required this.soundService,
  });

  void _handleTap(BuildContext context, int hintCount) {
    final canUseHint = !used && hintCount > 0;
    if (canUseHint) {
      soundService.playHint();
      onTap();

      if (hintText != null) {
        final isDynamic = HintUtility.isGenericHint(hintText);
        final displayText = isDynamic
            ? context.tr('hint.pro_tip_generic', fallback: 'Pro Tip')
            : hintText!;

        di.sl<TtsService>().speak(
          isDynamic
              ? context.tr(
                  'hint.pro_tip_tts',
                  fallback: 'Listen carefully to the pronunciation.',
                )
              : hintText!,
        );

        CustomSnackBar.show(
          context: context,
          message: displayText,
          type: CustomSnackBarType.info,
          duration: const Duration(seconds: 8),
        );
      }
    } else if (!used) {
      GameDialogHelper.showHintAdDialog(context, onHintEarned: onTap);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final hintCount = state.user?.hintCount ?? 0;
        final isPremium = state.user?.isPremium ?? false;
        final canUseHint = !used && hintCount > 0;

        return Semantics(
          button: true,
          enabled: !used,
          label: used
              ? context.tr(
                  'hint.already_used_semantic',
                  fallback: 'Hint already used',
                )
              : canUseHint
              ? context.tr(
                  'hint.use_hint_semantic',
                  args: ['$hintCount'],
                  fallback: 'Use hint ($hintCount remaining)',
                )
              : isPremium
                  ? context.tr(
                      'hint.get_free_hint_semantic',
                      fallback: 'Get a free hint',
                    )
                  : context.tr(
                      'hint.watch_ad_semantic',
                      fallback: 'Watch ad to earn a hint',
                    ),
          child: ScaleButton(
            onTap: () => _handleTap(context, hintCount),
            child: RepaintBoundary(
              child: Container(
                width: 48.r,
                height: 48.r,
                decoration: BoxDecoration(
                  color: canUseHint
                      ? primaryColor.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: canUseHint
                        ? primaryColor.withValues(alpha: 0.4)
                        : Colors.grey.withValues(alpha: 0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    if (canUseHint)
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.2),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Main icon
                    Icon(
                          used
                              ? Icons.psychology_outlined
                              : (hintCount > 0
                                    ? Icons.lightbulb_rounded
                                    : (isPremium
                                          ? Icons.add_circle_outline_rounded
                                          : Icons.video_collection_rounded)),
                          color: used
                              ? Colors.grey
                              : (hintCount > 0
                                    ? primaryColor
                                    : (isPremium ? Colors.greenAccent : Colors.amber[700])),
                          size: 26.r,
                        )
                        .animate(
                          onPlay: (c) =>
                              used ? c.stop() : c.repeat(reverse: true),
                        )
                        .shimmer(
                          duration: 2.seconds,
                          color: primaryColor.withValues(alpha: 0.3),
                        ),

                    // Hint count badge (when hints available)
                    if (!used && hintCount > 0)
                      Positioned(
                        top: 2.r,
                        right: 2.r,
                        child: Container(
                          padding: EdgeInsets.all(4.r),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16.r,
                            minHeight: 16.r,
                          ),
                          child: Center(
                            child: Text(
                              '$hintCount',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Ad badge (when 0 hints)
                    if (!used && hintCount == 0)
                      Positioned(
                        bottom: 4.r,
                        right: 4.r,
                        child: Container(
                          padding: EdgeInsets.all(2.r),
                          decoration: BoxDecoration(
                            color: isPremium ? Colors.green : const Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Icon(
                            isPremium ? Icons.add : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 10.r,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
