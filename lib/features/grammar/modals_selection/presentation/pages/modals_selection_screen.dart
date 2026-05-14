import 'dart:math';
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
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class ModalsSelectionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ModalsSelectionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.modalsSelection,
  });

  @override
  State<ModalsSelectionScreen> createState() => _ModalsSelectionScreenState();
}

class _ModalsSelectionScreenState extends State<ModalsSelectionScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  double _rotation = 0.0;
  int _selectedIndex = 0;
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

  void _onRotate(double delta, int count) {
    if (_isAnswered) return;
    setState(() {
      _rotation += delta * 0.01;
      _selectedIndex = ((_rotation * (count / 6.28)).round() % count).abs();
      // Tick haptic
      _hapticService.selection();
    });
  }

  void _submitAnswer(int correctIndex) {
    if (_isAnswered) return;
    
    bool isCorrect = _selectedIndex == correctIndex;

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
        _rotation = 0.0;
        _selectedIndex = 0;
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
              _selectedIndex = 0;
              _rotation = 0.0;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is GrammarGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'MODAL MASTER!', enableDoubleUp: true);
        } else if (state is GrammarGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<GrammarBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final options = quest?.options ?? ["CAN", "COULD", "MUST", "SHOULD"];
        
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
              _buildSentenceBoard(quest.question ?? "??", theme.primaryColor, isDark),
              SizedBox(height: 48.h),
              Expanded(
                child: _buildRotaryDial(options, theme.primaryColor, isDark),
              ),
              if (!_isAnswered)
                _buildSubmitButton(quest.correctAnswerIndex ?? 0, theme.primaryColor),
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
          Icon(Icons.av_timer_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("ROTATE DIAL TO CHOOSE MOOD", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSentenceBoard(String text, Color primaryColor, bool isDark) {
    return GlassTile(
      padding: EdgeInsets.all(24.r),
      borderRadius: BorderRadius.circular(24.r),
      child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 20.sp, color: isDark ? Colors.white70 : Colors.black87)),
    );
  }

  Widget _buildRotaryDial(List<String> options, Color primaryColor, bool isDark) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background Notch Circle
        Container(
          width: 250.r, height: 250.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: primaryColor.withValues(alpha: 0.1), width: 10.r),
          ),
        ),
        // Words
        ...List.generate(options.length, (i) {
          final angle = (i * (6.28 / options.length)) - 1.57;
          final isSelected = _selectedIndex == i;
          return Transform.translate(
            offset: Offset(cos(angle) * 110.r, sin(angle) * 110.r),
            child: Text(
              options[i],
              style: GoogleFonts.outfit(
                fontSize: isSelected ? 18.sp : 14.sp,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? primaryColor : (isDark ? Colors.white38 : Colors.black38),
              ),
            ),
          );
        }),
        // The Physical Dial
        GestureDetector(
          onPanUpdate: (details) => _onRotate(details.delta.dx + details.delta.dy, options.length),
          child: Transform.rotate(
            angle: _rotation,
            child: Container(
              width: 150.r, height: 150.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Colors.grey[800]!, Colors.grey[900]!, Colors.black],
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black54, blurRadius: 20, offset: const Offset(10, 10)),
                  BoxShadow(color: Colors.white10, blurRadius: 2, offset: const Offset(-2, -2)),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Indicators/Knurls
                  ...List.generate(12, (i) => Transform.rotate(
                    angle: i * (6.28 / 12),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(width: 4.r, height: 10.r, margin: EdgeInsets.only(top: 8.r), color: Colors.white12),
                    ),
                  )),
                  // The Pointer
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 8.r, height: 30.r,
                      margin: EdgeInsets.only(top: 15.r),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(4.r),
                        boxShadow: [BoxShadow(color: primaryColor, blurRadius: 10)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(int correctIndex, Color primaryColor) {
    return ScaleButton(
      onTap: () => _submitAnswer(correctIndex),
      child: Container(
        width: double.infinity, height: 60.h,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.r), color: primaryColor),
        child: Center(child: Text("LOCK CHOICE", style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2))),
      ),
    );
  }
}

