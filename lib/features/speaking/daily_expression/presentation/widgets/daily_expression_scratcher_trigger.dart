import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class DailyExpressionScratcherTrigger extends StatelessWidget {
  final bool isListening;
  final double timeVal;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;
  final int attempts;
  final bool isAnswered;
  

  const DailyExpressionScratcherTrigger({
    super.key,
    required this.isListening,
    required this.timeVal,
    required this.primaryColor,
    required this.isDark,
    required this.onLongPressStart,
    required this.onLongPressEnd,
    required this.attempts,
    required this.isAnswered,
    
  });

  @override
  Widget build(BuildContext context) {
    if (isAnswered) return const SizedBox.shrink();

    return GestureDetector(
      onLongPressStart: (_) => onLongPressStart(),
      onLongPressEnd: (_) => onLongPressEnd(),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Beautiful glowing golden star particles emitting while recording is active
              if (isListening)
                ...List.generate(8, (i) {
                  final double angle = (i * math.pi * 2) / 8 + (timeVal * 15.0);
                  final double dist =
                      60.w + (math.sin(timeVal * 20.0 + i) * 15.w);
                  return Positioned(
                    child:
                        Icon(
                              Icons.star_rounded,
                              color: primaryColor.withValues(alpha: 0.8),
                              size: (12.r + i * 2.r).clamp(10, 24).toDouble(),
                            )
                            .animate(onPlay: (c) => c.repeat())
                            .move(
                              begin: Offset.zero,
                              end: Offset(
                                math.cos(angle) * dist,
                                -50.h + math.sin(angle) * dist * 0.4,
                              ),
                              duration: Duration(milliseconds: 400 + i * 80),
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
                            ? primaryColor.withValues(alpha: 0.3)
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
                          ? [primaryColor.withValues(alpha: 0.8), primaryColor]
                          : [const Color(0xFF2C3E50), const Color(0xFF000000)],
                    ),
                    boxShadow: isListening
                        ? [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.45),
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
                        ? Icons.auto_fix_normal_rounded
                        : Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 32.r,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            isListening ? "RELEASE MIC TO SUBMIT" : "HOLD MIC TO SPEAK",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 9.sp,
              color: Colors.grey,
              letterSpacing: 1.5,
            ),
          ),
          
        ],
      ),
    );
  }
}
