import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Sports Stadium Theme for Verbs (Action Words) Game
/// Space Complexity: O(1)
/// Time Complexity: O(N) where N is the number of options (max 4)
class KidsVerbsLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsVerbsLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'verbs',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            SizedBox(height: 120.h),
            // The Stadium Scoreboard
            Expanded(
              flex: 5,
              child: Center(child: _buildScoreboard(context, state, quest)),
            ),
            SizedBox(height: 24.h),
            Text(
              context.tr(
                'games.kids_verbs_drag',
                fallback: 'Drag the sports ball to the scoreboard! ✨',
              ),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.black.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 16.h),
            // The Sports Balls (Bouncing slightly)
            Flexible(
              flex: 5,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Green Grass Field
                  Container(
                    height: 40.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E), // Grass green
                      border: Border(
                        top: BorderSide(color: Colors.white, width: 4.h),
                      ), // Pitch line
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: 10.h,
                      left: 16.w,
                      right: 16.w,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(quest.options?.length ?? 0, (
                        index,
                      ) {
                        final option = quest.options![index];
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            child: _buildSportsBallOption(
                              context,
                              state,
                              option,
                              quest.correctAnswer == option,
                              index,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            // Small AAA Design Card for Fun Facts
            if (quest.funFact != null)
              Padding(
                padding: EdgeInsets.only(top: 16.h, bottom: 24.h, left: 32.w, right: 32.w),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.3),
                      width: 2.w,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_circle_rounded,
                        color: primaryColor,
                        size: 28.r,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: AutoSizeText(
                          quest.funFact!,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.9)
                                : Colors.black.withValues(alpha: 0.8),
                          ),
                          maxLines: 2,
                          minFontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildScoreboard(
    BuildContext context,
    KidsLoaded state,
    dynamic quest,
  ) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        final text = details.data;
        final isCorrect = (text == quest.correctAnswer);
        di.sl<KidsTTSService>().speak(text);
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Container(
          width: 280.w,
          height: 180.h,
          decoration: BoxDecoration(
            color: isHovering
                ? const Color(0xFF1E293B)
                : const Color(0xFF0F172A), // Black board
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isHovering
                  ? const Color(0xFF64748B)
                  : const Color(0xFF334155),
              width: isHovering ? 10.r : 8.r,
            ), // Grey steel frame
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isHovering ? 0.5 : 0.3),
                blurRadius: isHovering ? 25 : 15,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: AutoSizeText(
                    quest.instruction ??
                        "?", // Show instruction, hide emoji/question to prevent cheat
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFFBBF24), // Glowing yellow
                      shadows: const [
                        Shadow(color: Color(0xFFF59E0B), blurRadius: 10),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    minFontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSportsBallOption(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
    int index,
  ) {
    // 0 = Soccer, 1 = Basketball, 2 = Tennis, 3 = Baseball
    final ballTypes = ['soccer', 'basketball', 'tennis', 'baseball'];
    final ballType = ballTypes[index % ballTypes.length];

    Color ballColor;
    Color textColor;

    switch (ballType) {
      case 'soccer':
        ballColor = Colors.white;
        textColor = Colors.black;
        break;
      case 'basketball':
        ballColor = const Color(0xFFEA580C);
        textColor = Colors.white;
        break;
      case 'tennis':
        ballColor = const Color(0xFFA3E635);
        textColor = const Color(0xFF064E3B);
        break;
      case 'baseball':
      default:
        ballColor = Colors.white;
        textColor = const Color(0xFFB91C1C);
        break;
    }

    final ballWidget = SizedBox(
      width: 80.w,
      child: Container(
        height: 80.r,
      decoration: BoxDecoration(
        color: ballColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, 6),
            blurRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: AutoSizeText(
            text,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            minFontSize: 8,
          ),
        ),
      ),
    ),
    );

    return Draggable<String>(
      data: text,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.05,
          child: Opacity(opacity: 0.9, child: ballWidget),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: ballWidget),
      child: ballWidget,
    );
  }
}
