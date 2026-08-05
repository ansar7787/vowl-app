import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';

/// Art Studio Theme for Colors Game
/// Space Complexity: O(1)
/// Time Complexity: O(N) where N is the number of options (max 4)
class KidsColorsLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsColorsLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'colors',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            SizedBox(height: 120.h),
            // The Artist Easel
            Expanded(flex: 5, child: Center(child: _buildEasel(quest))),
            // The Squeezed Paint Tubes
            Flexible(
              flex: 5,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(quest.options?.length ?? 0, (index) {
                    final option = quest.options![index];
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                        child: _buildPaintTube(
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

  Widget _buildEasel(dynamic quest) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Wooden back legs of the easel
        Positioned(
          top: -20.h,
          child: Container(
            width: 140.w,
            height: 250.h,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: const Color(0xFF92400E), width: 12.w),
                right: BorderSide(color: const Color(0xFF92400E), width: 12.w),
              ),
            ),
          ),
        ),
        // The Canvas
        Container(
          width: 280.w,
          height: 200.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4.r),
            border: Border.all(color: const Color(0xFFD4D4D8), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 8),
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
                    fontSize: 48.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF3F3F46),
                  ),
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
                        color: const Color(0xFF71717A), // Gray fact text
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
        // Wooden tray at the bottom of the canvas
        Positioned(
          bottom: 0,
          child: Container(
            width: 300.w,
            height: 20.h,
            decoration: BoxDecoration(
              color: const Color(0xFFB45309),
              borderRadius: BorderRadius.circular(4.r),
              boxShadow: const [
                BoxShadow(color: Colors.black26, offset: Offset(0, 4)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaintTube(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
  ) {
    // Determine color based on text if possible, otherwise fallback to primary
    Color tubeColor = _getColorFromName(text, primaryColor);

    return ScaleButton(
      onTap: () {
        di.sl<KidsTTSService>().speak(text);
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Paint Splatter at the top (simulating squeezed paint)
          Icon(Icons.water_drop_rounded, color: tubeColor, size: 28.r),
          // The Tube
          Container(
            height: 90.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8.r),
                topRight: Radius.circular(8.r),
                bottomLeft: Radius.circular(20.r),
                bottomRight: Radius.circular(20.r),
              ),
              border: Border.all(color: const Color(0xFFE4E4E7), width: 2),
              boxShadow: [
                BoxShadow(color: Colors.black12, offset: Offset(0, 6.h)),
              ],
            ),
            child: Column(
              children: [
                // Tube label color strip
                Container(
                  height: 30.h,
                  width: double.infinity,
                  color: tubeColor,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF3F3F46),
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
          // Tube Cap
          Container(
            height: 12.h,
            width: 30.w,
            decoration: BoxDecoration(
              color: const Color(0xFF52525B), // Grey cap
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(4.r)),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorFromName(String name, Color fallback) {
    final lower = name.toLowerCase();
    if (lower.contains('red')) return Colors.red;
    if (lower.contains('blue')) return Colors.blue;
    if (lower.contains('green')) return Colors.green;
    if (lower.contains('yellow')) return Colors.yellow;
    if (lower.contains('orange')) return Colors.orange;
    if (lower.contains('purple')) return Colors.purple;
    if (lower.contains('pink')) return Colors.pink;
    if (lower.contains('black')) return Colors.black;
    if (lower.contains('white')) {
      return const Color(0xFFE4E4E7); // Off-white for visibility
    }
    if (lower.contains('brown')) return Colors.brown;
    return fallback;
  }
}
