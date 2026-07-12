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
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspective
            ..rotateY(value),
          alignment: Alignment.center,
          child:
              Container(
                    width: isCompact ? 280.w : 320.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        isCompact ? 20.r : 32.r,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isFront ? primaryColor : backColor)
                              .withValues(alpha: 0.2),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: GlassTile(
                      padding: EdgeInsets.all(isCompact ? 16.r : 32.r),
                      borderRadius: BorderRadius.circular(
                        isCompact ? 20.r : 32.r,
                      ),
                      color: (isFront ? primaryColor : backColor).withValues(
                        alpha: 0.1,
                      ),
                      child: Transform(
                        transform: Matrix4.identity()
                          ..rotateY(isFront ? 0 : 3.14),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: (isFront ? primaryColor : backColor)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                isFront ? "DIRECT SPEECH" : "REPORTED SPEECH",
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: isCompact ? 8.sp : 10.sp,
                                  fontWeight: FontWeight.w900,
                                  color: isFront ? primaryColor : backColor,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            SizedBox(height: isCompact ? 12.h : 24.h),
                            Text(
                              isFront ? directText : indirectText,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: isCompact ? 16.sp : 22.sp,
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                height: 1.4,
                              ),
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
