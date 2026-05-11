import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_image.dart';

class DayNightGameScreen extends StatelessWidget {
  final int level;
  const DayNightGameScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: "Day & Night",
      gameType: "day_night",
      level: level,
      primaryColor: const Color(0xFF1E293B),
      backgroundColors: const [], // Using Unified Background
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            SizedBox(height: 30.h),
            Text(
              quest.instruction,
              style: GoogleFonts.poppins(
                fontSize: 26.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40.h),
            _buildSkyView(quest.imageUrl),
            SizedBox(height: 40.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Row(
                children: List.generate(quest.options?.length ?? 0, (index) {
                  final option = quest.options![index];
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: _buildCelestialCard(
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
          ],
        );
      },
    );
  }

  Widget _buildSkyView(String? imageUrl) {
    return Container(
      width: 260.w,
      height: 200.h,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(100.r), // Capsule shape
        border: Border.all(color: Colors.white24, width: 4),
      ),
      padding: EdgeInsets.all(20.r),
      child: KidsImage(
        imageUrl: imageUrl,
        fallbackIcon: Icons.nights_stay_rounded,
        iconColor: Colors.amber[200],
      ),
    );
  }

  Widget _buildCelestialCard(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
  ) {
    final isDay =
        text.toLowerCase().contains("day") ||
        text.toLowerCase().contains("sun");
    return ScaleButton(
      onTap: () {
        context.read<KidsBloc>().add(SubmitKidsAnswer(
              isCorrect,
            ));
      },
      child: Container(
        height: 120.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDay
                ? [const Color(0xFF38BDF8), const Color(0xFF0EA5E9)]
                : [const Color(0xFF334155), const Color(0xFF0F172A)],
          ),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: (isDay ? Colors.blue : Colors.black).withValues(
                alpha: 0.2,
              ),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDay ? Icons.wb_sunny_rounded : Icons.mode_night_rounded,
                color: Colors.white,
                size: 32.sp,
              ),
              SizedBox(height: 8.h),
              Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

