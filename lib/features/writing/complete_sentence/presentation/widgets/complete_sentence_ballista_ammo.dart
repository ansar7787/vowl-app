import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class CompleteSentenceBallistaAmmo extends StatelessWidget {
  final List<String> options;
  final String correct;
  final Color color;
  final bool isDark;
  final Function(Offset) onBridgeStart;
  final Function(Offset) onBridgeUpdate;
  final Function(String, String) onFire;

  const CompleteSentenceBallistaAmmo({
    super.key,
    required this.options,
    required this.correct,
    required this.color,
    required this.isDark,
    required this.onBridgeStart,
    required this.onBridgeUpdate,
    required this.onFire,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12.w, 
      runSpacing: 12.h,
      alignment: WrapAlignment.center,
      children: options.map((o) => GestureDetector(
        onPanStart: (details) => onBridgeStart(details.globalPosition),
        onPanUpdate: (details) => onBridgeUpdate(details.globalPosition),
        onPanEnd: (details) => onFire(o, correct),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isDark ? Colors.black87 : Colors.white,
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: isDark ? 0.35 : 0.15), blurRadius: 10)
            ],
          ),
          child: Text(
            o.toUpperCase(), 
            style: TextStyle(fontFamily: 'RobotoMono', 
              fontSize: 12.sp, 
              fontWeight: FontWeight.bold, 
              color: isDark ? Colors.white : Colors.black87
            )
          ),
        ),
      )).toList(),
    );
  }
}
