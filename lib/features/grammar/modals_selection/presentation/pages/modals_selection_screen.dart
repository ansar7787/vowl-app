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
import 'package:flutter_animate/flutter_animate.dart';
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
              SizedBox(height: 10.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 20.h),
              
              // Optimized: Concise Context Card (The Diamond Standard)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(22.r),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(28.r),
                    border: Border.all(color: theme.primaryColor.withValues(alpha: 0.15), width: 1.5),
                  ),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.fredoka(
                        fontSize: 20.sp, 
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.5
                      ),
                      children: _buildSentenceWithBlank(
                        quest.question ?? "___ sentence.", 
                        _isAnswered ? options[_selectedIndex] : null, 
                        theme.primaryColor, 
                        isDark
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),

              Expanded(
                child: _buildRotaryDial(options, theme.primaryColor, isDark),
              ),

              if (!_isAnswered)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.w),
                  child: _buildSubmitButton(quest.correctAnswerIndex ?? 0, theme.primaryColor),
                ),
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
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.av_timer_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text(
            "CALIBRATE THE MODAL DIAL", 
            style: GoogleFonts.outfit(
              fontSize: 10.sp, 
              fontWeight: FontWeight.w900, 
              color: primaryColor, 
              letterSpacing: 1.5
            )
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _buildSentenceWithBlank(String template, String? selected, Color primaryColor, bool isDark) {
    final parts = template.contains("____") ? template.split("____") : template.split("___");
    List<InlineSpan> spans = [];
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i]));
      if (i < parts.length - 1) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 8.w),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected != null ? primaryColor : (isDark ? Colors.white38 : Colors.black38), 
                  width: 2
                )
              )
            ),
            child: Text(
              selected ?? "      ", 
              style: GoogleFonts.outfit(
                fontSize: 22.sp, 
                fontWeight: FontWeight.bold, 
                color: primaryColor
              )
            ),
          ).animate(target: selected != null ? 1 : 0).shimmer(duration: 2.seconds),
        ));
      }
    }
    return spans;
  }

  Widget _buildRotaryDial(List<String> options, Color primaryColor, bool isDark) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer Halo
        Container(
          width: 280.r, height: 280.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: primaryColor.withValues(alpha: 0.05), width: 2.r),
          ),
        ),
        // Dial Words (Holographic Ring)
        ...List.generate(options.length, (i) {
          final angle = (i * (2 * pi / options.length)) - (pi / 2);
          final isSelected = _selectedIndex == i;
          return Transform.translate(
            offset: Offset(cos(angle) * 125.r, sin(angle) * 125.r),
            child: AnimatedScale(
              duration: 300.ms,
              scale: isSelected ? 1.2 : 0.9,
              child: Text(
                options[i],
                style: GoogleFonts.outfit(
                  fontSize: 16.sp,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: isSelected ? primaryColor : (isDark ? Colors.white30 : Colors.black26),
                  letterSpacing: 1
                ),
              ),
            ),
          );
        }),
        // The Physical Dial (Glass Morph)
        GestureDetector(
          onPanUpdate: (details) {
            // Precise Rotation Logic
            final center = Offset(140.r, 140.r);
            final pos = details.localPosition;
            final angle = atan2(pos.dy - center.dy, pos.dx - center.dx);
            _onRotate(angle, options.length);
          },
          child: Transform.rotate(
            angle: _rotation,
            child: Container(
              width: 170.r, height: 170.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: isDark 
                    ? [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.02)]
                    : [Colors.black.withValues(alpha: 0.05), Colors.black.withValues(alpha: 0.01)],
                ),
                border: Border.all(color: primaryColor.withValues(alpha: 0.2), width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(5, 5)),
                  BoxShadow(color: primaryColor.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 2),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Indicators (Glass Etchings)
                  ...List.generate(24, (i) => Transform.rotate(
                    angle: i * (2 * pi / 24),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: 2.r, height: 8.r, 
                        margin: EdgeInsets.only(top: 10.r), 
                        color: primaryColor.withValues(alpha: 0.2)
                      ),
                    ),
                  )),
                  // The Glowing Pointer
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 6.r, height: 35.r,
                      margin: EdgeInsets.only(top: 15.r),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(3.r),
                        boxShadow: [
                          BoxShadow(color: primaryColor, blurRadius: 15, spreadRadius: 1)
                        ],
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
        width: double.infinity, height: 65.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22.r), 
          gradient: LinearGradient(colors: [primaryColor, primaryColor.withValues(alpha: 0.8)]),
          boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))]
        ),
        child: Center(
          child: Text(
            "LOCK CONFIGURATION", 
            style: GoogleFonts.outfit(
              fontSize: 14.sp, 
              fontWeight: FontWeight.w900, 
              color: Colors.white, 
              letterSpacing: 2
            )
          )
        ),
      ),
    );
  }
}

