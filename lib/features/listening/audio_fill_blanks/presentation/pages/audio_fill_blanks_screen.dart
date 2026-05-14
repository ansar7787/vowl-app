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

class AudioFillBlanksScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const AudioFillBlanksScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.audioFillBlanks,
  });

  @override
  State<AudioFillBlanksScreen> createState() => _AudioFillBlanksScreenState();
}

class _AudioFillBlanksScreenState extends State<AudioFillBlanksScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  double _revealProgress = 0.0;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ListeningBloc>().add(FetchListeningQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onSmear(double delta) {
    if (_isAnswered) return;
    setState(() {
      _revealProgress = (_revealProgress + delta).clamp(0.0, 1.0);
      if (_revealProgress > 0.05) _hapticService.selection();
    });
  }

  void _submitAnswer(String correct) {
    if (_isAnswered || _controller.text.isEmpty) return;
    bool isCorrect = _controller.text.trim().toLowerCase() == correct.trim().toLowerCase();
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
              _revealProgress = 0.0;
              _controller.clear();
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ListeningGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'AUDITORY ACE!', enableDoubleUp: true);
        } else if (state is ListeningGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<ListeningBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is ListeningLoaded) ? state.currentQuest : null;
        
        return ListeningBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti, useScrolling: false,
          onContinue: () => context.read<ListeningBloc>().add(NextQuestion()),
          onHint: () => context.read<ListeningBloc>().add(ListeningHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              const Spacer(flex: 1),
              _buildInstruction(theme.primaryColor),
              const Spacer(flex: 2),
              _buildInkJar(quest.textToSpeak ?? "", theme.primaryColor),
              const Spacer(flex: 2),
              Expanded(
                flex: 6,
                child: _buildInkCanvas(quest.textWithBlanks ?? "", theme.primaryColor, isDark),
              ),
              const Spacer(flex: 2),
              _buildInputTerminal(theme.primaryColor, isDark),
              const Spacer(flex: 2),
              if (!_isAnswered)
                ScaleButton(
                  onTap: () => _submitAnswer(quest.correctAnswer ?? ""),
                  child: Container(
                    width: double.infinity, height: 60.h,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.r), color: theme.primaryColor),
                    child: Center(child: Text("SUBMIT TRANSCRIPTION", style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2))),
                  ),
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
          Icon(Icons.water_drop_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Flexible(
            child: Text(
              "SMEAR THE INK TO REVEAL TRANSCRIPTION",
              style: GoogleFonts.outfit(
                fontSize: 10.sp,
                fontWeight: FontWeight.w900,
                color: primaryColor,
                letterSpacing: 1.2,
              ),
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInkJar(String text, Color color) {
    return ScaleButton(
      onTap: () {
        _soundService.playTts(text);
        _hapticService.selection();
      },
      child: Container(
        width: 100.r, height: 100.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 3),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 20)],
        ),
        child: Icon(Icons.graphic_eq_rounded, size: 40.r, color: color),
      ),
    );
  }

  Widget _buildInkCanvas(String text, Color primaryColor, bool isDark) {
    return GestureDetector(
      onPanUpdate: (details) => _onSmear(details.delta.dx.abs() / 200 + details.delta.dy.abs() / 200),
      child: GlassTile(
        padding: EdgeInsets.all(32.r), borderRadius: BorderRadius.circular(24.r),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: _revealProgress,
              child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 20.sp, color: isDark ? Colors.white70 : Colors.black87)),
            ),
            if (_revealProgress < 1.0)
              ...List.generate(5, (i) => Positioned(
                left: 20.w + (i * 50.w),
                child: Container(
                  width: 60.r, height: 60.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? Colors.indigo[900]!.withValues(alpha: 0.8 - _revealProgress) : Colors.black87.withValues(alpha: 0.8 - _revealProgress),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 2.seconds),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildInputTerminal(Color primaryColor, bool isDark) {
    return TextField(
      controller: _controller,
      enabled: !_isAnswered,
      textAlign: TextAlign.center,
      style: GoogleFonts.shareTechMono(fontSize: 22.sp, fontWeight: FontWeight.w900, color: primaryColor),
      decoration: InputDecoration(
        hintText: "TYPE THE MISSING DATA",
        hintStyle: GoogleFonts.shareTechMono(fontSize: 14.sp, color: Colors.grey.withValues(alpha: 0.5)),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.2))),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
      ),
    );
  }
}

