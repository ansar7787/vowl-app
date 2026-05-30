import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CompleteSentenceTrajectoryPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;
  
  CompleteSentenceTrajectoryPainter({
    required this.start, 
    required this.end, 
    required this.color
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final diff = start - end;
    final controlPoint = Offset(start.dx + diff.dx, start.dy - diff.dy.abs() * 2);
    final targetPoint = Offset(start.dx + diff.dx * 2, start.dy - diff.dy.abs() * 3);
    
    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, targetPoint.dx, targetPoint.dy);
    
    canvas.drawPath(path, paint);
    canvas.drawCircle(targetPoint, 8.r, Paint()..color = color.withValues(alpha: 0.5));
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
