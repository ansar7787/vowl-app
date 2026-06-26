import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';

class AccentShadowingMicTrigger extends StatelessWidget {
  final bool isListening;
  final VoidCallback onTap;
  final VoidCallback onTutorPass;
  final Color primaryColor;
  final int attempts;
  final bool isAnswered;

  const AccentShadowingMicTrigger({
    super.key,
    required this.isListening,
    required this.onTap,
    required this.onTutorPass,
    required this.primaryColor,
    required this.attempts,
    required this.isAnswered,
  });

  @override
  Widget build(BuildContext context) {
    if (isAnswered) return const SizedBox.shrink();

    return Column(
      children: [
        Semantics(
          button: true,
          label: isListening
              ? context.tr('games.semantic_mic_stop')
              : context.tr('games.semantic_mic_start'),
          excludeSemantics: true,
          child:
              ScaleButton(
                    onTap: onTap,
                    child: Container(
                      width: 100.r,
                      height: 100.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isListening ? Colors.red : primaryColor,
                        boxShadow: [
                          BoxShadow(
                            color: (isListening ? Colors.red : primaryColor)
                                .withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: isListening ? 10 : 0,
                          ),
                        ],
                      ),
                      child: Icon(
                        isListening ? Icons.stop_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 48.r,
                      ),
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .scale(
                    begin: const Offset(1, 1),
                    end: isListening
                        ? const Offset(1.1, 1.1)
                        : const Offset(1, 1),
                    duration: 800.ms,
                  ),
        ),
        if (attempts > 0 && !isListening)
          Padding(
            padding: EdgeInsets.only(top: 20.h),
            child: Semantics(
              button: true,
              hint: context.tr('games.semantic_tutor_pass_hint'),
              child: ScaleButton(
                onTap: onTutorPass,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.amber, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.amber,
                        size: 18.r,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        context.tr('games.i_spoke_correctly').toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: Colors.amber,
                          fontWeight: FontWeight.w900,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().fadeIn().shake(),
      ],
    );
  }
}
