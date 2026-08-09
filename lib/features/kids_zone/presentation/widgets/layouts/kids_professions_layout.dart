import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// City Theme for Professions Game
class KidsProfessionsLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsProfessionsLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'professions',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            SizedBox(height: 60.h),
            // The Town Hall Board
            Expanded(
              flex: 6,
              child: Center(child: _buildTownHallBoard(context, state, quest)),
            ),
            SizedBox(height: 24.h),
            Text(
              context.tr(
                'games.kids_professions_drag',
                fallback: 'Drag the ID badge to the town board! ✨',
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
            // The Professional ID Badges (Options)
            Flexible(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(quest.options?.length ?? 0, (index) {
                    final option = quest.options![index];
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: _buildIdBadge(
                          context,
                          state,
                          option,
                          quest.correctAnswer == option,
                        ),
                      ),
                    );
                  }),
                ),
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

  Widget _buildTownHallBoard(
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
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 320.w,
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isHovering
                  ? [const Color(0xFFC7D2FE), const Color(0xFF818CF8)]
                  : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
            ),
            borderRadius: BorderRadius.circular(20.r), // Blocky, building shape
            border: Border.all(
              color: isHovering ? Colors.yellowAccent : const Color(0xFF818CF8),
              width: 6,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                blurRadius: 15,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (quest.emoji != null)
                Text(quest.emoji!, style: TextStyle(fontSize: 64.sp)),
              SizedBox(height: 8.h),
              Flexible(
                child: AutoSizeText(
                  quest.question ?? "?",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 40.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF312E81), // Indigo 900
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  minFontSize: 16,
                ),
              ),
              if (quest.phonetic != null) ...[
                SizedBox(height: 4.h),
                AutoSizeText(
                  quest.phonetic!,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6366F1), // Indigo 500
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ],
              if (quest.wordExample != null) ...[
                SizedBox(height: 12.h),
                Flexible(
                  child: AutoSizeText(
                    '"${quest.wordExample!}"',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF3730A3), // Indigo 800
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    minFontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildIdBadge(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
  ) {
    final badgeWidget = Container(
      width: 80.w,
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Color(0xFFEEF2FF), // Slight indigo tint at the bottom of the badge
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFF4F46E5),
          width: 3,
        ), // Indigo 600
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Badge hole punch
          Container(
            width: 20.w,
            height: 6.h,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF312E81),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    return Draggable<String>(
      data: text,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.05,
          child: Opacity(opacity: 0.9, child: badgeWidget),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: badgeWidget),
      child: badgeWidget,
    );
  }
}
