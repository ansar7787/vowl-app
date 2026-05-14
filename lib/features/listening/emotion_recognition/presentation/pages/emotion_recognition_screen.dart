import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/listening/presentation/widgets/listening_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EmotionRecognitionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const EmotionRecognitionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.emotionRecognition,
  });

  @override
  State<EmotionRecognitionScreen> createState() => _EmotionRecognitionScreenState();
}

class _EmotionRecognitionScreenState extends State<EmotionRecognitionScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  final ValueNotifier<Offset> _coreOffset = ValueNotifier(Offset.zero);
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    context.read<ListeningBloc>().add(FetchListeningQuests(gameType: widget.gameType, level: widget.level));
  }

  @override
  void dispose() {
    _coreOffset.dispose();
    super.dispose();
  }

  void _onCoreMove(Offset delta, BoxConstraints constraints) {
    if (_isAnswered) return;
    double nextX = (_coreOffset.value.dx + delta.dx).clamp(-constraints.maxWidth / 2 + 40.r, constraints.maxWidth / 2 - 40.r);
    double nextY = (_coreOffset.value.dy + delta.dy).clamp(-constraints.maxHeight / 2 + 40.r, constraints.maxHeight / 2 - 40.r);
    _coreOffset.value = Offset(nextX, nextY);
  }

  void _submitAnswer(int index, int correct) {
    if (_isAnswered) return;
    setState(() => _selectedIndex = index);
    bool isCorrect = index == correct;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; });
      context.read<ListeningBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { _isAnswered = true; _isCorrect = false; });
      context.read<ListeningBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('listening', level: widget.level);

    return BlocConsumer<ListeningBloc, ListeningState>(
      listener: (context, state) {
        if (state is ListeningLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedIndex = null;
              _coreOffset.value = Offset.zero;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ListeningGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'SENTIMENT PROBER!', enableDoubleUp: true);
        } else if (state is ListeningGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<ListeningBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is ListeningLoaded) ? state.currentQuest : null;
        
        return ListeningBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<ListeningBloc>().add(NextQuestion()),
          onHint: () => context.read<ListeningBloc>().add(ListeningHintUsed()),
          child: quest == null ? const SizedBox() : Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  SizedBox(height: 16.h),
                  _buildInstruction(theme.primaryColor),
                  const Spacer(flex: 2),
                  _buildEmitterNode(quest.textToSpeak ?? "", theme.primaryColor),
                  const Spacer(flex: 3),
                  Expanded(
                    flex: 12,
                    child: _buildNeuralField(quest.options ?? [], quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark),
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstruction(Color primaryColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30.r), border: Border.all(color: primaryColor.withValues(alpha: 0.2))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.psychology_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text(
            _isAnswered ? "ANALYSIS COMPLETE" : "PROBE THE EMOTIONAL FREQUENCY", 
            style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildEmitterNode(String tts, Color color) {
    return ScaleButton(
      onTap: () {
        _soundService.playTts(tts);
        _hapticService.selection();
      },
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          shape: BoxShape.circle, 
          color: color.withValues(alpha: 0.1), 
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 5)],
        ),
        child: Icon(Icons.graphic_eq_rounded, color: color, size: 40.r),
      ),
    );
  }

  Widget _buildNeuralField(List<String> options, int correct, Color color, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ValueListenableBuilder<Offset>(
          valueListenable: _coreOffset,
          builder: (context, offset, _) {
            return OverflowBox(
              alignment: Alignment.center,
              maxWidth: constraints.maxWidth * 2.0, // Aggressive overflow expansion
              maxHeight: constraints.maxHeight * 2.0,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none, // Absolute prevention of clipping
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
                        child: _buildReservoir(index, options[index], correct, color),
                      );
                    }),
                    
                    // The Psychology Core (Draggable Orb)
                    Transform.translate(
                      offset: offset,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: (details) => _onCoreMove(details.delta, constraints),
                        onPanEnd: (_) {
                          for (int i = 0; i < options.length; i++) {
                            double xDist = 110.w;
                            double yDist = 130.h;
                            double x = (i % 2 == 0) ? -xDist : xDist;
                            double y = (i < 2) ? -yDist : yDist;
                            if ((offset - Offset(x, y)).distance < 60.r) {
                              _submitAnswer(i, correct);
                              return;
                            }
                          }
                          _coreOffset.value = Offset.zero;
                        },
                        child: Container(
                          width: 70.r, height: 70.r,
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
    bool isSelected = _selectedIndex == index;
    // Only show Green if they actually got it right. 
    // If they got it wrong, don't reveal the correct answer in the grid (Loophole fix).
    bool isCorrect = _isAnswered && index == correct && _isCorrect == true;
    bool isWrong = _isAnswered && isSelected && _isCorrect == false;
    
    Color tileColor = isCorrect ? Colors.greenAccent : (isWrong ? Colors.redAccent : color);

    return AnimatedContainer(
      duration: 300.ms,
      width: 90.r, height: 90.r,
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: tileColor.withValues(alpha: 0.05),
        shape: BoxShape.circle,
        border: Border.all(
          color: tileColor.withValues(alpha: (isCorrect || isWrong) ? 0.8 : 0.2), 
          width: (isCorrect || isWrong) ? 3 : 1.5
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
                style: GoogleFonts.outfit(fontSize: 8.sp, fontWeight: FontWeight.w900, color: tileColor, letterSpacing: 0.5)
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
    
    // Draw Faded Crosshair (Fade at edges to avoid 'square container' feel)
    final lineGradient = RadialGradient(
      colors: [color.withValues(alpha: 0.5), color.withValues(alpha: 0.0)],
      stops: const [0.5, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final linePaint = Paint()
      ..shader = lineGradient
      ..strokeWidth = 1;
      
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), linePaint);
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), linePaint);
    
    // Draw Multi-layered Neural Circles
    canvas.drawCircle(Offset(centerX, centerY), 50.r, paint);
    canvas.drawCircle(Offset(centerX, centerY), 100.r, Paint()..color = color.withAlpha(40)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    canvas.drawCircle(Offset(centerX, centerY), 150.r, Paint()..color = color.withAlpha(20)..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

