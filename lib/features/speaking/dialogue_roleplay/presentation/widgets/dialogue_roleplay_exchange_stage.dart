import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/features/speaking/dialogue_roleplay/presentation/widgets/synaptic_link_painter.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class DialogueRoleplayExchangeStage extends StatelessWidget {
  final SpeakingQuest quest;
  final Color primaryColor;
  final bool isDark;
  final double timeVal;
  final bool isAnswered;
  final bool isCorrect;

  const DialogueRoleplayExchangeStage({
    super.key,
    required this.quest,
    required this.primaryColor,
    required this.isDark,
    required this.timeVal,
    required this.isAnswered,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = isAnswered && isCorrect;

    return Column(
      children: [
        // AI Partner Speech Card
        _buildBubbleCard(
          title: "ROLEPLAY PARTNER",
          content: quest.partnerDialogue ?? "Dialogue statement.",
          avatarIcon: Icons.support_agent_rounded,
          color: primaryColor,
          isUser: false,
          isDark: isDark,
        ),

        // Curving dynamic particle wire connection
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: SizedBox(
            height: 60.h,
            width: double.infinity,
            child: CustomPaint(
              painter: SynapticLinkPainter(
                time: timeVal,
                isConnected: isCompleted,
                themeColor: primaryColor,
              ),
            ),
          ),
        ),

        // User Spoken Target Card
        _buildBubbleCard(
          title: "YOUR RESPONSE OBLIGATION",
          content: quest.sampleAnswer ?? "Expected response.",
          avatarIcon: Icons.face_rounded,
          color: Colors.greenAccent,
          isUser: true,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildBubbleCard({
    required String title,
    required String content,
    required IconData avatarIcon,
    required Color color,
    required bool isUser,
    required bool isDark,
  }) {
    final soundService = di.sl<SoundService>();
    final bool highlight = isUser && isAnswered && isCorrect;
    final Color borderCol = highlight
        ? Colors.greenAccent
        : (isUser ? color.withValues(alpha: 0.4) : color.withValues(alpha: 0.6));

    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131326) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: borderCol, width: highlight ? 2 : 1),
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: Colors.greenAccent.withValues(alpha: 0.25),
                  blurRadius: 15.r,
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8.r,
                )
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor: highlight ? Colors.greenAccent.withValues(alpha: 0.1) : color.withValues(alpha: 0.1),
            child: Icon(avatarIcon, color: highlight ? Colors.greenAccent : color, size: 20.r),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.shareTechMono(
                        fontSize: 9.sp,
                        color: highlight ? Colors.greenAccent : color,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    if (!isUser)
                      ScaleButton(
                        onTap: () => soundService.playTts(content),
                        child: Icon(Icons.volume_up_rounded, color: color, size: 16.r),
                      ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  content,
                  style: GoogleFonts.fredoka(
                    fontSize: 14.sp,
                    color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
