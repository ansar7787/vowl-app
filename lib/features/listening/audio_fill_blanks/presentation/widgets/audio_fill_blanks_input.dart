import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AudioFillBlanksInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isAnswered;
  final Color primaryColor;

  const AudioFillBlanksInput({
    super.key,
    required this.controller,
    required this.isAnswered,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: !isAnswered,
      textAlign: TextAlign.center,
      style: GoogleFonts.shareTechMono(
        fontSize: 22.sp,
        fontWeight: FontWeight.w900,
        color: primaryColor,
      ),
      decoration: InputDecoration(
        hintText: "TYPE THE MISSING DATA",
        hintStyle: GoogleFonts.shareTechMono(
          fontSize: 14.sp,
          color: Colors.grey.withValues(alpha: 0.5),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.2)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }
}
