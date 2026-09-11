import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AudioTrueFalseInstruction extends StatelessWidget {
  final Color color;
  final String instruction;

  const AudioTrueFalseInstruction({
    super.key,
    required this.color,
    required this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          instruction,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white54
                : Colors.black54,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
