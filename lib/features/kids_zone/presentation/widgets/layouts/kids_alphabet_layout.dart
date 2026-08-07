import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
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
            Expanded(flex: 5, child: Center(child: _buildChalkboard(quest))),
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
      width: 320.w,
      height: 220.h,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4332), // Classic chalkboard green
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFF8B5A2B),
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
            if (quest.wordEmoji != null)
              Text(quest.wordEmoji!, style: TextStyle(fontSize: 40.sp))
            else if (quest.emoji != null)
              Text(quest.emoji!, style: TextStyle(fontSize: 40.sp)),
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (quest.capitalLetter != null) ...[
                    Flexible(
                      child: AutoSizeText(
                        quest.capitalLetter!,
                        style: TextStyle(
                          fontFamily: 'ComicSans',
                          fontSize: 64.sp,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFFDE68A), // Chalk yellow
                        ),
                        maxLines: 1,
                        minFontSize: 24,
                      ),
                    ),
                    SizedBox(width: 8.w),
                  ],
                  Flexible(
                    child: AutoSizeText(
                      quest.question ?? "?",
                      style: TextStyle(
                        fontFamily: 'ComicSans',
                        fontSize: 72.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.9), // Chalk white
                        letterSpacing: 2,
                      ),
                      maxLines: 1,
                      minFontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            if (quest.wordExample != null) ...[
              SizedBox(height: 4.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: AutoSizeText(
                  "${quest.wordExample!} ${quest.phonetic != null ? '(/${quest.phonetic}/)' : ''}",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFA7F3D0), // Chalk mint
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  minFontSize: 10,
                ),
              ),
            ],
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
        di.sl<KidsTTSService>().speak(text);
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      child: Container(
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
      ),
    );
  }
}
