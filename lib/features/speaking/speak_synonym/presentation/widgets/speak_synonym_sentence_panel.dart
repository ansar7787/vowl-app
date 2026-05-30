import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class SpeakSynonymSentencePanel extends StatelessWidget {
  final SpeakingQuest quest;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onPlayTts;

  const SpeakSynonymSentencePanel({
    super.key,
    required this.quest,
    required this.primaryColor,
    required this.isDark,
    required this.onPlayTts,
  });

  @override
  Widget build(BuildContext context) {
    final String fullText = quest.textToSpeak ?? "";
    final List<String> segments = fullText.split('*');

    return GlassTile(
      padding: EdgeInsets.all(22.r),
      borderRadius: BorderRadius.circular(26.r),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "SUBSTITUTE HIGHLIGHTED SEED",
                style: GoogleFonts.shareTechMono(
                  fontSize: 10.sp,
                  color: Colors.grey.shade400,
                  letterSpacing: 1.0,
                ),
              ),
              ScaleButton(
                onTap: onPlayTts,
                child: Icon(Icons.volume_up_rounded, color: primaryColor, size: 18.r),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.fredoka(
                fontSize: 18.sp,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.4,
              ),
              children: segments.asMap().entries.map((e) {
                final bool isTarget = e.key % 2 != 0;
                if (isTarget) {
                  return WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.6), width: 1.5.w),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.1),
                            blurRadius: 8,
                          )
                        ],
                      ),
                      child: Text(
                        e.value,
                        style: GoogleFonts.fredoka(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  );
                } else {
                  return TextSpan(text: e.value);
                }
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
