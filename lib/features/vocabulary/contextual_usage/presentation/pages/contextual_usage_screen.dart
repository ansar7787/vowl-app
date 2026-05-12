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

class ContextualUsageScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ContextualUsageScreen({super.key, required this.level, this.gameType = GameSubtype.contextualUsage});

  @override
  State<ContextualUsageScreen> createState() => _ContextualUsageScreenState();
}

class _ContextualUsageScreenState extends State<ContextualUsageScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  VocabularyQuest? _lastQuest;
  String? _selectedOption;

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(FetchVocabularyQuests(gameType: widget.gameType, level: widget.level));
  }

  void _submitAnswer(String selected, String correct) {
    if (_isAnswered) return;
    setState(() { _selectedOption = selected; _isAnswered = true; });

    bool isCorrect = selected.trim().toLowerCase() == correct.trim().toLowerCase();
    Future.delayed(600.ms, () {
      if (!mounted) return;
      if (isCorrect) {
        _hapticService.success(); _soundService.playCorrect();
        setState(() => _isCorrect = true);
        context.read<VocabularyBloc>().add(SubmitAnswer(true));
      } else {
        _hapticService.error(); _soundService.playWrong();
        setState(() => _isCorrect = false);
        context.read<VocabularyBloc>().add(SubmitAnswer(false));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.getTheme('vocabulary', level: widget.level);
    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: (context, state) {
        if (state is VocabularyLoaded) {
          if (state.currentIndex != _lastProcessedIndex || (_isAnswered && state.lastAnswerCorrect == null)) {
            setState(() {
              _lastQuest = state.currentQuest;
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedOption = null;
            });
          }
        }
        if (state is VocabularyGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'USAGE EXPERT!', enableDoubleUp: true);
        } else if (state is VocabularyGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<VocabularyBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is VocabularyLoaded) ? state.currentQuest : _lastQuest;
        if (quest == null && state is! VocabularyGameComplete) return const GameShimmerLoading();
        return VocabularyBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, showConfetti: _showConfetti,
          onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
          onHint: () => context.read<VocabularyBloc>().add(VocabularyHintUsed()),
          child: quest == null ? const SizedBox() : _buildUnfoldContent(quest, theme.primaryColor),
        );
      },
    );
  }

  Widget _buildUnfoldContent(VocabularyQuest quest, Color color) {
    String displaySentence = quest.question?.replaceAll("_____", _selectedOption ?? "_____") ?? "";
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("USAGE UNFOLD", style: GoogleFonts.shareTechMono(fontSize: 10.sp, color: color, letterSpacing: 4)).animate().fadeIn(),
        SizedBox(height: 40.h),
        Container(
          width: 0.85.sw,
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: color.withValues(alpha: 0.2)),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: -10)],
          ),
          child: Text(
            displaySentence,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.white, height: 1.6),
          ),
        ).animate(target: _isAnswered ? 1 : 0).shimmer(duration: 1.seconds).scale(begin: const Offset(1,1), end: const Offset(1.02, 1.02)),
        SizedBox(height: 60.h),
        Wrap(
          spacing: 12.w, runSpacing: 12.h,
          alignment: WrapAlignment.center,
          children: (quest.options ?? []).map((o) {
            final isSelected = _selectedOption == o;
            return ScaleButton(
              onTap: () => _submitAnswer(o, quest.correctAnswer ?? ""),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: isSelected ? (_isCorrect == true ? Colors.green.withValues(alpha: 0.4) : (_isCorrect == false ? Colors.red.withValues(alpha: 0.4) : color.withValues(alpha: 0.2))) : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: isSelected ? (_isCorrect == true ? Colors.green : (_isCorrect == false ? Colors.red : color)) : color.withValues(alpha: 0.2)),
                ),
                child: Text(o, style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            );
          }).toList(),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
      ],
    );
  }
}
