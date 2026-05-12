import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/widgets/vocabulary_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class IdiomsScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const IdiomsScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.idioms,
  });

  @override
  State<IdiomsScreen> createState() => _IdiomsScreenState();
}

class _IdiomsScreenState extends State<IdiomsScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  Offset _mirrorPosition = const Offset(150, 100);
  bool _meaningRevealed = false;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  VocabularyQuest? _lastQuest;

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(FetchVocabularyQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onMirrorMove(DragUpdateDetails details) {
    if (_isAnswered) return;
    setState(() {
      _mirrorPosition += details.delta;
      // Reveal meaning if mirror is near center
      if ((_mirrorPosition - const Offset(150, 150)).distance < 50) {
        if (!_meaningRevealed) {
          _hapticService.success();
          _meaningRevealed = true;
        }
      }
    });
  }

  void _submitAnswer(int index, String selected, String correct) {
    if (_isAnswered) return;
    bool isCorrect = selected.trim().toLowerCase() == correct.trim().toLowerCase();
    
    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; });
      context.read<VocabularyBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { _isAnswered = true; _isCorrect = false; });
      context.read<VocabularyBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('vocabulary', level: widget.level);

    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: (context, state) {
        if (state is VocabularyLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = state.lastAnswerCorrect == null && _isAnswered;

          if (isNewQuestion || isRetry) {
            setState(() {
              _lastQuest = state.currentQuest;
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _meaningRevealed = false;
              _mirrorPosition = const Offset(150, 100);
            });
          }
        }
        if (state is VocabularyGameComplete) {
          final xp = state.xpEarned;
          final coins = state.coinsEarned;
          setState(() => _showConfetti = true);
          if (!context.mounted) return;
          GameDialogHelper.showCompletion(
            context,
            xp: xp,
            coins: coins,
            title: 'IDIOM ARTIST!',
            enableDoubleUp: true,
          );
        } else if (state is VocabularyGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<VocabularyBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is VocabularyLoaded) ? state.currentQuest : _lastQuest;
        if (quest == null && state is! VocabularyGameComplete) return const GameShimmerLoading();
        final options = quest?.options ?? [];
        final literalImage = quest?.topicEmoji ?? "🎨";

        return VocabularyBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
          onHint: () => context.read<VocabularyBloc>().add(VocabularyHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 16.h),
              _buildInstruction(theme.primaryColor),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildArtFrame(literalImage, quest.correctAnswer ?? "", theme.primaryColor, isDark),
                    if (!_isAnswered) _buildPortalMirror(theme.primaryColor),
                  ],
                ),
              ),
              _buildIdiomPlates(options, quest.word ?? "", theme.primaryColor, isDark),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstruction(Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30.r), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Text("USE THE MIRROR TO REVEAL THE MEANING", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
    );
  }

  Widget _buildArtFrame(String emoji, String meaning, Color color, bool isDark) {
    return Container(
      width: 300.r, height: 300.r,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 4),
      ),
      child: Center(
        child: _meaningRevealed 
          ? Padding(
              padding: EdgeInsets.all(20.r),
              child: Text(meaning.toUpperCase(), textAlign: TextAlign.center, style: GoogleFonts.specialElite(fontSize: 18.sp, fontWeight: FontWeight.bold, color: color)),
            )
          : Text(emoji, style: TextStyle(fontSize: 80.sp)).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 2.seconds),
      ),
    );
  }

  Widget _buildPortalMirror(Color color) {
    return Positioned(
      left: _mirrorPosition.dx - 80.r, top: _mirrorPosition.dy - 80.r,
      child: GestureDetector(
        onPanUpdate: _onMirrorMove,
        child: Container(
          width: 160.r, height: 160.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 6),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 30)],
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Center(child: Icon(Icons.auto_awesome_rounded, color: color.withValues(alpha: 0.5), size: 40.r)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdiomPlates(List<String> options, String correctWord, Color color, bool isDark) {
    return Column(
      children: [
        Text("SELECT THE MATCHING IDIOM", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
        SizedBox(height: 16.h),
        Wrap(
          spacing: 12.w, runSpacing: 12.h,
          alignment: WrapAlignment.center,
          children: options.map((o) => ScaleButton(
            onTap: () => _submitAnswer(options.indexOf(o), o, correctWord),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: _isAnswered && o == correctWord ? Colors.greenAccent.withValues(alpha: 0.2) : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: _isAnswered && o == correctWord ? Colors.greenAccent : color.withValues(alpha: 0.2)),
              ),
              child: Text(o, style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            ),
          )).toList(),
        ),
      ],
    ).animate().fadeIn().moveY(begin: 20, end: 0);
  }
}

