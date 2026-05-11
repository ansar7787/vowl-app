import 'dart:math' as math;
import 'package:flutter/material.dart';

class KnowledgeNexusPainter extends CustomPainter {
  final Color color;
  final double progress;

  KnowledgeNexusPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final random = math.Random(42); // Fixed seed for stable nodes
    final nodes = List.generate(15, (index) {
      return Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
    });

    // Animate nodes slightly
    final animatedNodes = nodes.map((node) {
      final dx = math.sin(progress * 2 * math.pi + node.dx) * 10;
      final dy = math.cos(progress * 2 * math.pi + node.dy) * 10;
      return node + Offset(dx, dy);
    }).toList();

    // Draw connections
    for (var i = 0; i < animatedNodes.length; i++) {
      for (var j = i + 1; j < animatedNodes.length; j++) {
        final distance = (animatedNodes[i] - animatedNodes[j]).distance;
        if (distance < 150) {
          paint.color = color.withValues(alpha: (1 - distance / 150) * 0.2);
          canvas.drawLine(animatedNodes[i], animatedNodes[j], paint);
        }
      }
    }

    // Draw nodes
    for (var node in animatedNodes) {
      canvas.drawCircle(node, 2.0, dotPaint);
      
      // Draw pulse
      final pulse = (progress + nodes.indexOf(node) / 15) % 1.0;
      canvas.drawCircle(
        node, 
        10.0 * pulse, 
        Paint()..color = color.withValues(alpha: (1 - pulse) * 0.1)..style = PaintingStyle.stroke
      );
    }
  }

  @override
  bool shouldRepaint(KnowledgeNexusPainter oldDelegate) => true;
}
