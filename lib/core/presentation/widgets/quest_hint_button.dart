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

/// A premium, interactive gameplay action button providing TTS-enabled hints,
/// ad-backed rewarded hints, and visual status badges, isolated with a RepaintBoundary.
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final hintCount = authState.user?.hintCount ?? 0;
        final canUseHint = !used && hintCount > 0;

        return ScaleButton(
          onTap: () {
            if (canUseHint) {
              soundService.playHint();
              onTap();
              
              if (hintText != null) {
                final isDynamic = HintUtility.isGenericHint(hintText);
                final displayText = isDynamic 
                    ? "PRO TIP: Look for context clues! Eliminating unlikely options often reveals the truth." 
                    : hintText!;
                
                // Speak the hint text
                di.sl<TtsService>().speak(isDynamic ? "Pro tip: Look for context clues." : hintText!);
                
                CustomSnackBar.show(
                  context: context,
                  message: displayText,
                  type: CustomSnackBarType.info,
                );
              }
            } else if (!used) {
              GameDialogHelper.showHintAdDialog(context, onHintEarned: onTap);
            }
          },
          child: RepaintBoundary(
            child: Container(
              width: 48.r, height: 48.r,
              decoration: BoxDecoration(
                color: canUseHint ? primaryColor.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: canUseHint ? primaryColor.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.2), width: 2),
                boxShadow: [if (canUseHint) BoxShadow(color: primaryColor.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 1)],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Main Icon (Lightbulb/Psychology/Video)
                  Icon(
                    used 
                      ? Icons.psychology_outlined 
                      : (hintCount > 0 ? Icons.lightbulb_rounded : Icons.video_collection_rounded),
                    color: used ? Colors.grey : (hintCount > 0 ? primaryColor : Colors.amber[700]),
                    size: 26.r,
                  ).animate(onPlay: (c) => used ? c.stop() : c.repeat(reverse: true))
                   .shimmer(duration: 2.seconds, color: primaryColor.withValues(alpha: 0.3)),
                  
                  // Hint Count Badge (Active)
                  if (!used && hintCount > 0)
                    Positioned(
                      top: 2.r, right: 2.r,
                      child: Container(
                        padding: EdgeInsets.all(4.r),
                        decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1)),
                        constraints: BoxConstraints(minWidth: 16.r, minHeight: 16.r),
                        child: Center(child: Text(hintCount.toString(), style: TextStyle(fontFamily: 'RobotoMono', fontSize: 9.sp, fontWeight: FontWeight.w900, color: Colors.white))),
                      ),
                    ),
  
                  // Ad Badge (When 0 hints)
                  if (!used && hintCount == 0)
                    Positioned(
                      bottom: 4.r, right: 4.r,
                      child: Container(
                        padding: EdgeInsets.all(2.r),
                        decoration: BoxDecoration(color: const Color(0xFFF59E0B), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1)),
                        child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 10.r),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
