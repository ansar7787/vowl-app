import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';

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
              child: Center(
                child: _buildScoreboard(quest.question ?? "?", quest.emoji),
              ),
            ),
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
                      border: Border(top: BorderSide(color: Colors.white, width: 4.h)), // Pitch line
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 10.h, left: 16.w, right: 16.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(quest.options?.length ?? 0, (index) {
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
          ],
        );
      },
    );
  }

  Widget _buildScoreboard(String text, String? emoji) {
    return Container(
      width: 260.w,
      height: 140.h,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Black board
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFF334155), width: 8.r), // Grey steel frame
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null)
              Text(
                emoji,
                style: TextStyle(fontSize: 48.sp),
              ),
            Text(
              text,
              style: TextStyle(
                fontFamily: 'CourierPrime', // Use a digital/monospace looking font if possible
                fontSize: 48.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFFBBF24), // Glowing yellow
                shadows: const [
                  Shadow(color: Color(0xFFF59E0B), blurRadius: 10),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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

    return ScaleButton(
      onTap: () {
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      child: Container(
        height: 80.r,
        decoration: BoxDecoration(
          color: ballColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black.withValues(alpha: 0.2), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(0, 6),
              blurRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true))
       .moveY(begin: 0, end: -10.h, duration: (400 + index * 100).ms, curve: Curves.easeOutQuad),
    );
  }
}
