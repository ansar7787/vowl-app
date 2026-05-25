import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class AmbientIdEmitterNode extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;

  const AmbientIdEmitterNode({
    super.key,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(28.r),
        decoration: BoxDecoration(
          shape: BoxShape.circle, 
          color: color, 
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2.5),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 25),
            BoxShadow(color: Colors.black.withValues(alpha: 0.4), offset: const Offset(0, 4), blurRadius: 10),
          ],
        ),
        child: Icon(Icons.settings_input_antenna_rounded, size: 52.r, color: Colors.white),
      ),
    );
  }
}
