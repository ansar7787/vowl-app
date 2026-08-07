import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';

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
              child: Center(child: _buildBlueprintCrane(context, state, quest)),
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

  Widget _buildBlueprintCrane(BuildContext context, KidsLoaded state, dynamic quest) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        final text = details.data;
        final isCorrect = (text == quest.correctAnswer);
        di.sl<KidsTTSService>().speak(text);
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
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
              ),
            ),
            // Crane Hook / Cables
            Container(
              height: 30.h,
              width: 4.w,
              color: const Color(0xFF52525B), // Steel cable
            ),
            // The Blueprint Paper
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 280.w,
              height: 200.h,
              decoration: BoxDecoration(
                color: isHovering ? const Color(0xFF3B82F6) : const Color(0xFF1E3A8A), // Blueprint Blue (lighter when hovering)
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: isHovering ? Colors.yellowAccent : Colors.white, width: 4),
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
                    child: CustomPaint(painter: _BlueprintGridPainter()),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (quest.emoji != null)
                          Text(quest.emoji!, style: TextStyle(fontSize: 64.sp)), // Enlarge emoji since question is removed
                        if (quest.funFact != null) ...[
                          SizedBox(height: 8.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: AutoSizeText(
                              quest.funFact!,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF93C5FD), // Light blue
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              minFontSize: 10,
                            ),
                          ),
                        ],
                      ],
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

    final blockWidget = Column(
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
          width: 75.w, // Fixed width for Draggable overlay stability
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4.r),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.1),
              width: 1,
            ),
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
            child: AutoSizeText(
              text,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              minFontSize: 8,
            ),
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
          child: Opacity(
            opacity: 0.9,
            child: blockWidget,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: blockWidget,
      ),
      child: blockWidget,
    );
  }

  Widget _buildStud(Color color) {
    return Container(
      height: 12.h,
      width: 20.w,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.vertical(top: Radius.circular(4.r)),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.15),
          width: 1,
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
