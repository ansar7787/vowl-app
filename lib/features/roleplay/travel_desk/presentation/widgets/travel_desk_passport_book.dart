import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/roleplay/travel_desk/presentation/widgets/travel_desk_stamp_painter.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color06060e = Color(0xFF06060E);
}

class TravelDeskPassportBook extends StatefulWidget {
  final List<String> options;
  final Color color;
  final int correctIndex;
  final bool isDark;
  final int? selectedIndex;
  final int? hoveredIndex;
  final String? travelDocument;
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
    this.travelDocument,
    required this.isAnswered,
    required this.isCorrect,
    required this.rippleAnimation,
    required this.onSubmitStamp,
    required this.onHoverChanged,
    required this.onHoverEnded,
    required this.onDragStarted,
  });

  @override
  State<TravelDeskPassportBook> createState() => _TravelDeskPassportBookState();
}

class _TravelDeskPassportBookState extends State<TravelDeskPassportBook> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.sw,
      padding: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        color: widget.isDark
            ? _LocalPalette.color06060e
            : Colors.black.withValues(alpha: 0.02),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  (widget.travelDocument ?? "BIOMETRIC PASSPORT BOOKLET")
                      .toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.sp,
                    color: widget.color.withValues(alpha: 0.7),
                    letterSpacing: 1.5,
                  ),
                ),
                Icon(
                  Icons.menu_book_rounded,
                  color: widget.color.withValues(alpha: 0.5),
                  size: 16.r,
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Horizontal scroll layout matching booklet pages without overflow crash
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  Colors.white,
                  Colors.white,
                  Colors.transparent,
                ],
                stops: const [0.0, 0.05, 0.95, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              clipBehavior: Clip.none,
              child: IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(
                    widget.options.length,
                    (i) => _buildDragTargetPage(i, widget.options[i]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragTargetPage(int index, String text) {
    final bool isSelected = widget.selectedIndex == index;
    final bool isHovered = widget.hoveredIndex == index;

    Color borderColor = widget.color.withValues(alpha: 0.15);
    if (isHovered && !widget.isAnswered) {
      borderColor = widget.color;
    } else if (isSelected) {
      borderColor = (index == widget.correctIndex)
          ? AppColors.gameCorrect
          : AppColors.gameIncorrect;
    }

    return DragTarget<int>(
      onWillAcceptWithDetails: (data) => !widget.isAnswered,
      onAcceptWithDetails: (details) {
        widget.onSubmitStamp(index, widget.correctIndex);
      },
      onMove: (details) {
        if (widget.hoveredIndex != index) {
          widget.onHoverChanged(index);
        }
      },
      onLeave: (data) {
        widget.onHoverEnded();
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 120.w,
              constraints: BoxConstraints(minHeight: 165.h),
              margin: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: widget.isDark ? AppColors.deepDark : Colors.white,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: borderColor,
                  width: (isSelected || isHovered) ? 3.0 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isSelected || isHovered)
                        ? (isSelected
                                  ? ((index == widget.correctIndex)
                                        ? AppColors.gameCorrect
                                        : AppColors.gameIncorrect)
                                  : widget.color)
                              .withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.08),
                    blurRadius: (isSelected || isHovered) ? 14 : 6,
                    spreadRadius: (isSelected || isHovered) ? 1 : 0,
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                fit: StackFit.expand,
                children: [
                  // Retro grid lines inside passport book with parallax effect
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: AnimatedBuilder(
                        animation: _scrollController,
                        builder: (context, child) {
                          double offset = 0;
                          if (_scrollController.hasClients) {
                            offset = _scrollController.offset;
                          }
                          return Transform.translate(
                            offset: Offset(-offset * 0.15, 0),
                            child: CustomPaint(
                              painter: PassportBackgroundGrid(
                                color: widget.color.withValues(alpha: 0.04),
                              ),
                            ),
                          );
                        },
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          Icons.public_rounded,
                          color: widget.color.withValues(
                            alpha: isHovered ? 0.35 : 0.12,
                          ),
                          size: 28.r,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          text.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            color: widget.isDark
                                ? Colors.white.withValues(alpha: 0.9)
                                : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          "PAGE 0${index + 1}",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 8.sp,
                            color: widget.color.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Glowing stamp thud ink ripple overlay
                  if (isSelected)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: widget.rippleAnimation,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: StampRipplePainter(
                              impactOffset: Offset(55.w, 82.h),
                              animationValue: widget.rippleAnimation.value,
                              themeColor: (index == widget.correctIndex)
                                  ? AppColors.gameCorrect
                                  : AppColors.gameIncorrect,
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
                                  color: (index == widget.correctIndex)
                                      ? AppColors.gameCorrect
                                      : AppColors.gameIncorrect,
                                  width: 2.5,
                                ),
                                borderRadius: BorderRadius.circular(8.r),
                                color: Colors.black.withValues(alpha: 0.1),
                              ),
                              child: Text(
                                (index == widget.correctIndex)
                                    ? "APPROVED"
                                    : "DENIED",
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w900,
                                  color: (index == widget.correctIndex)
                                      ? AppColors.gameCorrect
                                      : AppColors.gameIncorrect,
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
