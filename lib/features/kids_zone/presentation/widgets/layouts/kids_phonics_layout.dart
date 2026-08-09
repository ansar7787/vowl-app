import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/core/utils/locale_service.dart';

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
              child: Center(child: _buildStudioMonitor(context, state, quest)),
            ),
            SizedBox(height: 24.h),
            Text(
              context.tr(
                'games.kids_phonics_drag',
                fallback: 'Drag the vinyl record to the monitor! ✨',
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
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(8.r),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: const Color(0xFF475569),
                          width: 4.h,
                        ),
                      ),
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

  Widget _buildStudioMonitor(
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
        return Container(
          width: 280.w,
          height: 200.h,
          decoration: BoxDecoration(
            color: const Color(0xFF09090B), // Deep black screen
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isHovering
                  ? const Color(0xFF6366F1)
                  : const Color(0xFF52525B),
              width: isHovering ? 14.r : 12.r,
            ), // Silver monitor frame
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isHovering ? 0.6 : 0.4),
                blurRadius: isHovering ? 25 : 15,
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
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: AutoSizeText(
                        quest.instruction ??
                            "?", // Use instruction, hide emoji/question
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: isHovering
                                  ? const Color(0xFF818CF8)
                                  : const Color(0xFF22C55E),
                              blurRadius: 15,
                            ), // Neon glow
                          ],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        minFontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEqBar(int index) {
    final heightMap = [
      20.0,
      50.0,
      30.0,
      80.0,
      40.0,
      60.0,
      100.0,
      70.0,
      40.0,
      90.0,
      50.0,
      30.0,
      60.0,
      20.0,
      40.0,
    ];
    final baseHeight = heightMap[index % heightMap.length];

    return Container(
      width: 8.w,
      height: baseHeight.h,
      decoration: BoxDecoration(
        color: const Color(
          0xFF22C55E,
        ).withValues(alpha: 0.3), // Faint green EQ bars
        borderRadius: BorderRadius.circular(4.r),
      ),
      // Remove flutter_animate usage for EQ bars to keep it simpler without the package,
      // or we can use a TweenAnimationBuilder. For simplicity, we just leave it static or use Tween.
      // Since flutter_animate was imported previously but we replaced it, let's just make it static.
    );
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

    final recordWidget = Stack(
      alignment: Alignment.center,
      children: [
        // The Vinyl Record (Black disc)
        Container(
          height: 90.r,
          width: 80.w, // Added width constraint for uniform responsive behavior
          decoration: BoxDecoration(
            color: const Color(0xFF18181B),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF3F3F46), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Grooves
              Container(
                width: 70.r,
                height: 70.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF27272A)),
                ),
              ),
              Container(
                width: 50.r,
                height: 50.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF27272A)),
                ),
              ),

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
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ), // Hole
                  ),
                ),
              ),
            ],
          ),
        ),
        // The overlay with text (does not spin)
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4.r),
            border: Border.all(color: labelColor, width: 2),
          ),
          child: AutoSizeText(
            text,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
            maxLines: 1,
            minFontSize: 8,
          ),
        ),
      ],
    );

    return Draggable<String>(
      data: text,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.05,
          child: Opacity(opacity: 0.9, child: recordWidget),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: recordWidget),
      child: recordWidget,
    );
  }
}
