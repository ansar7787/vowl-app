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
    setState(() {
      _selectedOption = selected;
      _isAnswered = true;
    });

    bool isCorrect = selected.trim().toLowerCase() == correct.trim().toLowerCase();
    
    Future.delayed(600.ms, () {
      if (!mounted) return;
      if (isCorrect) {
        _hapticService.success();
        _soundService.playCorrect();
        setState(() => _isCorrect = true);
        context.read<VocabularyBloc>().add(SubmitAnswer(true));
      } else {
        _hapticService.error();
        _soundService.playWrong();
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
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'EMOJI EXPERT!',
            enableDoubleUp: true,
          );
        } else if (state is VocabularyGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<VocabularyBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is VocabularyLoaded) ? state.currentQuest : _lastQuest;
        if (quest == null && state is! VocabularyGameComplete) return const GameShimmerLoading();

        return VocabularyBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
          onHint: () => context.read<VocabularyBloc>().add(VocabularyHintUsed()),
          child: quest == null ? const SizedBox() : _buildChatInterface(quest, theme.primaryColor),
        );
      },
    );
  }

  Widget _buildChatInterface(VocabularyQuest quest, Color color) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
            children: [
              _buildSystemMessage("DECODE THE EMOJI SEQUENCE", color),
              SizedBox(height: 20.h),
              _buildStrangerMessage(quest.topicEmoji ?? "❓", color),
              if (_selectedOption != null) ...[
                SizedBox(height: 20.h),
                _buildUserMessage(_selectedOption!, color, _isCorrect),
              ],
              if (_isAnswered && _isCorrect == false) ...[
                SizedBox(height: 10.h),
                _buildSystemMessage("INCORRECT. TRY AGAIN.", Colors.redAccent),
              ],
            ],
          ),
        ),
        _buildOptions(quest.options ?? [], quest.correctAnswer ?? "", color),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildSystemMessage(String text, Color color) {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          text,
          style: GoogleFonts.shareTechMono(fontSize: 10.sp, color: color, letterSpacing: 1),
        ),
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildStrangerMessage(String emojis, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: 0.7.sw),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
            bottomRight: Radius.circular(20.r),
          ),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          emojis,
          style: TextStyle(fontSize: 40.sp),
        ),
      ),
    ).animate().slideX(begin: -0.2, duration: 400.ms).fadeIn();
  }

  Widget _buildUserMessage(String text, Color color, bool? isCorrect) {
    final bgColor = isCorrect == true ? Colors.green : (isCorrect == false ? Colors.red : color);
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: 0.7.sw),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: bgColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
            bottomLeft: Radius.circular(20.r),
          ),
          border: Border.all(color: bgColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                text,
                style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            if (isCorrect != null) ...[
              SizedBox(width: 8.w),
              Icon(
                isCorrect ? Icons.done_all_rounded : Icons.close_rounded,
                color: isCorrect ? Colors.greenAccent : Colors.redAccent,
                size: 16.r,
              ),
            ],
          ],
        ),
      ),
    ).animate().slideX(begin: 0.2, duration: 400.ms).fadeIn();
  }

  Widget _buildOptions(List<String> options, String correct, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Wrap(
        spacing: 10.w,
        runSpacing: 10.h,
        alignment: WrapAlignment.center,
        children: options.map((o) {
          final isSelected = _selectedOption == o;
          return ScaleButton(
            onTap: () => _submitAnswer(o, correct),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: isSelected ? color : color.withValues(alpha: 0.2)),
              ),
              child: Text(
                o,
                style: GoogleFonts.outfit(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2);
  }
}
