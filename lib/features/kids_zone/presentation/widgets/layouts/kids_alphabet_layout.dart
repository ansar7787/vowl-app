import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';

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
            Expanded(
              flex: 5,
              child: Center(
                child: _buildChalkboard(quest),
              ),
            ),
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

  Widget _buildChalkboard(dynamic quest) {
    return Container(
      width: 280.w,
      height: 200.h,
      decoration: BoxDecoration(
        color: const Color(0xFF1B4332), // Classic chalkboard green
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF8B5A2B), width: 12.r), // Wooden frame
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
            if (quest.wordEmoji != null)
              Text(
                quest.wordEmoji!,
                style: TextStyle(fontSize: 40.sp),
              )
            else if (quest.emoji != null)
              Text(
                quest.emoji!,
                style: TextStyle(fontSize: 40.sp),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (quest.capitalLetter != null) ...[
                  Text(
                    quest.capitalLetter!,
                    style: TextStyle(
                      fontFamily: 'ComicSans', // Or a chalk-like font if available
                      fontSize: 64.sp,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFFDE68A), // Chalk yellow
                    ),
                  ),
                  SizedBox(width: 8.w),
                ],
                Text(
                  quest.question ?? "?",
                  style: TextStyle(
                    fontFamily: 'ComicSans',
                    fontSize: 72.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withValues(alpha: 0.9), // Chalk white
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            if (quest.wordExample != null) ...[
              SizedBox(height: 4.h),
              Text(
                "${quest.wordExample!} ${quest.phonetic != null ? '(/${quest.phonetic}/)' : ''}",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFA7F3D0), // Chalk mint
                ),
              ),
            ],
          ],
        ),
      ),
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

    return ScaleButton(
      onTap: () {
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      child: Container(
        height: 100.h,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: shadowColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 32.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF78350F), // Etched wood color
            ),
          ),
        ),
      ),
    );
  }
}
