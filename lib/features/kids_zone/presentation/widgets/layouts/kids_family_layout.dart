import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';

/// Cozy Living Room Theme for Family Game
/// Space Complexity: O(1)
/// Time Complexity: O(N) where N is the number of options (max 4)
class KidsFamilyLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsFamilyLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'family',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            SizedBox(height: 120.h),
            // The Framed Painting
            Expanded(
              flex: 5,
              child: Center(
                child: _buildFramedPainting(quest.question ?? "?", quest.emoji),
              ),
            ),
            // The Polaroid Pictures on Mantle
            Flexible(
              flex: 5,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Wooden Mantlepiece
                  Container(
                    height: 24.h,
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF78350F), // Dark wood mantle
                      borderRadius: BorderRadius.vertical(top: Radius.circular(4.r)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  // Polaroids resting on mantle
                  Padding(
                    padding: EdgeInsets.only(bottom: 24.h, left: 16.w, right: 16.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(quest.options?.length ?? 0, (index) {
                        final option = quest.options![index];
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            child: _buildPolaroidOption(
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

  Widget _buildFramedPainting(String text, String? emoji) {
    return Container(
      width: 240.w,
      height: 180.h,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF08A), // Warm wallpaper yellow
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: const Color(0xFFB45309), width: 16.r), // Ornate wooden frame
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 12),
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
                fontFamily: 'Outfit',
                fontSize: 42.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF451A03),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolaroidOption(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
    int index,
  ) {
    // Slight random rotation for polaroids
    final double rotation = index % 2 == 0 ? -0.05 : 0.05;

    return ScaleButton(
      onTap: () {
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          height: 110.h,
          padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 20.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                offset: const Offset(0, 4),
                blurRadius: 6,
              ),
            ],
          ),
          child: Column(
            children: [
              // Photo area (placeholder color)
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFE2E8F0), // Blank photo grey
                  child: Center(
                    child: Icon(Icons.photo_rounded, color: const Color(0xFF94A3B8), size: 24.r),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              // Handwriting text
              Text(
                text,
                style: TextStyle(
                  fontFamily: 'ComicSans', // Or any casual font
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF334155),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
