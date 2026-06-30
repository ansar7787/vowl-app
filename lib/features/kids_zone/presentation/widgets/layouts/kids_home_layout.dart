import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';

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
              child: Center(
                child: _buildDollhouse(quest.question ?? "?"),
              ),
            ),
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
                      borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
                      border: Border(top: BorderSide(color: const Color(0xFF78350F), width: 4.h)),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 25.h, left: 16.w, right: 16.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(quest.options?.length ?? 0, (index) {
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

  Widget _buildDollhouse(String text) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dollhouse Roof
        ClipPath(
          clipper: _TriangleClipper(),
          child: Container(
            width: 240.w,
            height: 60.h,
            color: const Color(0xFFEF4444), // Red roof
          ),
        ),
        // Dollhouse Room
        Container(
          width: 200.w,
          height: 120.h,
          decoration: BoxDecoration(
            color: const Color(0xFFFDE68A), // Warm yellow wallpaper
            border: Border.all(color: const Color(0xFF78350F), width: 6.r), // Wooden walls
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 36.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF451A03),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
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

    return ScaleButton(
      onTap: () {
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      child: Container(
        height: 75.h,
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
                  child: Text(
                    text,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
