import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';

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
            Expanded(flex: 6, child: Center(child: _buildTownHallBoard(quest))),
            // The Professional ID Badges (Options)
            Flexible(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16.w,
                  runSpacing: 16.h,
                  children: List.generate(quest.options?.length ?? 0, (index) {
                    final option = quest.options![index];
                    return _buildIdBadge(
                      context,
                      state,
                      option,
                      quest.correctAnswer == option,
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

  Widget _buildTownHallBoard(dynamic quest) {
    return Container(
      width: 320.w,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF), // Indigo 50
        borderRadius: BorderRadius.circular(20.r), // Blocky, building shape
        border: Border.all(color: const Color(0xFF818CF8), width: 6),
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
          Text(
            quest.question ?? "?",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 40.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF312E81), // Indigo 900
            ),
            textAlign: TextAlign.center,
          ),
          if (quest.phonetic != null) ...[
            SizedBox(height: 4.h),
            Text(
              quest.phonetic!,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6366F1), // Indigo 500
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (quest.funFact != null) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: const Color(0xFFC7D2FE), width: 2),
              ),
              child: Text(
                "🏢 ${quest.funFact!}",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4338CA), // Indigo 700
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          if (quest.wordExample != null) ...[
            SizedBox(height: 12.h),
            Text(
              '"${quest.wordExample!}"',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.sp,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF3730A3), // Indigo 800
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIdBadge(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
  ) {
    return ScaleButton(
      onTap: () {
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      child: Container(
        width: 140.w,
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFF4F46E5), width: 3), // Indigo 600
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
      ),
    );
  }
}
