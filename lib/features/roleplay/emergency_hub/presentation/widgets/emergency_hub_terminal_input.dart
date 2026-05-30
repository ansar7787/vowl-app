import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class EmergencyHubTerminalInput extends StatelessWidget {
  final TextEditingController controller;
  final String correctAnswer;
  final bool isDark;
  final VoidCallback onChanged;

  const EmergencyHubTerminalInput({
    super.key,
    required this.controller,
    required this.correctAnswer,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCodeValid = controller.text.trim().replaceAll(' ', '').toLowerCase() ==
        correctAnswer.trim().replaceAll(' ', '').toLowerCase();

    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF07070F) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "DECRYPTION KEYBOARD SLATE",
                style: GoogleFonts.shareTechMono(
                  fontSize: 10.sp,
                  color: isCodeValid ? Colors.greenAccent : Colors.amberAccent,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                isCodeValid ? Icons.vpn_key_rounded : Icons.keyboard_rounded,
                color: isCodeValid ? Colors.greenAccent : Colors.amberAccent,
                size: 16.r,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          TextField(
            controller: controller,
            onChanged: (_) => onChanged(),
            style: GoogleFonts.shareTechMono(
              fontSize: 18.sp,
              color: isCodeValid ? Colors.greenAccent : Colors.redAccent,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
            decoration: InputDecoration(
              hintText: "ENTER CODE (e.g. CODE RED 99)",
              hintStyle: GoogleFonts.shareTechMono(
                fontSize: 14.sp,
                color: isDark ? Colors.white24 : Colors.black26,
                letterSpacing: 1.5,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F0F1B) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(
                  color: isCodeValid ? Colors.greenAccent.withValues(alpha: 0.4) : Colors.redAccent.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(
                  color: isCodeValid ? Colors.greenAccent : Colors.redAccent,
                  width: 2,
                ),
              ),
              prefixIcon: Icon(
                Icons.terminal_rounded,
                color: isCodeValid ? Colors.greenAccent : Colors.redAccent,
                size: 20.r,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
