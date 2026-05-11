import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/widgets/writing_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OpinionWritingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const OpinionWritingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.opinionWriting,
  });

  @override
  State<OpinionWritingScreen> createState() => _OpinionWritingScreenState();
}

class _OpinionWritingScreenState extends State<OpinionWritingScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final List<String> _leftPanArgs = [];
  final List<String> _rightPanArgs = [];
  double _scaleRotation = 0.0;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<WritingBloc>().add(FetchWritingQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onDropArg(String arg, bool isLeft) {
    if (_isAnswered) return;
    _hapticService.success();
    setState(() {
      if (isLeft) {
        _leftPanArgs.add(arg);
      } else {
        _rightPanArgs.add(arg);
      }
      
      // Calculate imbalance: diff between pans affects rotation
      double diff = (_leftPanArgs.length - _rightPanArgs.length).toDouble();
      _scaleRotation = (diff * 0.1).clamp(-0.4, 0.4);
    });
  }

  void _submitAnswer() {
    if (_isAnswered || (_leftPanArgs.isEmpty && _rightPanArgs.isEmpty)) return;
    
    _hapticService.success();
    _soundService.playCorrect();
    setState(() { _isAnswered = true; _isCorrect = true; });
    context.read<WritingBloc>().add(SubmitAnswer(true));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('writing', level: widget.level);

    return BlocConsumer<WritingBloc, WritingState>(
      listener: (context, state) {
        if (state is WritingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _leftPanArgs.clear();
              _rightPanArgs.clear();
              _scaleRotation = 0.0;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is WritingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'LOGIC MASTER!', enableDoubleUp: true);
        } else if (state is WritingGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<WritingBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is WritingLoaded) ? state.currentQuest : null;
        final options = ["STRONG EVIDENCE", "LOGICAL FLOW", "CLEAR THESIS", "COUNTER POINT", "VALID DATA"];

        return WritingBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<WritingBloc>().add(NextQuestion()),
          onHint: () => context.read<WritingBloc>().add(WritingHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 16.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 32.h),
              _buildThesisCard(quest.prompt ?? "", theme.primaryColor, isDark),
              Expanded(
                child: _buildScaleInterface(theme.primaryColor),
              ),
              _buildArgumentStones(options, theme.primaryColor),
              SizedBox(height: 32.h),
              if (!_isAnswered)
                ScaleButton(
                  onTap: _submitAnswer,
                  child: Container(
                    width: double.infinity, height: 60.h,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.r), color: (_leftPanArgs.isNotEmpty || _rightPanArgs.isNotEmpty) ? theme.primaryColor : Colors.grey, boxShadow: [if (_leftPanArgs.isNotEmpty || _rightPanArgs.isNotEmpty) BoxShadow(color: theme.primaryColor.withValues(alpha: 0.3), blurRadius: 15)]),
                    child: Center(child: Text("BALANCE THE TRUTH", style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2))),
                  ),
                ),
              SizedBox(height: 20.h),
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
          Icon(Icons.balance_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("WEIGH YOUR ARGUMENTS ON THE SCALE", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildThesisCard(String text, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        image: DecorationImage(image: const NetworkImage('https://www.transparenttextures.com/patterns/ancient-pavilion.png'), opacity: 0.05, repeat: ImageRepeat.repeat),
      ),
      child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
    );
  }

  Widget _buildScaleInterface(Color color) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Pivot Base
          Positioned(bottom: 0, child: Container(width: 10.w, height: 200.h, decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withValues(alpha: 0.5), color]), borderRadius: BorderRadius.vertical(top: Radius.circular(5.r))))),
          // The Beam
          AnimatedRotation(
            duration: 800.milliseconds, curve: Curves.elasticOut,
            turns: _scaleRotation / (2 * 3.1415),
            child: Container(
              width: 300.w, height: 12.h,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6.r), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 20)]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPan(true, color),
                  _buildPan(false, color),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPan(bool isLeft, Color color) {
    final args = isLeft ? _leftPanArgs : _rightPanArgs;
    return DragTarget<String>(
      onAcceptWithDetails: (details) => _onDropArg(details.data, isLeft),
      builder: (context, candidateData, rejectedData) {
        return Transform.translate(
          offset: Offset(0, 100.h),
          child: Column(
            children: [
              SizedBox(width: 2.w, height: 40.h, child: ColoredBox(color: color.withValues(alpha: 0.5))),
              Container(
                width: 120.w, 
                constraints: BoxConstraints(minHeight: 60.h),
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(15.r),
                  border: Border.all(color: candidateData.isNotEmpty ? Colors.white : color.withValues(alpha: 0.3), width: 2),
                ),
                child: Wrap(
                  spacing: 4.w, runSpacing: 4.h,
                  children: args.map((a) => Container(
                    padding: EdgeInsets.all(4.r),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4.r)),
                    child: Icon(Icons.check_circle_rounded, size: 12.r, color: color),
                  )).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildArgumentStones(List<String> options, Color color) {
    return Wrap(
      spacing: 12.w, runSpacing: 12.h,
      alignment: WrapAlignment.center,
      children: options.map((o) => Draggable<String>(
        data: o,
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20.r), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20)]),
            child: Text(o, style: GoogleFonts.shareTechMono(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.sp)),
          ),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: color.withValues(alpha: 0.3))),
          child: Text(o, style: GoogleFonts.shareTechMono(color: color.withValues(alpha: 0.7), fontWeight: FontWeight.bold, fontSize: 10.sp)),
        ),
      )).toList(),
    );
  }
}
