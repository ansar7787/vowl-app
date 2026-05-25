import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class GrammarQuestSentence extends StatelessWidget {
  final String text;
  final bool isDark;

  const GrammarQuestSentence({
    super.key,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      padding: EdgeInsets.all(24.r),
      borderRadius: BorderRadius.circular(28.r),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.fredoka(
          fontSize: 20.sp,
          color: isDark ? Colors.white : Colors.black87,
          height: 1.4,
        ),
      ),
    );
  }
}
