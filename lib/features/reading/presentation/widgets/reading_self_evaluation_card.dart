import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class ReadingSelfEvaluationCard extends StatefulWidget {
  final String correctAnswer;
  final String? explanation;
  final Color primaryColor;
  final bool isDark;
  final Function(bool isCorrect) onEvaluated;

  const ReadingSelfEvaluationCard({
    super.key,
    required this.correctAnswer,
    this.explanation,
    required this.primaryColor,
    required this.isDark,
    required this.onEvaluated,
  });

  @override
  State<ReadingSelfEvaluationCard> createState() => _ReadingSelfEvaluationCardState();
}

class _ReadingSelfEvaluationCardState extends State<ReadingSelfEvaluationCard> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  bool _isRevealed = false;

  void _reveal() {
    _hapticService.selection();
    setState(() => _isRevealed = true);
  }

  void _evaluate(bool isCorrect) {
    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
    } else {
      _hapticService.error();
      _soundService.playWrong();
    }
    widget.onEvaluated(isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isRevealed) {
      return GestureDetector(
        onTap: _reveal,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 24.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.primaryColor.withValues(alpha: 0.8),
                widget.primaryColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: widget.primaryColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(Icons.visibility_rounded, color: Colors.white, size: 32.sp),
              SizedBox(height: 12.h),
              Text(
                'TAP TO REVEAL ANSWER',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Think of the answer first!',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: widget.primaryColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(
            'THE ANSWER IS',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: widget.primaryColor,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            widget.correctAnswer,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: widget.isDark ? Colors.white : Colors.black87,
            ),
          ),
          if (widget.explanation != null && widget.explanation!.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: widget.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                widget.explanation!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: widget.isDark ? Colors.white70 : Colors.black54,
                  height: 1.5,
                ),
              ),
            ),
          ],
          SizedBox(height: 24.h),
          Divider(color: widget.primaryColor.withValues(alpha: 0.2)),
          SizedBox(height: 16.h),
          Text(
            'DID YOU GET IT RIGHT?',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: widget.isDark ? Colors.white54 : Colors.black54,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildEvalButton(
                icon: Icons.close_rounded,
                label: 'MISSED IT',
                color: Colors.redAccent,
                onTap: () => _evaluate(false),
              ),
              _buildEvalButton(
                icon: Icons.check_rounded,
                label: 'NAILED IT',
                color: Colors.green,
                onTap: () => _evaluate(true),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildEvalButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120.w,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28.sp),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
