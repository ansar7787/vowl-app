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

class QuestionFormatterScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const QuestionFormatterScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.questionFormatter,
  });

  @override
  State<QuestionFormatterScreen> createState() => _QuestionFormatterScreenState();
}
class _QuestionFormatterScreenState extends State<QuestionFormatterScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  double _crankRotation = 0.0;
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

  void _onCrankUpdate(double delta) {
    if (_isAnswered) return;
    setState(() {
      _crankRotation += delta * 0.01;
      // Provide haptic feedback every 10 degrees
      if ((_crankRotation * 57.29).abs().toInt() % 10 == 0) {
        _hapticService.selection();
      }
    });

    if (_crankRotation.abs() >= 6.28) { // One full rotation
      _showQuestionOptions();
    }
  }

  void _showQuestionOptions() {
    // In actual use, we'd transition to an options state
  }

  void _onOptionSelect(int index, int correctIndex) {
    if (_isAnswered) return;
    bool isCorrect = index == correctIndex;

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
        _crankRotation = 0.0;
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
              _crankRotation = 0.0;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is GrammarGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'QUESTION MASTER!', enableDoubleUp: true);
        } else if (state is GrammarGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<GrammarBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final options = quest?.options ?? ["Is he...?", "Does he...?", "Has he...?", "Was he...?"];
        
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
              _buildInverterBoard(quest.sentence ?? "STATEMENT", theme.primaryColor, isDark),
              SizedBox(height: 60.h),
              if (!_isAnswered && _crankRotation.abs() < 6.28)
                _buildCrank(theme.primaryColor, isDark)
              else if (!_isAnswered)
                _buildQuestionOptions(options, quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark)
              else
                _buildCorrectResult(quest.correctAnswer ?? "", theme.primaryColor, isDark),
              SizedBox(height: 40.h),
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
          Icon(Icons.cached_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("CRANK TO INVERT STATEMENT", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildInverterBoard(String text, Color primaryColor, bool isDark) {
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(_crankRotation),
      alignment: Alignment.center,
      child: GlassTile(
        padding: EdgeInsets.all(32.r),
        borderRadius: BorderRadius.circular(24.r),
        child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 22.sp, color: isDark ? Colors.white : Colors.black87)),
      ),
    );
  }

  Widget _buildCrank(Color primaryColor, bool isDark) {
    return GestureDetector(
      onPanUpdate: (details) => _onCrankUpdate(details.delta.dx + details.delta.dy),
      child: Container(
        width: 150.r, height: 150.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 8.r),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: _crankRotation,
              child: Column(
                children: [
                  Container(width: 12.r, height: 40.r, decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(6.r))),
                  const Spacer(),
                ],
              ),
            ),
            Icon(Icons.bolt_rounded, color: primaryColor, size: 32.r),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionOptions(List<String> options, int correctIndex, Color primaryColor, bool isDark) {
    return Column(
      children: options.asMap().entries.map((entry) => Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: GestureDetector(
          onTap: () => _onOptionSelect(entry.key, correctIndex),
          child: GlassTile(
            padding: EdgeInsets.all(16.r),
            borderRadius: BorderRadius.circular(16.r),
            child: Center(child: Text(entry.value, style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.bold, color: primaryColor))),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildCorrectResult(String result, Color primaryColor, bool isDark) {
    return GlassTile(
      padding: EdgeInsets.all(24.r),
      borderRadius: BorderRadius.circular(24.r),
      color: Colors.greenAccent.withValues(alpha: 0.1),
      child: Column(
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 32.r),
          SizedBox(height: 12.h),
          Text(result, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
        ],
      ),
    );
  }
}

