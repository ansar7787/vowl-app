import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';

/// Busy City Intersection Theme for Transport Game
/// Space Complexity: O(1)
/// Time Complexity: O(N) where N is the number of options (max 4)
class KidsTransportLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsTransportLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'transport',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            SizedBox(height: 120.h),
            // The Traffic Light / Road Sign
            Expanded(flex: 5, child: Center(child: _buildRoadSign(quest))),
            // The License Plates (Options)
            Flexible(
              flex: 5,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Road Asphalt Background
                  Container(
                    height: 40.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155), // Dark asphalt
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24.r),
                      ),
                    ),
                    child: Center(
                      // Yellow dashed line
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(10, (index) {
                          return Container(
                            width: 20.w,
                            height: 4.h,
                            color: const Color(0xFFFACC15),
                          );
                        }),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: 20.h,
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
                            child: _buildLicensePlateOption(
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

  Widget _buildRoadSign(dynamic quest) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The green highway sign
        Container(
          width: 280.w,
          height: 180.h,
          decoration: BoxDecoration(
            color: const Color(0xFF166534), // Highway Green
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.white, width: 4.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (quest.emoji != null)
                  Text(quest.emoji!, style: TextStyle(fontSize: 48.sp)),
                Text(
                  quest.question ?? "?",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 42.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
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
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF86EFAC), // Light green
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
        ),
        // The metal pole holding it
        Container(
          width: 16.w,
          height: 40.h,
          decoration: BoxDecoration(
            color: const Color(0xFF94A3B8), // Metal grey
            border: Border.all(color: const Color(0xFF475569), width: 2),
          ),
        ),
      ],
    );
  }

  Widget _buildLicensePlateOption(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
    int index,
  ) {
    final colors = [
      const Color(0xFFFDE047), // Yellow plate (NY style)
      Colors.white, // White plate (CA style)
      const Color(0xFF93C5FD), // Blue plate
      const Color(0xFF86EFAC), // Green plate
    ];
    final plateColor = colors[index % colors.length];

    return ScaleButton(
      onTap: () {
        di.sl<KidsTTSService>().speak(text);
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      child: Container(
        height: 60.h,
        decoration: BoxDecoration(
          color: plateColor,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: const Color(0xFF475569), width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Screw holes
            Positioned(top: 4.h, left: 6.w, child: _buildScrew()),
            Positioned(top: 4.h, right: 6.w, child: _buildScrew()),
            Positioned(bottom: 4.h, left: 6.w, child: _buildScrew()),
            Positioned(bottom: 4.h, right: 6.w, child: _buildScrew()),

            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  text.toUpperCase(),
                  style: TextStyle(
                    fontFamily:
                        'Outfit', // A rigid font looks more like a license plate
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrew() {
    return Container(
      width: 6.r,
      height: 6.r,
      decoration: const BoxDecoration(
        color: Color(0xFF475569),
        shape: BoxShape.circle,
      ),
    );
  }
}
