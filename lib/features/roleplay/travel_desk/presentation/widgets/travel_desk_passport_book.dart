import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/roleplay/travel_desk/presentation/widgets/travel_desk_stamp_painter.dart';

class TravelDeskPassportBook extends StatelessWidget {
  final List<String> options;
  final Color color;
  final int correctIndex;
  final bool isDark;
  final int? selectedIndex;
  final int? hoveredIndex;
  final bool isAnswered;
  final bool? isCorrect;
  final Animation<double> rippleAnimation;
  final Function(int, int) onSubmitStamp;
  final Function(int) onHoverChanged;
  final Function() onHoverEnded;
  final Function() onDragStarted;

  const TravelDeskPassportBook({
    super.key,
    required this.options,
    required this.color,
    required this.correctIndex,
    required this.isDark,
    required this.selectedIndex,
    required this.hoveredIndex,
    required this.isAnswered,
    required this.isCorrect,
    required this.rippleAnimation,
    required this.onSubmitStamp,
    required this.onHoverChanged,
    required this.onHoverEnded,
    required this.onDragStarted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF06060E)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "BIOMETRIC PASSPORT BOOKLET",
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 10.sp,
                  color: color.withValues(alpha: 0.7),
                  letterSpacing: 1.5,
                ),
              ),
              Icon(
                Icons.menu_book_rounded,
                color: color.withValues(alpha: 0.5),
                size: 16.r,
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Horizontal scroll layout matching booklet pages without overflow crash
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                options.length,
                (i) => _buildDragTargetPage(i, options[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragTargetPage(int index, String text) {
    final bool isSelected = selectedIndex == index;
    final bool isHovered = hoveredIndex == index;

    Color borderColor = color.withValues(alpha: 0.15);
    if (isHovered && !isAnswered) {
      borderColor = color;
    } else if (isSelected) {
      borderColor = (isCorrect ?? false)
          ? Colors.greenAccent
          : Colors.redAccent;
    }

    return DragTarget<int>(
      onWillAcceptWithDetails: (data) => !isAnswered,
      onAcceptWithDetails: (details) {
        onSubmitStamp(index, correctIndex);
      },
      onMove: (details) {
        if (hoveredIndex != index) {
          onHoverChanged(index);
        }
      },
      onLeave: (data) {
        onHoverEnded();
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 110.w,
              height: 165.h,
              margin: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F0F1B) : Colors.white,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: borderColor,
                  width: (isSelected || isHovered) ? 3.0 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isSelected || isHovered)
                        ? (isSelected
                                  ? ((isCorrect ?? false)
                                        ? Colors.greenAccent
                                        : Colors.redAccent)
                                  : color)
                              .withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.08),
                    blurRadius: (isSelected || isHovered) ? 14 : 6,
                    spreadRadius: (isSelected || isHovered) ? 1 : 0,
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Retro grid lines inside passport book
                  Positioned.fill(
                    child: CustomPaint(
                      painter: PassportBackgroundGrid(
                        color: color.withValues(alpha: 0.04),
                      ),
                    ),
                  ),

                  // Page contents
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 14.h,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.public_rounded,
                          color: color.withValues(
                            alpha: isHovered ? 0.35 : 0.12,
                          ),
                          size: 28.r,
                        ),
                        const Spacer(),
                        Text(
                          text.toUpperCase(),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'RobotoMono',
                            fontSize: 12.sp,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.9)
                                : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "PAGE 0${index + 1}",
                          style: TextStyle(
                            fontFamily: 'RobotoMono',
                            fontSize: 8.sp,
                            color: color.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Glowing stamp thud ink ripple overlay
                  if (isSelected)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: rippleAnimation,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: StampRipplePainter(
                              impactOffset: Offset(55.w, 82.h),
                              animationValue: rippleAnimation.value,
                              themeColor: (isCorrect ?? false)
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                            ),
                          );
                        },
                      ),
                    ),

                  // Stamp mark locked on page
                  if (isSelected)
                    Center(
                      child:
                          Transform.rotate(
                            angle: -0.22,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: (isCorrect ?? false)
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                  width: 2.5,
                                ),
                                borderRadius: BorderRadius.circular(8.r),
                                color: Colors.black.withValues(alpha: 0.1),
                              ),
                              child: Text(
                                (isCorrect ?? false) ? "APPROVED" : "DENIED",
                                style: TextStyle(
                                  fontFamily: 'RobotoMono',
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w900,
                                  color: (isCorrect ?? false)
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ).animate().scale(
                            duration: 200.ms,
                            curve: Curves.elasticOut,
                            begin: const Offset(3.5, 3.5),
                            end: const Offset(1, 1),
                          ),
                    ),
                ],
              ),
            )
            .animate(target: isHovered ? 1.0 : 0.0)
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.05, 1.05),
              duration: 150.ms,
            );
      },
    );
  }
}

// Background Grid custom painter for authentic passport passport book
class PassportBackgroundGrid extends CustomPainter {
  final Color color;
  PassportBackgroundGrid({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    double spacing = 12.r;

    // Draw vertical lines
    for (double x = spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Draw horizontal lines
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant PassportBackgroundGrid oldDelegate) {
    return oldDelegate.color != color;
  }
}
