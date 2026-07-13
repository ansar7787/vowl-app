import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';

class SpeakSynonymWateringMicTrigger extends StatelessWidget {
  final bool isListening;
  final Color primaryColor;
  final double timeVal;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;
  final int attempts;
  final bool isAnswered;
  final VoidCallback onTutorPass;

  const SpeakSynonymWateringMicTrigger({
    super.key,
    required this.isListening,
    required this.primaryColor,
    required this.timeVal,
    required this.onLongPressStart,
    required this.onLongPressEnd,
    required this.attempts,
    required this.isAnswered,
    required this.onTutorPass,
  });

  @override
  Widget build(BuildContext context) {
    if (isAnswered) return const SizedBox.shrink();

    return Column(
      children: [
        GestureDetector(
          onLongPressStart: (_) => onLongPressStart(),
          onLongPressEnd: (_) => onLongPressEnd(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Beautiful glowing water droplet streams floating up while recording is active
              if (isListening)
                ...List.generate(6, (i) {
                  final double shiftX =
                      -30.w + (i * 12.w) + (math.sin(timeVal * 10.0 + i) * 4.w);
                  return Positioned(
                    bottom: 50.h,
                    left: 1.sw / 2 + shiftX,
                    child:
                        Icon(
                              Icons.water_drop_rounded,
                              color: Colors.cyanAccent.withValues(alpha: 0.7),
                              size: (12.r + i * 2.r).clamp(10, 24).toDouble(),
                            )
                            .animate(onPlay: (c) => c.repeat())
                            .moveY(
                              begin: 0,
                              end: -120.h,
                              duration: Duration(milliseconds: 600 + i * 150),
                              curve: Curves.easeOut,
                            )
                            .fadeOut(),
                  );
                }),

              // Outer aura ring
              Container(
                    width: 96.r,
                    height: 96.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                      border: Border.all(
                        color: isListening
                            ? Colors.greenAccent.withValues(alpha: 0.3)
                            : primaryColor.withValues(alpha: 0.1),
                        width: 4.r,
                      ),
                    ),
                  )
                  .animate(target: isListening ? 1 : 0)
                  .scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.18, 1.18),
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeInOut,
                  ),

              // Sizzling inner watering can core
              ScaleButton(
                onTap: () {},
                child: Container(
                  width: 76.r,
                  height: 76.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isListening
                          ? [Colors.teal[800]!, Colors.greenAccent]
                          : [const Color(0xFF0F2027), const Color(0xFF203A43)],
                    ),
                    boxShadow: isListening
                        ? [
                            BoxShadow(
                              color: Colors.greenAccent.withValues(alpha: 0.45),
                              blurRadius: 25.r,
                              spreadRadius: 2.r,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10.r,
                            ),
                          ],
                  ),
                  child: Icon(
                    isListening
                        ? Icons.opacity_rounded
                        : Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 32.r,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          isListening
              ? "RELEASE CORE TO STOP WATERING"
              : "HOLD CAN TO WATER WITH A SPOKEN SYNONYM",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 9.sp,
            color: Colors.grey,
            letterSpacing: 1.5,
          ),
        ),
        if (attempts > 0 && !isListening)
          Padding(
            padding: EdgeInsets.only(top: 20.h),
            child: Semantics(
              button: true,
              hint: context.tr('games.semantic_tutor_pass_hint', fallback: 'Speak now'),
              child: ScaleButton(
                onTap: onTutorPass,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Center(
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
                            context.tr('games.i_spoke_correctly', fallback: 'I spoke correctly').toUpperCase(),
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
              ),
            ),
          ).animate().fadeIn().shake(),
      ],
    );
  }
}
