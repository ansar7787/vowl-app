import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/widgets/grammar_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PartsOfSpeechScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const PartsOfSpeechScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.partsOfSpeech,
  });

  @override
  State<PartsOfSpeechScreen> createState() => _PartsOfSpeechScreenState();
}

class _PartsOfSpeechScreenState extends State<PartsOfSpeechScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  Offset _dragOffset = Offset.zero;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<GrammarBloc>().add(FetchGrammarQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onFlick(int targetIndex, int correctIndex) {
    if (_isAnswered) return;

    bool isCorrect = targetIndex == correctIndex;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; });
      context.read<GrammarBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { 
        _isAnswered = true; 
        _isCorrect = false;
      });
      context.read<GrammarBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listener: (context, state) {
        if (state is GrammarLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _dragOffset = Offset.zero;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is GrammarGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'POS PRO!', enableDoubleUp: true);
        } else if (state is GrammarGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<GrammarBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final options = (quest?.options?.length ?? 0) >= 4 ? quest!.options!.sublist(0, 4) : ["Noun", "Verb", "Adj", "Adv"];
        
        return GrammarBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,
          onContinue: () => context.read<GrammarBloc>().add(NextQuestion()),
          onHint: () => context.read<GrammarBloc>().add(GrammarHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 20.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 32.h),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Vortex Buckets (Corners)
                    _buildVortex(0, options[0], Colors.blueAccent, Alignment.topLeft),
                    _buildVortex(1, options[1], Colors.purpleAccent, Alignment.topRight),
                    _buildVortex(2, options[2], Colors.orangeAccent, Alignment.bottomLeft),
                    _buildVortex(3, options[3], Colors.greenAccent, Alignment.bottomRight),
                    
                    // The Word to Flick
                    if (!_isAnswered)
                      GestureDetector(
                        onPanUpdate: (details) {
                          setState(() => _dragOffset += details.delta);
                          _checkCollision(quest.correctAnswerIndex ?? 0);
                        },
                        onPanEnd: (details) {
                          setState(() => _dragOffset = Offset.zero);
                        },
                        child: Transform.translate(
                          offset: _dragOffset,
                          child: Transform.rotate(
                            angle: _dragOffset.dx / 100,
                            child: _buildDraggableWord(quest.targetWord ?? quest.word ?? "??", theme.primaryColor, isDark),
                          ),
                        ),
                      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                  ],
                ),
              ),
              SizedBox(height: 40.h),
            ],
          ),
        );
      },
    );
  }

  void _checkCollision(int correctIndex) {
    final threshold = 120.r;
    if (_dragOffset.dx < -threshold && _dragOffset.dy < -threshold) {
      _onFlick(0, correctIndex);
    } else if (_dragOffset.dx > threshold && _dragOffset.dy < -threshold) {
      _onFlick(1, correctIndex);
    } else if (_dragOffset.dx < -threshold && _dragOffset.dy > threshold) {
      _onFlick(2, correctIndex);
    } else if (_dragOffset.dx > threshold && _dragOffset.dy > threshold) {
      _onFlick(3, correctIndex);
    }
  }

  Widget _buildInstruction(Color primaryColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30.r), border: Border.all(color: primaryColor.withValues(alpha: 0.2))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cyclone_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("FLICK INTO THE VORTEX", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildVortex(int index, String label, Color color, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 120.r, height: 120.r,
        margin: EdgeInsets.all(10.r),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [color.withValues(alpha: 0.6), color.withValues(alpha: 0.1), Colors.transparent]),
              ),
            ).animate(onPlay: (c) => c.repeat()).rotate(duration: 3.seconds),
            Text(label.toUpperCase(), style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableWord(String word, Color primaryColor, bool isDark) {
    return GlassTile(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 20.h),
      borderRadius: BorderRadius.circular(24.r),
      child: Text(
        word, 
        textAlign: TextAlign.center, 
        style: GoogleFonts.fredoka(fontSize: 28.sp, color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)
      ),
    );
  }
}

