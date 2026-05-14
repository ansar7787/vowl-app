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

class TenseMasteryScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const TenseMasteryScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.tenseMastery,
  });

  @override
  State<TenseMasteryScreen> createState() => _TenseMasteryScreenState();
}

class _TenseMasteryScreenState extends State<TenseMasteryScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  double _sliderValue = 0.5; // Default to Present
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _isFinalFailure = false;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  final List<String> _tenses = ["Past", "Present", "Future"];

  String get _currentTense {
    if (_sliderValue < 0.25) return "Past";
    if (_sliderValue > 0.75) return "Future";
    return "Present";
  }

  @override
  void initState() {
    super.initState();
    context.read<GrammarBloc>().add(FetchGrammarQuests(gameType: widget.gameType, level: widget.level));
  }

  void _submitAnswer(GameQuest quest) {
    if (_isAnswered) return;
    
    final selectedTense = _currentTense;
    bool isCorrect = selectedTense.toLowerCase() == (quest.correctAnswerCategory?.toLowerCase() ?? quest.correctAnswer?.toLowerCase());

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
              _isFinalFailure = state.isFinalFailure;
              _sliderValue = 0.5;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is GrammarGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'TIMELINE RESTORED!', enableDoubleUp: true);
        } else if (state is GrammarGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<GrammarBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        
        return GrammarBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          isFinalFailure: _isFinalFailure,
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
                  padding: EdgeInsets.all(22.r),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(color: theme.primaryColor.withValues(alpha: 0.15), width: 1.5),
                  ),
                  child: Text(
                    quest.sentence ?? "",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(
                      fontSize: 20.sp,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),

              SizedBox(height: 60.h),
              
              // The Cinematic Timeline
              _buildTimelineSlider(theme.primaryColor, isDark),
              
              const Spacer(),
              
              if (!_isAnswered)
                ScaleButton(
                  onTap: () => _submitAnswer(quest),
                  child: Container(
                    width: double.infinity, height: 65.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.r), 
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.8)]
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withValues(alpha: 0.4), 
                          blurRadius: 20, 
                          offset: const Offset(0, 8)
                        )
                      ]
                    ),
                    child: Center(
                      child: Text(
                        "FREEZE TIMELINE", 
                        style: GoogleFonts.outfit(
                          fontSize: 16.sp, 
                          fontWeight: FontWeight.w900, 
                          color: Colors.white, 
                          letterSpacing: 3
                        )
                      )
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds, color: Colors.white24),
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
          Icon(Icons.auto_awesome_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text(
            "SHIFT THROUGH TIME", 
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

  Widget _buildTimelineSlider(Color primaryColor, bool isDark) {
    return Container(
      height: 120.h,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 30.w),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Track
          Container(
            height: 6.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(3.r),
            ),
          ),
          
          // The Timeline Nodes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _tenses.map((tense) {
              final isCurrent = _currentTense == tense;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 14.r, height: 14.r,
                    decoration: BoxDecoration(
                      color: isCurrent ? primaryColor : (isDark ? Colors.white10 : Colors.black12),
                      shape: BoxShape.circle,
                      boxShadow: isCurrent 
                          ? [BoxShadow(color: primaryColor.withValues(alpha: 0.4), blurRadius: 15, spreadRadius: 4)] 
                          : [],
                    ),
                  ),
                  SizedBox(height: 28.h),
                  Text(
                    tense.toUpperCase(), 
                    style: GoogleFonts.outfit(
                      fontSize: 12.sp, 
                      fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600, 
                      color: isCurrent ? primaryColor : (isDark ? Colors.white24 : Colors.black26), 
                      letterSpacing: 1.5
                    )
                  ),
                ],
              );
            }).toList(),
          ),
          
          // The Draggable Chrono-Sphere
          Positioned(
            left: _sliderValue * (MediaQuery.of(context).size.width - 100.w),
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                if (_isAnswered) return;
                setState(() {
                  _sliderValue = (_sliderValue + details.delta.dx / (MediaQuery.of(context).size.width - 100.w)).clamp(0.0, 1.0);
                  // Dynamic Haptics
                  if ((_sliderValue - 0.0).abs() < 0.02 || (_sliderValue - 0.5).abs() < 0.02 || (_sliderValue - 1.0).abs() < 0.02) {
                    _hapticService.selection();
                  }
                });
              },
              onHorizontalDragEnd: (details) {
                if (_isAnswered) return;
                setState(() {
                  if (_sliderValue < 0.25) {
                    _sliderValue = 0.0;
                  } else if (_sliderValue > 0.75) {
                    _sliderValue = 1.0;
                  } else {
                    _sliderValue = 0.5;
                  }
                  _hapticService.heavy();
                });
              },
              child: Container(
                width: 60.r, height: 60.r,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: primaryColor.withValues(alpha: 0.4), blurRadius: 25, spreadRadius: 5)
                  ],
                  border: Border.all(color: primaryColor, width: 6.r),
                ),
                child: Center(
                  child: Icon(Icons.timer_rounded, color: primaryColor, size: 28.r),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .shimmer(duration: 1500.ms, color: primaryColor.withValues(alpha: 0.2)),
            ),
          ),
        ],
      ),
    );
  }
}
