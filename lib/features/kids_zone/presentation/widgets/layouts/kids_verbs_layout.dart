import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_fitted_text.dart';

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
            KidsFittedText(
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
              maxLines: 2,
              textAlign: TextAlign.center,
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
        if (!isCorrect) {
          di.sl<KidsTTSService>().speak(text);
        }
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return InkWell(
          onTap: state.lastAnswerCorrect != null
              ? null
              : () {
                  if (quest.instruction != null) {
                    di.sl<KidsTTSService>().speak(quest.instruction!);
                  }
                },
          child: Container(
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
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (quest.emoji != null &&
                          (quest.question == "?" || quest.question == null))
                        state.lastAnswerCorrect == true
                            ? Text(
                                quest.emoji!,
                                style: TextStyle(fontSize: 80.sp),
                              )
                            : ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                  const Color(
                                    0xFFFBBF24,
                                  ).withValues(alpha: 0.15),
                                  BlendMode.srcIn,
                                ),
                                child: Text(
                                  quest.emoji!,
                                  style: TextStyle(fontSize: 80.sp),
                                ),
                              ),
                      if (quest.emoji == null ||
                          (quest.question != "?" && quest.question != null))
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: KidsFittedText(
                            quest.question ?? "?",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize:
                                  (quest.question == "?" ||
                                      quest.question == null)
                                  ? 70.sp
                                  : 24.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFBBF24).withValues(
                                alpha:
                                    (quest.question == "?" ||
                                        quest.question == null)
                                    ? 0.7
                                    : 1.0,
                              ),
                              shadows: const [
                                Shadow(
                                  color: Color(0xFFF59E0B),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 4,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
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
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
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
