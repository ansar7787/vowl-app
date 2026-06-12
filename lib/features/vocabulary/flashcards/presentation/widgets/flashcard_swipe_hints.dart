import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FlashcardSwipeHints extends StatelessWidget {
  const FlashcardSwipeHints({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 28.w.clamp(16.0, 28.0),
      runSpacing: 12.h.clamp(8.0, 12.0),
      children: const [
        _HintIcon(
          icon: Icons.refresh_rounded,
          color: Colors.redAccent,
          label: 'REVIEW',
        ),
        _HintIcon(
          icon: Icons.check_circle_rounded,
          color: Colors.greenAccent,
          label: 'MASTER',
        ),
      ],
    );
  }
}

// ─── Private sub-widget ───────────────────────────────────────────────────────

class _HintIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _HintIcon({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: 88.w.clamp(72.0, 110.0)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 24.r),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 1,
            ),
          ),
        ],
      ).animate().fadeIn(delay: 400.ms).scale(),
    );
  }
}
