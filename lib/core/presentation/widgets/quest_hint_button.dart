import 'package:vowl/core/utils/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(seconds: 6),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    behavior: SnackBarBehavior.floating,
                    content: Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withValues(alpha: 0.9),
                            primaryColor.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 20.r,
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "MASTER'S HINT",
                                  style: GoogleFonts.outfit(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  hintText!,
                                  style: GoogleFonts.outfit(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    height: 1.2,
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
            } else if (!used) {
              GameDialogHelper.showHintAdDialog(context, onHintEarned: onTap);
            }
          },
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
                ).animate(onPlay: (c) => used ? c.stop() : c.repeat(reverse: true)).shimmer(duration: 2.seconds, color: primaryColor.withValues(alpha: 0.3)),
                
                // Hint Count Badge (Active)
                if (!used && hintCount > 0)
                  Positioned(
                    top: 2.r, right: 2.r,
                    child: Container(
                      padding: EdgeInsets.all(4.r),
                      decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1)),
                      constraints: BoxConstraints(minWidth: 16.r, minHeight: 16.r),
                      child: Center(child: Text(hintCount.toString(), style: GoogleFonts.shareTechMono(fontSize: 9.sp, fontWeight: FontWeight.w900, color: Colors.white))),
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
        );
      },
    );
  }
}
