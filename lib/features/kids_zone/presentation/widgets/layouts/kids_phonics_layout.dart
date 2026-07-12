import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';


/// Music Studio Theme for Phonics Game
/// Space Complexity: O(1)
/// Time Complexity: O(N) where N is the number of options (max 4)
class KidsPhonicsLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsPhonicsLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'phonics',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            SizedBox(height: 120.h),
            // The Studio Monitor
            Expanded(
              flex: 5,
              child: Center(
                child: _buildStudioMonitor(quest),
              ),
            ),
            // Vinyl Records
            Flexible(
              flex: 5,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Studio Desk
                  Container(
                    height: 30.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155), // Slate desk
                      borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
                      border: Border(top: BorderSide(color: const Color(0xFF475569), width: 4.h)),
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
                            child: _buildVinylRecordOption(
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

  Widget _buildStudioMonitor(dynamic quest) {
    return Container(
      width: 280.w,
      height: 200.h,
      decoration: BoxDecoration(
        color: const Color(0xFF09090B), // Deep black screen
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF52525B), width: 12.r), // Silver monitor frame
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Simulated Soundwave Equalizer Background
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(15, (index) {
              return _buildEqBar(index);
            }),
          ),
          
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (quest.emoji != null)
                  Text(
                    quest.emoji!,
                    style: TextStyle(fontSize: 48.sp),
                  ),
                Text(
                  quest.question ?? "?",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 48.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: Color(0xFF22C55E), blurRadius: 15), // Neon green glow
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                if (quest.funFact != null) ...[
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Text(
                      quest.funFact!,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF86EFAC), // Light neon green text
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEqBar(int index) {
    final heightMap = [20.0, 50.0, 30.0, 80.0, 40.0, 60.0, 100.0, 70.0, 40.0, 90.0, 50.0, 30.0, 60.0, 20.0, 40.0];
    final baseHeight = heightMap[index % heightMap.length];
    
    return Container(
      width: 8.w,
      height: baseHeight.h,
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.3), // Faint green EQ bars
        borderRadius: BorderRadius.circular(4.r),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
     .scaleY(begin: 0.5, end: 1.5, duration: (300 + (index * 50)).ms);
  }

  Widget _buildVinylRecordOption(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
    int index,
  ) {
    final colors = [
      const Color(0xFFEF4444),
      const Color(0xFF3B82F6),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
    ];
    final labelColor = colors[index % colors.length];

    return ScaleButton(
      onTap: () {
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Vinyl Record (Black disc)
          Container(
            height: 90.r,
            width: 90.r,
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF3F3F46), width: 1),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.3), offset: const Offset(0, 4)),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Grooves
                Container(width: 70.r, height: 70.r, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF27272A)))),
                Container(width: 50.r, height: 50.r, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF27272A)))),
                
                // Center Label
                Container(
                  width: 35.r,
                  height: 35.r,
                  decoration: BoxDecoration(
                    color: labelColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 5.r,
                      height: 5.r,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), // Hole
                    ),
                  ),
                ),
              ],
            ),
          ).animate(onPlay: (c) => c.repeat())
           .rotate(duration: 5.seconds, curve: Curves.linear), // Spin record slowly
           
          // The overlay with text (does not spin)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4.r),
              border: Border.all(color: labelColor, width: 2),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
