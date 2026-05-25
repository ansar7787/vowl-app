import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class TrueFalseReadingCoinZone extends StatelessWidget {
  final double coinX;
  final double coinY;
  final double coinRotation;
  final Function(Offset) onFlick;
  final bool isDark;
  final Color themeColor;

  const TrueFalseReadingCoinZone({
    super.key,
    required this.coinX,
    required this.coinY,
    required this.coinRotation,
    required this.onFlick,
    required this.isDark,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250.h,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Slots
          Positioned(left: 20.w, child: _buildSlot("FALSE", Colors.redAccent, isDark)),
          Positioned(right: 20.w, child: _buildSlot("TRUE", Colors.greenAccent, isDark)),
          
          // The Coin
          Transform.translate(
            offset: Offset(coinX, coinY),
            child: Transform.rotate(
              angle: coinRotation,
              child: GestureDetector(
                onPanUpdate: (details) => onFlick(details.delta),
                child: Container(
                  width: 100.r,
                  height: 100.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Colors.amberAccent, Colors.orangeAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black45 : Colors.black12,
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(color: Colors.white30, width: 2),
                  ),
                  child: Center(
                    child: Icon(Icons.stars_rounded, color: Colors.white, size: 48.r),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlot(String label, Color color, bool isDark) {
    bool isTargeted = (coinX > 0 && label == "TRUE") || (coinX < 0 && label == "FALSE");
    return Opacity(
      opacity: isTargeted ? 1.0 : (isDark ? 0.3 : 0.15),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.1 : 0.05),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isTargeted ? color : color.withValues(alpha: isDark ? 0.4 : 0.2), 
            width: 2,
          ),
        ),
        child: RotatedBox(
          quarterTurns: 3,
          child: Text(
            label, 
            style: GoogleFonts.outfit(
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
