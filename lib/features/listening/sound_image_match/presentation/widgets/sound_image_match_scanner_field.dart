import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class SoundImageMatchScannerField extends StatelessWidget {
  final List<String> options;
  final int correctAnswerIndex;
  final Color color;
  final bool isAnswered;
  final bool? isCorrectState;
  final int? selectedIndex;
  final Offset lensPosition;
  final Function(Offset) onScan;
  final Function(int) onSelect;

  const SoundImageMatchScannerField({
    super.key,
    required this.options,
    required this.correctAnswerIndex,
    required this.color,
    required this.isAnswered,
    required this.isCorrectState,
    required this.selectedIndex,
    required this.lensPosition,
    required this.onScan,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // The Options Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.w,
                mainAxisSpacing: 16.h,
                childAspectRatio: constraints.maxWidth / (constraints.maxHeight / 2 * 1.8),
              ),
              itemCount: options.length,
              itemBuilder: (context, index) => _buildEncryptedTile(
                index,
                options[index],
                correctAnswerIndex,
                color,
                constraints,
              ),
            ),
          
            // The Scanning Lens
            Positioned(
              left: lensPosition.dx - 50.r,
              top: lensPosition.dy - 50.r,
              child: GestureDetector(
                onPanUpdate: (details) => onScan(lensPosition + details.delta),
                child: Container(
                  width: 100.r,
                  height: 100.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.cyanAccent, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.filter_center_focus_rounded,
                      color: Colors.cyanAccent,
                      size: 24.r,
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.2, 1.2),
                      duration: 800.ms,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEncryptedTile(
    int index,
    String text,
    int correct,
    Color color,
    BoxConstraints fieldConstraints,
  ) {
    double tileWidth = fieldConstraints.maxWidth / 2;
    double tileHeight = tileWidth / (fieldConstraints.maxWidth / (fieldConstraints.maxHeight / 2 * 1.8));
    
    double centerX = (index % 2 == 0) ? tileWidth / 2 : tileWidth * 1.5;
    double centerY = (index < 2) ? tileHeight / 2 : tileHeight * 1.5;
    
    double dist = (lensPosition - Offset(centerX, centerY)).distance;
    bool isRevealed = dist < 60.r;
    bool isSelected = isAnswered && selectedIndex == index;
    Color tileColor = isSelected
        ? (isCorrectState == true ? Colors.greenAccent : Colors.redAccent)
        : Colors.white.withValues(alpha: 0.05);

    return GestureDetector(
      onDoubleTap: () => onSelect(index),
      child: GlassTile(
        padding: EdgeInsets.all(12.r),
        borderRadius: BorderRadius.circular(20.r),
        color: tileColor,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isRevealed || isAnswered)
              FittedBox(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getCategoryIcon(text),
                      color: isSelected ? Colors.white : color,
                      size: 32.r,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      text.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? Colors.white : color,
                      ),
                    ),
                  ],
                ),
              ),
            if (!isRevealed && !isAnswered)
              Icon(Icons.security_rounded, color: Colors.white24, size: 32.r),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fruits': return Icons.apple_rounded;
      case 'tools': return Icons.build_rounded;
      case 'vehicles': return Icons.directions_car_rounded;
      case 'professions': return Icons.work_rounded;
      case 'animals': return Icons.pets_rounded;
      case 'places': return Icons.location_on_rounded;
      default: return Icons.category_rounded;
    }
  }
}
