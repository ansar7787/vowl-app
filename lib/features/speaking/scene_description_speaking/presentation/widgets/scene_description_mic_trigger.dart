import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class SceneDescriptionMicTrigger extends StatelessWidget {
  final bool isListening;
  final int activeHotspot;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;

  const SceneDescriptionMicTrigger({
    super.key,
    required this.isListening,
    required this.activeHotspot,
    required this.primaryColor,
    required this.isDark,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    final bool canRecord = activeHotspot != -1;

    return GestureDetector(
      onLongPressStart: (_) => canRecord ? onLongPressStart() : null,
      onLongPressEnd: (_) => canRecord ? onLongPressEnd() : null,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Rippling concentric audio paths
              if (isListening)
                ...List.generate(4, (i) {
                  return Container(
                    width: 76.r + (i * 24.r),
                    height: 76.r + (i * 24.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.15),
                        width: 1.5.r,
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .scale(
                    begin: const Offset(1.0, 1.0), 
                    end: const Offset(1.15, 1.15), 
                    duration: const Duration(milliseconds: 800), 
                    curve: Curves.easeOut
                  )
                  .fadeOut();
                }),

              // Boundary Ring
              Container(
                width: 96.r,
                height: 96.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  border: Border.all(
                    color: canRecord
                        ? (isListening
                            ? Colors.redAccent.withValues(alpha: 0.35)
                            : primaryColor.withValues(alpha: 0.15))
                        : Colors.grey.withValues(alpha: 0.1),
                    width: 4.r,
                  ),
                ),
              ).animate(target: isListening ? 1 : 0).scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.18, 1.18),
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeInOut,
                  ),

              // Interactive Mic Core
              ScaleButton(
                onTap: () {},
                child: Container(
                  width: 76.r,
                  height: 76.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: canRecord
                          ? (isListening
                              ? [Colors.red[900]!, Colors.redAccent]
                              : [const Color(0xFF1F1C2C), const Color(0xFF928DAB)])
                          : [Colors.grey[800]!, Colors.grey[900]!],
                    ),
                    boxShadow: isListening
                        ? [
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.45),
                              blurRadius: 25.r,
                              spreadRadius: 2.r,
                            )
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10.r,
                            )
                          ],
                  ),
                  child: Icon(
                    isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 32.r,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            !canRecord
                ? "TAP PULSING RADAR BEACON TO UNLOCK MIC"
                : (isListening
                    ? "RELEASE MICROPHONE TO ANALYZE DESCRIPTION"
                    : "HOLD MICROPHONE TO DESCRIBE SELECTION"),
            textAlign: TextAlign.center,
            style: GoogleFonts.shareTechMono(
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
