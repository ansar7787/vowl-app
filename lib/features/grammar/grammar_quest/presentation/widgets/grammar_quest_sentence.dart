import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class GrammarQuestSentence extends StatelessWidget {
  final String text;
  final bool isDark;
  final bool isCompact;

  const GrammarQuestSentence({
    super.key,
    required this.text,
    required this.isDark,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      padding: EdgeInsets.all(isCompact ? 14.r : 24.r),
      borderRadius: BorderRadius.circular(isCompact ? 18.r : 28.r),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: isCompact ? 15.sp : 20.sp,
          color: isDark ? Colors.white : Colors.black87,
          height: 1.4,
        ),
      ),
    );
  }
}
