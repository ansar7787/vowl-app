import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';

class KidsAlphabetLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsAlphabetLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'alphabet',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            SizedBox(height: 120.h), // Mascot space
            // The Chalkboard for the Question
            Expanded(flex: 5, child: Center(child: _buildChalkboard(context, state, quest))),
            // The Wooden Blocks for Options
            Flexible(
              flex: 5,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(quest.options?.length ?? 0, (index) {
                    final option = quest.options![index];
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: _buildWoodenBlock(
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
          ],
        );
      },
    );
  }

  Widget _buildChalkboard(BuildContext context, KidsLoaded state, dynamic quest) {
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
          height: 220.h,
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: isHovering ? const Color(0xFF2D6A4F) : const Color(0xFF1B4332), // Highlight green when hovering
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isHovering ? const Color(0xFFB07D45) : const Color(0xFF8B5A2B),
              width: 12.r,
            ), // Wooden frame
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 15,
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
                quest.instruction ?? "?",
                style: TextStyle(
                  fontFamily: 'ComicSans',
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFFDE68A), // Chalk yellow
                ),
                textAlign: TextAlign.center,
                maxLines: 4,
                minFontSize: 14,
              ),
            ),
            if (quest.funFact != null) ...[
              SizedBox(height: 8.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: AutoSizeText(
                  quest.funFact!,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF93C5FD), // Light chalk blue
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  minFontSize: 8,
                ),
              ),
            ],
          ],
        ),
      ),
        );
      },
    );
  }

  Widget _buildWoodenBlock(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
  ) {
    final baseColor = const Color(0xFFFDE68A); // Light wood
    final shadowColor = const Color(0xFFD97706); // Dark wood

    final blockWidget = Container(
        height: 100.h,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: shadowColor, width: 2),
          boxShadow: [BoxShadow(color: shadowColor, offset: Offset(0, 8.h))],
        ),
        child: Center(
          child: AutoSizeText(
            text,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 32.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF78350F), // Etched wood color
            ),
            maxLines: 1,
            minFontSize: 12,
            textAlign: TextAlign.center,
          ),
        ),
      );

    return Draggable<String>(
      data: text,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.05,
          child: Opacity(
            opacity: 0.9,
            child: blockWidget,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: blockWidget,
      ),
      child: blockWidget,
    );
  }
}
