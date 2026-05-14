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
  
  Offset _coreOffset = Offset.zero;
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

  void _onCoreMove(Offset delta) {
    if (_isAnswered) return;
    setState(() {
      _coreOffset += delta;
      _hapticService.selection();
    });
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
              _coreOffset = Offset.zero;
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
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 16.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 40.h),
              _buildEmitterNode(quest.textToSpeak ?? "", theme.primaryColor),
              const Spacer(),
              _buildNeuralField(quest.options ?? [], quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark),
              const Spacer(),
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
          Text("NAVIGATE THE CORE TO MATCH EMOTION", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
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
        width: 80.r, height: 80.r,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.1), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Icon(Icons.waves_rounded, color: color, size: 32.r),
      ),
    );
  }

  Widget _buildNeuralField(List<String> options, int correct, Color color, bool isDark) {
    return SizedBox(
      height: 400.h, width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Neural Grid
          ...List.generate(options.length, (index) {
            double x = (index % 2 == 0) ? -120.w : 120.w;
            double y = (index < 2) ? -140.h : 140.h;
            return Transform.translate(
              offset: Offset(x, y),
              child: _buildReservoir(index, options[index], correct, color),
            );
          }),
          
          // The Psychology Core
          Transform.translate(
            offset: _coreOffset,
            child: GestureDetector(
              onPanUpdate: (details) => _onCoreMove(details.delta),
              onPanEnd: (_) {
                for (int i = 0; i < options.length; i++) {
                  double x = (i % 2 == 0) ? -120.w : 120.w;
                  double y = (i < 2) ? -140.h : 140.h;
                  if ((_coreOffset - Offset(x, y)).distance < 60.r) {
                    _submitAnswer(i, correct);
                    break;
                  }
                }
              },
              child: Container(
                width: 80.r, height: 80.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 20)],
                ),
                child: Icon(Icons.bolt_rounded, color: Colors.white, size: 40.r),
              ).animate(onPlay: (c) => c.repeat()).shimmer(color: Colors.white24, duration: 2.seconds),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservoir(int index, String text, int correct, Color color) {
    bool isCorrect = _isAnswered && index == correct && _isCorrect == true;
    bool isWrong = _isAnswered && index == _selectedIndex && _isCorrect == false;
    Color tileColor = isCorrect ? Colors.greenAccent : (isWrong ? Colors.redAccent : color);

    return Container(
      width: 100.r, height: 100.r,
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: tileColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: tileColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_getEmotionEmoji(text), style: TextStyle(fontSize: 24.sp)),
          SizedBox(height: 4.h),
          Text(text.toUpperCase(), textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 8.sp, fontWeight: FontWeight.w900, color: tileColor)),
        ],
      ),
    );
  }

  String _getEmotionEmoji(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'anger': return '😡';
      case 'excitement': return '🤩';
      case 'sadness': return '😢';
      case 'boredom': return '😑';
      case 'happiness': return '😊';
      case 'surprise': return '😲';
      default: return '🎭';
    }
  }
}

