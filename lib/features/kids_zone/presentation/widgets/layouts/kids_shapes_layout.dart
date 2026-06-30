import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';

/// Toy Construction Theme for Shapes Game
/// Space Complexity: O(1)
/// Time Complexity: O(N) where N is the number of options (max 4)
class KidsShapesLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsShapesLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'shapes',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            SizedBox(height: 120.h),
            // The Crane holding Blueprint
            Expanded(
              flex: 5,
              child: Center(
                child: _buildBlueprintCrane(quest.question ?? "?", quest.emoji),
              ),
            ),
            // The Toy Building Blocks
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
                        child: _buildToyBlock(
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
            ),
          ],
        );
      },
    );
  }

  Widget _buildBlueprintCrane(String text, String? emoji) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crane Arm (Yellow/Black stripes)
        Container(
          height: 16.h,
          width: 180.w,
          decoration: BoxDecoration(
            color: const Color(0xFFFBBF24), // Construction Yellow
            borderRadius: BorderRadius.circular(4.r),
            border: Border.all(color: const Color(0xFF92400E), width: 2),
            // A simple stripe effect would require a custom painter, 
            // but we keep it solid yellow for performance and clean aesthetic
          ),
        ),
        // Crane Hook / Cables
        Container(
          height: 30.h,
          width: 4.w,
          color: const Color(0xFF52525B), // Steel cable
        ),
        // The Blueprint Paper
        Container(
          width: 240.w,
          height: 160.h,
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A), // Blueprint Blue
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Grid pattern for blueprint
              Positioned.fill(
                child: CustomPaint(
                  painter: _BlueprintGridPainter(),
                ),
              ),
              Center(
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
                        fontWeight: FontWeight.w400, // Thinner weight for blueprint aesthetic
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToyBlock(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
    int index,
  ) {
    // Cycle through bright primary colors for the toy blocks
    final colors = [
      const Color(0xFFEF4444), // Red
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF10B981), // Green
      const Color(0xFFF59E0B), // Yellow
    ];
    final color = colors[index % colors.length];

    return ScaleButton(
      onTap: () {
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The studs on top of the block
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(2, (i) => _buildStud(color)),
          ),
          // The main block body
          Container(
            height: 90.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4.r),
              border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  offset: Offset(0, 6.h),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2),
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStud(Color color) {
    return Container(
      height: 12.h,
      width: 20.w,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.vertical(top: Radius.circular(4.r)),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.4), width: 1),
          left: BorderSide(color: Colors.black.withValues(alpha: 0.1), width: 1),
          right: BorderSide(color: Colors.black.withValues(alpha: 0.1), width: 1),
        ),
      ),
    );
  }
}

class _BlueprintGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final spacing = 20.w;
    
    // Draw vertical lines
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
