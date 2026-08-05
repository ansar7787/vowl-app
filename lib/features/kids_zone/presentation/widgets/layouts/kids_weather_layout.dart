import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';

/// Sky Theme for Weather Game
class KidsWeatherLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsWeatherLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'weather',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            SizedBox(height: 60.h),
            // The Sky Billboard
            Expanded(flex: 6, child: Center(child: _buildSkyBillboard(quest))),
            // The Weather Clouds (Options)
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
                    return _buildWeatherCloud(
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

  Widget _buildSkyBillboard(dynamic quest) {
    return Container(
      width: 320.w,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF0F9FF), // Sky 50
            Color(0xFFE0F2FE), // Sky 100
          ],
        ),
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
              color: const Color(0xFF0369A1), // Dark sky blue
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
                color: const Color(0xFF7DD3FC),
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
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text(
                "💡 ${quest.funFact!}",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0284C7),
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
                color: const Color(0xFF0C4A6E),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeatherCloud(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
  ) {
    return ScaleButton(
      onTap: () {
        di.sl<KidsTTSService>().speak(text);
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      child: Container(
        width: 140.w,
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFF0F9FF), // Very soft blue at bottom of cloud
            ],
          ),
          borderRadius: BorderRadius.circular(40.r), // Cloud-like pill shape
          border: Border.all(color: const Color(0xFFE0F2FE), width: 3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7DD3FC).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0369A1),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
