import 'dart:async';
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
import 'package:voxai_quest/core/presentation/widgets/reading/book_streak.dart';
import 'package:voxai_quest/core/presentation/widgets/scale_button.dart';
import 'package:voxai_quest/core/presentation/widgets/shimmer_loading.dart';
import 'package:voxai_quest/core/utils/ad_service.dart';
import 'package:voxai_quest/core/utils/haptic_service.dart';
import 'package:voxai_quest/core/utils/injection_container.dart' as di;
import 'package:voxai_quest/core/utils/sound_service.dart';
import 'package:voxai_quest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:voxai_quest/features/reading/presentation/bloc/reading_bloc.dart';

class ReadingSpeedScreen extends StatefulWidget {
  final int level;
  const ReadingSpeedScreen({super.key, required this.level});

  @override
  State<ReadingSpeedScreen> createState() => _ReadingSpeedScreenState();
}

class _ReadingSpeedScreenState extends State<ReadingSpeedScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  int? _selectedOptionIndex;
  bool _isReadingPhase = true;
  DateTime? _startTime;
  int _timeTakenMs = 0;
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    context.read<ReadingBloc>().add(
      FetchReadingQuests(
        gameType: GameSubtype.readingSpeedCheck,
        level: widget.level,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_startTime != null) return;
    _startTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
    });
  }

  void _finishReading() {
    _hapticService.success();
    _timer?.cancel();
    if (_startTime != null) {
      _timeTakenMs = DateTime.now().difference(_startTime!).inMilliseconds;
    }
    setState(() => _isReadingPhase = false);
  }

  void _submitAnswer(int index, int correctIndex) {
    if (_selectedOptionIndex != null) return;
    _hapticService.selection();
    setState(() => _selectedOptionIndex = index);

    bool isCorrect = (index == correctIndex);
    if (isCorrect) {
      _soundService.playCorrect();
    } else {
      _soundService.playWrong();
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<ReadingBloc>().add(SubmitAnswer(isCorrect));
      }
    });
  }

  int _calculateWpm(String text) {
    if (_timeTakenMs == 0) return 0;
    int wordCount = text
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    double minutes = _timeTakenMs / 60000.0;
    return (wordCount / minutes).round();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocConsumer<ReadingBloc, ReadingState>(
        listener: (context, state) {
          if (state is ReadingGameComplete) {
            setState(() => _showConfetti = true);
            final isPremium =
                context.read<AuthBloc>().state.user?.isPremium ?? false;
            di.sl<AdService>().showInterstitialAd(
              isPremium: isPremium,
              onDismissed: () => GameDialogHelper.showCompletion(
          context,
          xp: state.xpEarned,
          coins: state.coinsEarned,
          title: 'Speedster!',
          description:
              'You earned ${state.xpEarned} XP and ${state.coinsEarned} Coins for your blink-of-an-eye reading!',
        ),
            );
          } else if (state is ReadingGameOver) {
            GameDialogHelper.showGameOver(
        context,
        title: 'Time Paused',
        description: 'Try to read accurately while maintaining speed!',
        onRestore: () => context.read<ReadingBloc>().add(RestoreLife()),
      );
          } else if (state is ReadingLoaded &&
              state.lastAnswerCorrect == null) {
            setState(() {
              _selectedOptionIndex = null;
              _isReadingPhase = true;
              _startTime = null;
              _timeTakenMs = 0;
              _elapsedSeconds = 0;
            });
          }
        },
        builder: (context, state) {
          if (state is ReadingLoading || state is ReadingInitial) {
            return const GameShimmerLoading();
          }
          if (state is ReadingLoaded) {
            final theme = LevelThemeHelper.getTheme(
              'reading',
              level: widget.level,
            );
            if (_isReadingPhase && _startTime == null) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _startTimer(),
              );
            }
            return Stack(
              children: [
                MeshGradientBackground(colors: theme.backgroundColors),
                BookStreak(color: theme.primaryColor),
                _buildGameUI(context, state, isDark, theme),
              ],
            );
          }
          if (state is ReadingError) {
            return QuestUnavailableScreen(
              message: state.message,
              onRetry: () => context.read<ReadingBloc>().add(
                FetchReadingQuests(
                  gameType: GameSubtype.readingSpeedCheck,
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
    ReadingLoaded state,
    bool isDark,
    ThemeResult theme,
  ) {
    final quest = state.currentQuest;
    final progress = (state.currentIndex + 1) / state.quests.length;
    final passage = quest.passage ?? "";
    final question = quest.question ?? "";
    final options = quest.options ?? [];
    final correctIndex = quest.correctAnswerIndex ?? 0;

    return Stack(
      children: [
        Column(
          children: [
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
                            : Colors.black.withValues(alpha: 0.05),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  _buildHintButton(state.hintUsed, theme.primaryColor),
                  SizedBox(width: 12.w),
                  _buildHeartCount(state.livesRemaining),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    SizedBox(height: 10.h),
                    if (_isReadingPhase) ...[
                      Text(
                        theme.title,
                        style: GoogleFonts.outfit(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
                          color: theme.primaryColor,
                        ),
                      ).animate().fadeIn(),
                      SizedBox(height: 16.h),
                      _buildTimerUI(isDark, theme.primaryColor),
                      SizedBox(height: 24.h),
                      Text(
                        "Read clearly and quickly!",
                        style: GoogleFonts.outfit(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 32.h),
                      _buildPassageCard(passage, isDark, theme.primaryColor),
                      SizedBox(height: 48.h),
                      _buildFinishButton(theme.primaryColor),
                    ] else ...[
                      _buildSpeedStats(passage, isDark, theme.primaryColor),
                      SizedBox(height: 40.h),
                      Text(
                        question,
                        style: GoogleFonts.outfit(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 32.h),
                      ...List.generate(
                        options.length,
                        (i) => _buildOption(
                          i,
                          options[i],
                          correctIndex,
                          state,
                          isDark,
                          theme.primaryColor,
                        ),
                      ),
                    ],
                    SizedBox(height: 100.h),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (state.lastAnswerCorrect != null)
          ModernGameResultOverlay(
            isCorrect: state.lastAnswerCorrect!,
            title: state.lastAnswerCorrect! ? "SPEEDY SUCCESS!" : "KEEP AT IT!",
            subtitle: quest.explanation ?? "Connectivity skills expanding!",
            onContinue: () => context.read<ReadingBloc>().add(NextQuestion()),
            primaryColor: theme.primaryColor,
          ),
        if (_showConfetti) const GameConfetti(),
      ],
    );
  }

  Widget _buildTimerUI(bool isDark, Color primaryColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, color: primaryColor, size: 24.r),
          SizedBox(width: 10.w),
          Text(
            "00:${_elapsedSeconds.toString().padLeft(2, '0')}",
            style: GoogleFonts.sourceCodePro(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
    ).animate().scale();
  }

  Widget _buildPassageCard(String passage, bool isDark, Color primaryColor) {
    return GlassTile(
      borderRadius: BorderRadius.circular(32.r),
      padding: EdgeInsets.all(28.r),
      borderColor: primaryColor.withValues(alpha: 0.2),
      color: isDark
          ? Colors.white.withValues(alpha: 0.03)
          : Colors.black.withValues(alpha: 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4.w,
                height: 24.h,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                "PASSAGE",
                style: GoogleFonts.outfit(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Text(
            passage,
            style: GoogleFonts.spectral(
              fontSize: 19.sp,
              height: 1.7,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.black87,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildFinishButton(Color primaryColor) {
    return ScaleButton(
      onTap: _finishReading,
      child: Container(
        width: double.infinity,
        height: 70.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          gradient: LinearGradient(
            colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: Text(
            "DONE READING",
            style: GoogleFonts.outfit(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildSpeedStats(String passage, bool isDark, Color primaryColor) {
    final wpm = _calculateWpm(passage);
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _statItem(
            "TIME",
            "${(_timeTakenMs / 1000).toStringAsFixed(1)}s",
            primaryColor,
          ),
          SizedBox(width: 20.w),
          Container(
            width: 1,
            height: 40.h,
            color: primaryColor.withValues(alpha: 0.2),
          ),
          SizedBox(width: 20.w),
          _statItem("SPEED", "$wpm WPM", primaryColor),
        ],
      ),
    ).animate().scale();
  }

  Widget _statItem(String label, String value, Color primaryColor) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
            color: primaryColor,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 22.sp,
            fontWeight: FontWeight.w900,
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildOption(
    int index,
    String text,
    int correctIndex,
    ReadingLoaded state,
    bool isDark,
    Color primaryColor,
  ) {
    final isSelected = _selectedOptionIndex == index;
    final isCorrect = index == correctIndex;
    final lastResult = state.lastAnswerCorrect;

    Color? cardColor;
    Color? borderColor;

    if (lastResult != null) {
      if (isCorrect) {
        cardColor = const Color(0xFF10B981);
        borderColor = cardColor;
      } else if (isSelected) {
        cardColor = const Color(0xFFF43F5E);
        borderColor = cardColor;
      }
    } else if (isSelected) {
      cardColor = primaryColor.withValues(alpha: 0.2);
      borderColor = primaryColor;
    } else if (state.hintUsed && isCorrect) {
      borderColor = primaryColor;
    }

    return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: ScaleButton(
            onTap: () => _submitAnswer(index, correctIndex),
            child: GlassTile(
              borderRadius: BorderRadius.circular(20.r),
              padding: EdgeInsets.all(20.r),
              color: cardColor,
              borderColor: borderColor,
              child: Row(
                children: [
                  Container(
                    width: 32.r,
                    height: 32.r,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white24
                          : primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + index),
                        style: GoogleFonts.outfit(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : primaryColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Text(
                      text,
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  if (state.hintUsed && isCorrect && lastResult == null)
                    Icon(
                          Icons.lightbulb_rounded,
                          color: primaryColor,
                          size: 20.r,
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 1500.ms),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 100 * index))
        .slideX(begin: 0.1);
  }

  

  

  Widget _buildHintButton(bool used, Color primaryColor) {
    return ScaleButton(
      onTap: used
          ? null
          : () => context.read<ReadingBloc>().add(ReadingHintUsed()),
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
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: used ? Colors.grey : primaryColor,
              ),
            ),
          ],
        ),
      ),
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
}
