import 'dart:math' as math;
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
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AudioMultipleChoiceScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const AudioMultipleChoiceScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.audioMultipleChoice,
  });

  @override
  State<AudioMultipleChoiceScreen> createState() => _AudioMultipleChoiceScreenState();
}

class _AudioMultipleChoiceScreenState extends State<AudioMultipleChoiceScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  double _rotation = 0.0;
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

  void _onSpin(double delta) {
    if (_isAnswered) return;
    setState(() {
      _rotation += delta / 200;
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
              _rotation = 0.0;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ListeningGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'SONIC RADAR!', enableDoubleUp: true);
        } else if (state is ListeningGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<ListeningBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is ListeningLoaded) ? state.currentQuest : null;
        
        return ListeningBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          useScrolling: false,
          onContinue: () => context.read<ListeningBloc>().add(NextQuestion()),
          onHint: () => context.read<ListeningBloc>().add(ListeningHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              const Spacer(flex: 1),
              _buildInstruction(theme.primaryColor),
              const Spacer(flex: 2),
              _buildQuestionDisplay(quest.question ?? "", theme.primaryColor, isDark),
              const Spacer(flex: 2),
              Expanded(
                flex: 12,
                child: _buildOrbitalSpinner(quest.options ?? [], quest.correctAnswerIndex ?? 0, theme.primaryColor, quest.textToSpeak ?? ""),
              ),
              const Spacer(flex: 1),
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
          Icon(Icons.track_changes_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text("SPIN SATELLITES TO LOCK IN CORRECT DATA", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionDisplay(String text, Color color, bool isDark) {
    return GlassTile(
      padding: EdgeInsets.all(24.r), borderRadius: BorderRadius.circular(20.r),
      child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
    );
  }

  Widget _buildOrbitalSpinner(List<String> options, int correct, Color color, String tts) {
    return GestureDetector(
      onPanUpdate: (details) => _onSpin(details.delta.dx),
      child: Container(
        width: double.infinity,
        color: Colors.transparent, // Ensures the entire area is draggable
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Orbital Ring
            Container(
              width: 300.r, height: 300.r,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.1), width: 2)),
            ),
            
            // Central Core
            ScaleButton(
              onTap: () {
                _soundService.playTts(tts);
                _hapticService.selection();
              },
              child: Container(
                width: 100.r, height: 100.r,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20)]),
                child: Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 50.r),
              ),
            ),
            
            // Satellite Options
            ...List.generate(options.length, (index) {
              double angle = (index * (2 * 3.14159 / options.length)) + _rotation;
              double radius = 130.r;
              return Align(
                alignment: Alignment.center,
                child: Transform.translate(
                  offset: Offset(radius * math.cos(angle), radius * math.sin(angle)),
                  child: _buildSatellite(index, options[index], correct, color),
                ),
              );
            }),
            
            // Target Zone
            Positioned(
              top: 40.h,
              child: Container(
                width: 40.w, height: 10.h,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(5.r)),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 1.seconds),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSatellite(int index, String text, int correct, Color color) {
    bool isSelected = _selectedIndex == index;
    bool isCorrect = _isAnswered && index == correct && _isCorrect == true;
    bool isWrong = _isAnswered && isSelected && _isCorrect == false;
    Color tileColor = isCorrect ? Colors.greenAccent : (isWrong ? Colors.redAccent : (isSelected ? Colors.white : color));

    return ScaleButton(
      onTap: () => _submitAnswer(index, correct),
      child: Container(
        width: 80.r, height: 80.r,
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: tileColor.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: tileColor, width: 2),
          boxShadow: isSelected ? [BoxShadow(color: tileColor.withValues(alpha: 0.5), blurRadius: 15)] : [],
        ),
        child: Center(child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: Colors.white))),
      ),
    );
  }
}

