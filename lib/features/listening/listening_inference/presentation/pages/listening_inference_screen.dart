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

class ListeningInferenceScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ListeningInferenceScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.listeningInference,
  });

  @override
  State<ListeningInferenceScreen> createState() => _ListeningInferenceScreenState();
}

class _ListeningInferenceScreenState extends State<ListeningInferenceScreen> with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  late AnimationController _pulseController;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    context.read<ListeningBloc>().add(FetchListeningQuests(gameType: widget.gameType, level: widget.level));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ListeningGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'INFERENCE MASTER!', enableDoubleUp: true);
        } else if (state is ListeningGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<ListeningBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is ListeningLoaded) ? state.currentQuest : null;
        
        return ListeningBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          useScrolling: true,
          onContinue: () => context.read<ListeningBloc>().add(NextQuestion()),
          onHint: () => context.read<ListeningBloc>().add(ListeningHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10.h),
              _buildInstruction(theme.primaryColor),
                    SizedBox(height: 10.h),
                    _buildRadarCore(quest.textToSpeak ?? "", theme.primaryColor),
                    SizedBox(height: 30.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        quest.question?.toUpperCase() ?? "INFER THE ACTOR",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w900, color: theme.primaryColor, letterSpacing: 1.2),
                      ),
                    ),
                    SizedBox(height: 30.h),
                    _buildInferenceGrid(quest.options ?? [], quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark),
              SizedBox(height: 30.h),
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
          Icon(Icons.radar_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("PROBE SUBTEXT TO INFER INTENT", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildRadarCore(String tts, Color color) {
    return ScaleButton(
      onTap: () {
        _soundService.playTts(tts);
        _hapticService.selection();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse Rings
          ...List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                double progress = (_pulseController.value + (i * 0.33)) % 1.0;
                return Container(
                  width: (100 + (progress * 150)).r,
                  height: (100 + (progress * 150)).r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: (1.0 - progress) * 0.3), width: 2.r),
                  ),
                );
              },
            );
          }),
          
          // Central Core
          Container(
            padding: EdgeInsets.all(32.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle, 
              gradient: RadialGradient(colors: [color, color.withValues(alpha: 0.7)]),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 30, spreadRadius: 5)],
            ),
            child: Icon(Icons.psychology_rounded, size: 64.r, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildInferenceGrid(List<String> options, int correct, Color color, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Wrap(
        spacing: 16.w,
        runSpacing: 16.h,
        alignment: WrapAlignment.center,
        children: List.generate(options.length, (index) {
          bool isSelected = _selectedIndex == index;
          bool isChoiceCorrect = _isAnswered && index == correct && _isCorrect == true;
          bool isChoiceWrong = _isAnswered && isSelected && _isCorrect == false;
          
          return ScaleButton(
            onTap: () => _submitAnswer(index, correct),
            child: Container(
              width: 135.w,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: isChoiceCorrect 
                    ? Colors.greenAccent 
                    : (isChoiceWrong 
                        ? Colors.redAccent 
                        : (isSelected ? color : const Color(0xFF1E1E24))),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isChoiceCorrect || isChoiceWrong || isSelected 
                      ? Colors.white.withValues(alpha: 0.5) 
                      : color.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    offset: Offset(0, 4.h),
                    blurRadius: 8,
                  ),
                  if (isSelected || isChoiceCorrect || isChoiceWrong)
                    BoxShadow(
                      color: (isChoiceCorrect ? Colors.greenAccent : (isChoiceWrong ? Colors.redAccent : color)).withValues(alpha: 0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isChoiceCorrect ? Icons.verified_user_rounded : (isChoiceWrong ? Icons.report_problem_rounded : Icons.bubble_chart_rounded),
                    color: Colors.white,
                    size: 18.r
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    options[index].toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

