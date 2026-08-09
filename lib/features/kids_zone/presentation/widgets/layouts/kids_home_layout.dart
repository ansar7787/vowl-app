import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Dollhouse Theme for Home Game
/// Space Complexity: O(1)
/// Time Complexity: O(N) where N is the number of options (max 4)
class KidsHomeLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsHomeLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'home',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            SizedBox(height: 120.h),
            // The Dollhouse Cross-section
            Expanded(
              flex: 5,
              child: Center(child: _buildDollhouse(context, state, quest)),
            ),
            SizedBox(height: 24.h),
            AutoSizeText(
              context.tr(
                'games.kids_home_drag',
                fallback: 'Drag the furniture into the house! ✨',
              ),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.black.withValues(alpha: 0.6),
              ),
              maxLines: 2,
              minFontSize: 10,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            // The Furniture pieces (Options)
            Flexible(
              flex: 5,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Wooden Floor for furniture
                  Container(
                    height: 30.h,
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB45309), // Hardwood floor
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(8.r),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: const Color(0xFF78350F),
                          width: 4.h,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: 25.h,
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
                            child: _buildFurnitureOption(
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

  Widget _buildDollhouse(
    BuildContext context,
    KidsLoaded state,
    dynamic quest,
  ) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        final text = details.data;
        final isCorrect = (text == quest.correctAnswer);
        if (!isCorrect) {
          di.sl<KidsTTSService>().speak(text);
        }
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dollhouse Roof
            ClipPath(
              clipper: _TriangleClipper(),
              child: Container(
                width: 280.w,
                height: 60.h,
                color: isHovering
                    ? const Color(0xFFDC2626)
                    : const Color(0xFFEF4444), // Red roof
              ),
            ),
            // Dollhouse Room
            Container(
              width: 240.w,
              height: 160.h, // Made slightly taller to fit instruction
              decoration: BoxDecoration(
                color: isHovering
                    ? const Color(0xFFFEF3C7)
                    : const Color(0xFFFDE68A), // Warm yellow wallpaper
                border: Border.all(
                  color: isHovering
                      ? const Color(0xFF92400E)
                      : const Color(0xFF78350F),
                  width: isHovering ? 8.r : 6.r,
                ), // Wooden walls
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isHovering ? 0.3 : 0.15,
                    ),
                    blurRadius: isHovering ? 20 : 10,
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
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: AutoSizeText(
                        quest.question ??
                            "?", // Use instruction as clue, hide question
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF451A03),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 4,
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

  Widget _buildFurnitureOption(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
    int index,
  ) {
    final colors = [
      const Color(0xFF6366F1), // Indigo Sofa
      const Color(0xFF10B981), // Green Chair
      const Color(0xFFF43F5E), // Pink Bed
      const Color(0xFF8B5CF6), // Purple Wardrobe
    ];
    final furnitureColor = colors[index % colors.length];

    final furnitureWidget = Container(
      height: 75.h,
      width: 80.w,
      decoration: BoxDecoration(
        color: furnitureColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Furniture "cushion" line
          Container(
            margin: EdgeInsets.only(top: 20.h),
            height: 2.h,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    text,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Draggable<String>(
      data: text,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.05,
          child: Opacity(opacity: 0.9, child: furnitureWidget),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: furnitureWidget),
      child: furnitureWidget,
    );
  }
}

class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width / 2, 0); // Top Center
    path.lineTo(size.width, size.height); // Bottom Right
    path.lineTo(0, size.height); // Bottom Left
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
