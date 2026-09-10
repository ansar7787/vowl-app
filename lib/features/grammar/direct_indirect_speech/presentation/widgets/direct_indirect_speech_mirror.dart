import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class DirectIndirectSpeechMirror extends StatelessWidget {
  final double rotation;
  final String directText;
  final String indirectText;
  final bool? isCorrect;
  final bool isDark;
  final Color primaryColor;
  final bool isCompact;

  const DirectIndirectSpeechMirror({
    super.key,
    required this.rotation,
    required this.directText,
    required this.indirectText,
    required this.isCorrect,
    required this.isDark,
    required this.primaryColor,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final backColor = (isCorrect == false)
        ? Colors.redAccent
        : Colors.greenAccent;

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: rotation),
      duration: 1000.ms,
      curve: Curves.elasticOut,
      builder: (context, double value, child) {
        final isFront = value < 1.57;
        final currentColor = isFront ? primaryColor : backColor;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspective
            ..rotateY(value),
          alignment: Alignment.center,
          child:
              Container(
                    width: isCompact ? 290.w : 330.w,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: currentColor.withValues(alpha: 0.2),
                          blurRadius: 30,
                          spreadRadius: 2,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: GlassTile(
                      padding: EdgeInsets.all(isCompact ? 20.r : 32.r),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isCompact ? 24.r : 32.r),
                        topRight: Radius.circular(isCompact ? 24.r : 32.r),
                        bottomLeft: Radius.circular(
                          isFront ? 4.r : (isCompact ? 24.r : 32.r),
                        ),
                        bottomRight: Radius.circular(
                          isFront ? (isCompact ? 24.r : 32.r) : 4.r,
                        ),
                      ),
                      color: currentColor.withValues(alpha: 0.15),
                      border: Border.all(
                        color: currentColor.withValues(alpha: 0.4),
                        width: 2,
                      ),
                      child: Transform(
                        transform: Matrix4.identity()
                          ..rotateY(isFront ? 0 : 3.14),
                        alignment: Alignment.center,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Watermark
                            Positioned(
                              right: isFront ? 0 : null,
                              left: isFront ? null : 0,
                              bottom: 0,
                              child: Icon(
                                Icons.format_quote_rounded,
                                size: 80.r,
                                color: currentColor.withValues(alpha: 0.1),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 6.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: currentColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(
                                      color: currentColor.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isFront
                                            ? Icons.record_voice_over_rounded
                                            : Icons.mark_chat_read_rounded,
                                        size: 12.r,
                                        color: currentColor,
                                      ),
                                      SizedBox(width: 6.w),
                                      Text(
                                        isFront
                                            ? "DIRECT SPEECH"
                                            : "REPORTED SPEECH",
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: isCompact ? 9.sp : 11.sp,
                                          fontWeight: FontWeight.w900,
                                          color: currentColor,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: isCompact ? 16.h : 24.h),
                                Text(
                                  isFront ? directText : indirectText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: isCompact ? 18.sp : 24.sp,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.w800,
                                    height: 1.4,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .animate(key: ValueKey(isFront))
                  .shimmer(duration: 2.seconds, color: Colors.white10),
        );
      },
    );
  }
}
