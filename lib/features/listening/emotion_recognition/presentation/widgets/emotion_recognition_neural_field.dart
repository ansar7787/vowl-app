import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
class EmotionRecognitionNeuralField extends StatelessWidget {
  final List<String> options;
  final int correctAnswerIndex;
  final Color color;
  final bool isAnswered;
  final bool? isCorrectState;
  final int? selectedIndex;
  final ValueNotifier<Offset> coreOffset;
  final Function(Offset, BoxConstraints) onCoreMove;
  final Function(int) onSubmitAnswer;

  const EmotionRecognitionNeuralField({
    super.key,
    required this.options,
    required this.correctAnswerIndex,
    required this.color,
    required this.isAnswered,
    required this.isCorrectState,
    required this.selectedIndex,
    required this.coreOffset,
    required this.onCoreMove,
    required this.onSubmitAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ValueListenableBuilder<Offset>(
          valueListenable: coreOffset,
          builder: (context, offset, _) {
            return OverflowBox(
              alignment: Alignment.center,
              maxWidth: constraints.maxWidth * 2.0,
              maxHeight: constraints.maxHeight * 2.0,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Neural Grid Background Lines
                  CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: NeuralGridPainter(color.withValues(alpha: 0.1)),
                  ),
  
                  // The Neural Grid Targets
                  ...List.generate(options.length, (index) {
                    double xDist = 110.w;
                    double yDist = 130.h;
                    double x = (index % 2 == 0) ? -xDist : xDist;
                    double y = (index < 2) ? -yDist : yDist;
                    
                    return Transform.translate(
                      offset: Offset(x, y),
                      child: _buildReservoir(index, options[index], correctAnswerIndex, color),
                    );
                  }),
                  
                  // The Psychology Core (Draggable Orb)
                  Transform.translate(
                    offset: offset,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (details) => onCoreMove(details.delta, constraints),
                      onPanEnd: (_) {
                        for (int i = 0; i < options.length; i++) {
                          double xDist = 110.w;
                          double yDist = 130.h;
                          double x = (i % 2 == 0) ? -xDist : xDist;
                          double y = (i < 2) ? -yDist : yDist;
                          if ((offset - Offset(x, y)).distance < 60.r) {
                            onSubmitAnswer(i);
                            return;
                          }
                        }
                        coreOffset.value = Offset.zero;
                      },
                      child: Container(
                        width: 70.r,
                        height: 70.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [Colors.white, color, color.withValues(alpha: 0.8)],
                            stops: const [0.1, 0.4, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 20, spreadRadius: 5),
                            BoxShadow(color: Colors.white.withValues(alpha: 0.4), blurRadius: 10, spreadRadius: 2),
                          ],
                        ),
                        child: Icon(Icons.blur_on_rounded, color: Colors.white.withValues(alpha: 0.9), size: 35.r),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReservoir(int index, String text, int correct, Color color) {
    bool isSelected = selectedIndex == index;
    bool isCorrect = isAnswered && index == correct && isCorrectState == true;
    bool isWrong = isAnswered && isSelected && isCorrectState == false;
    
    Color tileColor = isCorrect ? Colors.greenAccent : (isWrong ? Colors.redAccent : color);

    return AnimatedContainer(
      duration: 300.ms,
      width: 90.r,
      height: 90.r,
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: tileColor.withValues(alpha: 0.05),
        shape: BoxShape.circle,
        border: Border.all(
          color: tileColor.withValues(alpha: (isCorrect || isWrong) ? 0.8 : 0.2), 
          width: (isCorrect || isWrong) ? 3 : 1.5,
        ),
        boxShadow: (isCorrect || isWrong) 
            ? [BoxShadow(color: tileColor.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 2)]
            : [],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_getEmotionEmoji(text), style: TextStyle(fontSize: 22.sp))
              .animate(target: (isCorrect || isWrong) ? 1 : 0)
              .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), curve: Curves.elasticOut),
            SizedBox(height: 2.h),
            FittedBox(
              child: Text(
                text.toUpperCase(), 
                textAlign: TextAlign.center, 
                style: TextStyle(fontFamily: 'Outfit', 
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w900,
                  color: tileColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEmotionEmoji(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'angry':
      case 'anger': return '😡';
      case 'excited':
      case 'excitement': return '🤩';
      case 'sad':
      case 'sadness': return '😢';
      case 'bored':
      case 'boredom': return '😑';
      case 'happy':
      case 'happiness': return '😊';
      case 'surprised':
      case 'surprise': return '😲';
      case 'curious': return '🤔';
      case 'neutral': return '😐';
      case 'fear':
      case 'afraid': return '😨';
      case 'confident': return '😎';
      default: return '🎭';
    }
  }
}

class NeuralGridPainter extends CustomPainter {
  final Color color;
  NeuralGridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
      
    double centerX = size.width / 2;
    double centerY = size.height / 2;
    
    final lineGradient = RadialGradient(
      colors: [color.withValues(alpha: 0.5), color.withValues(alpha: 0.0)],
      stops: const [0.5, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final linePaint = Paint()
      ..shader = lineGradient
      ..strokeWidth = 1;
      
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), linePaint);
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), linePaint);
    
    canvas.drawCircle(Offset(centerX, centerY), 50.r, paint);
    canvas.drawCircle(Offset(centerX, centerY), 100.r, Paint()..color = color.withAlpha(40)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    canvas.drawCircle(Offset(centerX, centerY), 150.r, Paint()..color = color.withAlpha(20)..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
