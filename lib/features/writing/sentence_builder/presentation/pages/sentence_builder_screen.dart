import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voxai_quest/core/domain/entities/game_quest.dart';
import 'package:voxai_quest/core/presentation/pages/quest_unavailable_screen.dart';
import 'package:voxai_quest/core/presentation/themes/level_theme_helper.dart';
import 'package:voxai_quest/core/presentation/widgets/game_confetti.dart';
import 'package:voxai_quest/core/presentation/widgets/glass_tile.dart';
import 'package:voxai_quest/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:voxai_quest/core/presentation/widgets/game_dialog_helper.dart';
import 'package:voxai_quest/core/presentation/widgets/modern_game_result_overlay.dart';
import 'package:voxai_quest/core/presentation/widgets/scale_button.dart';
import 'package:voxai_quest/core/presentation/widgets/shimmer_loading.dart';
import 'package:voxai_quest/core/presentation/widgets/writing/ink_streak.dart';
import 'package:voxai_quest/core/utils/ad_service.dart';
import 'package:voxai_quest/core/utils/haptic_service.dart';
import 'package:voxai_quest/core/utils/injection_container.dart' as di;
import 'package:voxai_quest/core/utils/sound_service.dart';
import 'package:voxai_quest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:voxai_quest/features/writing/presentation/bloc/writing_bloc.dart';

class SentenceBuilderScreen extends StatefulWidget {
  final int level;
  const SentenceBuilderScreen({super.key, required this.level});

  @override
  State<SentenceBuilderScreen> createState() => _SentenceBuilderScreenState();
}

class _SentenceBuilderScreenState extends State<SentenceBuilderScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final List<String> _selectedWords = [];
  List<String>? _remainingWords;
  bool _hasSubmitted = false;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    context.read<WritingBloc>().add(
      FetchWritingQuests(
        gameType: GameSubtype.sentenceBuilder,
        level: widget.level,
      ),
    );
  }

  void _initWordsIfNeeded(List<String> shuffled) {
    _remainingWords ??= List.from(shuffled);
  }

  void _addWord(String word, int index) {
    if (_hasSubmitted) {
      return;
    }
    _hapticService.selection();
    setState(() {
      _selectedWords.add(word);
      _remainingWords!.removeAt(index);
    });
  }

  void _removeWord(String word, int index) {
    if (_hasSubmitted) {
      return;
    }
    _hapticService.selection();
    setState(() {
      _remainingWords!.add(word);
      _selectedWords.removeAt(index);
    });
  }

  void _submitAnswer(String? correctSentence) {
    if (_hasSubmitted || _selectedWords.isEmpty) {
      return;
    }
    _hapticService.selection();
    setState(() => _hasSubmitted = true);

    final userSentence = _selectedWords.join(' ').trim();
    final target = (correctSentence ?? "").trim();

    bool isCorrect =
        userSentence.toLowerCase().replaceAll(RegExp(r'[.!?]'), '') ==
        target.toLowerCase().replaceAll(RegExp(r'[.!?]'), '');

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<WritingBloc>().add(SubmitAnswer(isCorrect));
      }
    });
  }

  void _useHint(String correctSentence) {
    _hapticService.selection();
    context.read<WritingBloc>().add(WritingHintUsed());

    // Auto-select the next correct word if hint is used
    final targetWords = correctSentence.split(' ');
    if (_selectedWords.length < targetWords.length) {
      final nextWord = targetWords[_selectedWords.length];
      final indexInRemaining =
          _remainingWords?.indexWhere(
            (w) =>
                w.toLowerCase().replaceAll(RegExp(r'[.!?]'), '') ==
                nextWord.toLowerCase().replaceAll(RegExp(r'[.!?]'), ''),
          ) ??
          -1;

      if (indexInRemaining != -1) {
        _addWord(_remainingWords![indexInRemaining], indexInRemaining);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme(
      'writing',
      level: widget.level,
      isDark: isDark,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocConsumer<WritingBloc, WritingState>(
        listener: (context, state) {
          if (state is WritingGameComplete) {
            setState(() => _showConfetti = true);
            final isPremium =
                context.read<AuthBloc>().state.user?.isPremium ?? false;
            di.sl<AdService>().showInterstitialAd(
              isPremium: isPremium,
              onDismissed: () => GameDialogHelper.showCompletion(
                context,
                xp: state.xpEarned,
                coins: state.coinsEarned,
                title: 'Sentence Architect!',
                description:
                    'You earned ${state.xpEarned} XP and ${state.coinsEarned} Coins!',
                enableDoubleUp: true,
              ),
            );
          } else if (state is WritingGameOver) {
            GameDialogHelper.showGameOver(
              context,
              title: 'Construction Halted',
              description:
                  'Your sentence lacked support. Recharge and try again!',
            );
          } else if (state is WritingLoaded &&
              state.lastAnswerCorrect == null) {
            setState(() {
              _hasSubmitted = false;
              _selectedWords.clear();
              _remainingWords = null;
            });
          }
        },
        builder: (context, state) {
          if (state is WritingLoading || state is WritingInitial) {
            return const GameShimmerLoading();
          }
          if (state is WritingLoaded) {
            return Stack(
              children: [
                MeshGradientBackground(colors: theme.backgroundColors),
                InkStreak(color: theme.primaryColor),
                _buildGameUI(context, state, isDark, theme),
              ],
            );
          }
          if (state is WritingError) {
            return QuestUnavailableScreen(
              message: state.message,
              onRetry: () => context.read<WritingBloc>().add(
                FetchWritingQuests(
                  gameType: GameSubtype.sentenceBuilder,
                  level: widget.level,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildGameUI(
    BuildContext context,
    WritingLoaded state,
    bool isDark,
    ThemeResult theme,
  ) {
    final quest = state.currentQuest;
    final progress = (state.currentIndex + 1) / state.quests.length;
    _initWordsIfNeeded(quest.shuffledWords ?? []);

    return Stack(
      children: [
        Column(
          children: [
            // Modern Header
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 60.h, 20.w, 10.h),
              child: Row(
                children: [
                  ScaleButton(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black12,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 24.r,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.r),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 14.h,
                        backgroundColor: isDark
                            ? Colors.white10
                            : Colors.black12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  _buildHintButton(
                    state.hintUsed,
                    quest.correctSentence ?? "",
                    theme.primaryColor,
                  ),
                  SizedBox(width: 12.w),
                  _buildHeartCount(state.livesRemaining),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  SizedBox(height: 20.h),
                  Text(
                    "MASTER BUILDER",
                    style: GoogleFonts.outfit(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: theme.primaryColor,
                    ),
                  ).animate().fadeIn(),
                  SizedBox(height: 12.h),
                  Text(
                    quest.instruction,
                    style: GoogleFonts.outfit(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 200.ms),

                  SizedBox(height: 48.h),

                  // Assembly Area
                  GlassTile(
                    borderRadius: BorderRadius.circular(32.r),
                    padding: EdgeInsets.all(24.r),
                    borderColor: _hasSubmitted
                        ? (state.lastAnswerCorrect == true
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF43F5E))
                        : theme.primaryColor.withValues(alpha: 0.1),
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.black.withValues(alpha: 0.02),
                    child: Container(
                      constraints: BoxConstraints(minHeight: 160.h),
                      width: double.infinity,
                      child: Wrap(
                        spacing: 10.w,
                        runSpacing: 14.h,
                        children: List.generate(
                          _selectedWords.length,
                          (index) => _buildWordChip(
                            _selectedWords[index],
                            true,
                            index,
                            isDark,
                            theme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn().slideY(begin: 0.05),

                  if (_selectedWords.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 40.h),
                      child: Text(
                        "Tap words below to build...",
                        style: GoogleFonts.outfit(
                          fontSize: 16.sp,
                          color: isDark ? Colors.white24 : Colors.black26,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                  SizedBox(height: 60.h),

                  // Options Area
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12.w,
                    runSpacing: 16.h,
                    children: List.generate(
                      _remainingWords!.length,
                      (index) => _buildWordChip(
                        _remainingWords![index],
                        false,
                        index,
                        isDark,
                        theme.primaryColor,
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                ],
              ),
            ),

            const Spacer(),

            if (!_hasSubmitted)
              Padding(
                padding: EdgeInsets.all(24.r),
                child: SizedBox(
                  width: double.infinity,
                  height: 60.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      elevation: 8,
                      shadowColor: theme.primaryColor.withValues(alpha: 0.4),
                    ),
                    onPressed: _selectedWords.isEmpty
                        ? null
                        : () => _submitAnswer(quest.correctSentence),
                    child: Text(
                      "BUILD SENTENCE",
                      style: GoogleFonts.outfit(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ).animate().slideY(begin: 0.5),

            SizedBox(height: 20.h),
          ],
        ),

        if (state.lastAnswerCorrect != null)
          ModernGameResultOverlay(
            isCorrect: state.lastAnswerCorrect!,
            title: state.lastAnswerCorrect! ? "STURDY!" : "TWEAK IT!",
            subtitle: "Correct Sentence: ${quest.correctSentence}",
            onContinue: () => context.read<WritingBloc>().add(NextQuestion()),
            primaryColor: theme.primaryColor,
          ),

        if (_showConfetti) const GameConfetti(),
      ],
    );
  }

  Widget _buildHeartCount(int lives) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.pink.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 20.r),
          SizedBox(width: 6.w),
          Text(
            "$lives",
            style: GoogleFonts.outfit(
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              color: Colors.pinkAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintButton(
    bool used,
    String correctSentence,
    Color primaryColor,
  ) {
    return ScaleButton(
      onTap: used ? null : () => _useHint(correctSentence),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: used
              ? Colors.grey.withValues(alpha: 0.1)
              : primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: used
                ? Colors.grey.withValues(alpha: 0.3)
                : primaryColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              used ? Icons.lightbulb_outline_rounded : Icons.lightbulb_rounded,
              color: used ? Colors.grey : primaryColor,
              size: 20.r,
            ),
            SizedBox(width: 6.w),
            Text(
              "HINT",
              style: GoogleFonts.outfit(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: used ? Colors.grey : primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordChip(
    String word,
    bool isSelected,
    int index,
    bool isDark,
    Color primaryColor,
  ) {
    return ScaleButton(
      onTap: () =>
          isSelected ? _removeWord(word, index) : _addWord(word, index),
      child: GlassTile(
        borderRadius: BorderRadius.circular(16.r),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
        color: isSelected
            ? primaryColor.withValues(alpha: 0.1)
            : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03)),
        borderColor: isSelected
            ? primaryColor
            : primaryColor.withValues(alpha: 0.1),
        child: Text(
          word,
          style: GoogleFonts.spectral(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
            color: isSelected
                ? primaryColor
                : (isDark
                      ? Colors.white.withValues(alpha: 0.9)
                      : Colors.black87),
          ),
        ),
      ),
    );
  }
}
