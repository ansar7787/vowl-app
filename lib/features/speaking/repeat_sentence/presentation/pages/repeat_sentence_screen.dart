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
import 'package:voxai_quest/core/utils/ad_service.dart';
import 'package:voxai_quest/core/utils/haptic_service.dart';
import 'package:voxai_quest/core/utils/injection_container.dart' as di;
import 'package:voxai_quest/core/utils/sound_service.dart';
import 'package:voxai_quest/core/utils/speech_service.dart';
import 'package:voxai_quest/core/utils/hint_helper.dart';
import 'package:voxai_quest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:voxai_quest/features/speaking/presentation/bloc/speaking_bloc.dart';

// Main screen for Repeat Sentence game
class RepeatSentenceScreen extends StatefulWidget {
  final int level;
  const RepeatSentenceScreen({super.key, required this.level});

  @override
  State<RepeatSentenceScreen> createState() => _RepeatSentenceScreenState();
}

class _RepeatSentenceScreenState extends State<RepeatSentenceScreen> {
  final _speechService = di.sl<SpeechService>();
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  bool _isListening = false;
  String _recognizedText = '';
  bool _hasAnalyzed = false;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _speechService.initializeStt();
    context.read<SpeakingBloc>().add(
      FetchSpeakingQuests(
        gameType: GameSubtype.repeatSentence,
        level: widget.level,
      ),
    );
    // Pre-load ads
    di.sl<AdService>().loadRewardedAd();
  }

  @override
  void dispose() {
    _speechService.stop();
    super.dispose();
  }

  void _playSound(String text) async {
    _hapticService.selection();
    await _speechService.speak(text, rate: 0.45);
  }

  void _startListening() {
    _hapticService.success();
    setState(() {
      _isListening = true;
      _recognizedText = '';
      _hasAnalyzed = false;
    });

    _speechService.listen(
      onResult: (result) {
        setState(() {
          _recognizedText = result;
        });
      },
      onDone: () {
        if (mounted) {
          setState(() => _isListening = false);
          _analyzeSpeech();
        }
      },
    );
  }

  void _stopListening() async {
    _hapticService.light();
    await _speechService.stop();
    setState(() => _isListening = false);
    _analyzeSpeech();
  }

  void _analyzeSpeech() {
    if (_hasAnalyzed || _recognizedText.isEmpty) return;
    _hasAnalyzed = true;

    final state = context.read<SpeakingBloc>().state;
    if (state is! SpeakingLoaded) return;

    final targetText = (state.currentQuest.textToSpeak ?? "")
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '');
    final utteredText = _recognizedText.toLowerCase().replaceAll(
      RegExp(r'[^\w\s]'),
      '',
    );

    bool isCorrect =
        utteredText == targetText ||
        utteredText.contains(targetText) ||
        (targetText.contains(utteredText) &&
            utteredText.length > targetText.length * 0.7);

    context.read<SpeakingBloc>().add(SubmitAnswer(isCorrect));
  }

  void _useHint() {
    HintHelper.useHint(
      context: context,
      onHintAction: () {
        context.read<SpeakingBloc>().add(SpeakingHintUsed());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme(
      'speaking',
      level: widget.level,
      isDark: isDark,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocConsumer<SpeakingBloc, SpeakingState>(
        listener: (context, state) {
          if (state is SpeakingGameComplete) {
            setState(() => _showConfetti = true);
            final isPremium =
                context.read<AuthBloc>().state.user?.isPremium ?? false;
            di.sl<AdService>().showInterstitialAd(
              isPremium: isPremium,
              onDismissed: () => GameDialogHelper.showCompletion(
          context,
          xp: state.xpEarned,
          coins: state.coinsEarned,
          title: 'Vocal Mastery!',
          description:
              'You earned ${state.xpEarned} XP and ${state.coinsEarned} Coins for your sharp pronunciation!',
          enableDoubleUp: true,
          popResult: true,
        ),
            );
          } else if (state is SpeakingGameOver) {
            GameDialogHelper.showGameOver(
        context,
        title: 'Lost Your Rhythm?',
        description: 'Your voice needs a short break. Try again soon!',
      );
          }
        },
        builder: (context, state) {
          if (state is SpeakingLoading || state is SpeakingInitial) {
            return const GameShimmerLoading();
          }
          if (state is SpeakingLoaded) {
            return Stack(
              children: [
                MeshGradientBackground(colors: theme.backgroundColors),
                _buildGameUI(context, state, isDark, theme),
              ],
            );
          }
          if (state is SpeakingError) {
            return QuestUnavailableScreen(
              message: state.message,
              onRetry: () => context.read<SpeakingBloc>().add(
                FetchSpeakingQuests(
                  gameType: GameSubtype.repeatSentence,
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
    SpeakingLoaded state,
    bool isDark,
    ThemeResult theme,
  ) {
    final quest = state.currentQuest;
    final progress = (state.currentIndex + 1) / state.quests.length;

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
                            : Colors.black12,
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
                    Text(
                      theme.title,
                      style: GoogleFonts.outfit(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                        color: theme.primaryColor,
                      ),
                    ).animate().fadeIn(),
                    SizedBox(height: 8.h),
                    Text(
                      "Listen and Repeat",
                      style: GoogleFonts.outfit(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                    SizedBox(height: 48.h),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated Sonic Rings
                        ...List.generate(3, (index) {
                          return Container(
                                width: 160.r + (index * 40),
                                height: 160.r + (index * 40),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.primaryColor.withValues(
                                      alpha: 0.1,
                                    ),
                                    width: 2,
                                  ),
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat())
                              .scale(
                                duration: (1000 + (index * 500)).ms,
                                begin: const Offset(1, 1),
                                end: const Offset(1.2, 1.2),
                              )
                              .fadeOut(duration: (1000 + (index * 500)).ms);
                        }),
                        ScaleButton(
                          onTap: () => _playSound(quest.textToSpeak ?? ""),
                          child: GlassTile(
                            borderRadius: BorderRadius.circular(50.r),
                            padding: EdgeInsets.all(32.r),
                            borderColor: theme.primaryColor.withValues(
                              alpha: 0.3,
                            ),
                            child: Icon(
                              Icons.volume_up_rounded,
                              size: 56.r,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 400.ms).scale(),
                    SizedBox(height: 32.h),
                    Text(
                      "TARGET PHRASE",
                      style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: theme.primaryColor.withValues(alpha: 0.6),
                        letterSpacing: 2,
                      ),
                    ).animate().fadeIn(delay: 600.ms),
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        quest.textToSpeak ?? "",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1),
                    SizedBox(height: 48.h),
                    if (_recognizedText.isNotEmpty)
                      Column(
                        children: [
                          Text(
                            "YOUR VOICE",
                            style: GoogleFonts.outfit(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              color: theme.primaryColor.withValues(alpha: 0.6),
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          GlassTile(
                            borderRadius: BorderRadius.circular(24.r),
                            padding: EdgeInsets.all(24.r),
                            color: theme.primaryColor.withValues(alpha: 0.05),
                            child: Text(
                              _recognizedText,
                              style: GoogleFonts.outfit(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w800,
                                color: theme.primaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ).animate().fadeIn().slideY(begin: 0.1),
                    SizedBox(height: 40.h),
                    _buildMicButton(theme.primaryColor),
                    SizedBox(height: 24.h),
                    Text(
                      _isListening ? "RECORDING..." : "PRESS & HOLD TO SPEAK",
                      style: GoogleFonts.outfit(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                    SizedBox(height: 60.h),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (state.lastAnswerCorrect != null)
          ModernGameResultOverlay(
            isCorrect: state.lastAnswerCorrect!,
            title: state.lastAnswerCorrect!
                ? "VOCAL MASTERY!"
                : "KEEP PRACTICING!",
            onContinue: () {
              setState(() {
                _recognizedText = '';
                _hasAnalyzed = false;
              });
              context.read<SpeakingBloc>().add(NextQuestion());
            },
            primaryColor: theme.primaryColor,
            recognizedText: _recognizedText,
            targetText: quest.textToSpeak,
            showHint: state.hintUsed,
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

  Widget _buildHintButton(bool used, Color primaryColor) {
    return ScaleButton(
      onTap: used ? null : _useHint,
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

  Widget _buildMicButton(Color primaryColor) {
    return AnimatedContainer(
      duration: 300.ms,
      padding: EdgeInsets.all(_isListening ? 12.r : 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: primaryColor.withValues(alpha: _isListening ? 0.3 : 0),
          width: 4,
        ),
      ),
      child: GestureDetector(
        onLongPressStart: (_) => _startListening(),
        onLongPressEnd: (_) => _stopListening(),
        child: Container(
          width: 90.r,
          height: 90.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.4),
                blurRadius: _isListening ? 40 : 20,
                spreadRadius: _isListening ? 10 : 0,
              ),
            ],
          ),
          child:
              Icon(
                    _isListening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 40.r,
                  )
                  .animate(target: _isListening ? 1 : 0)
                  .scale(duration: 200.ms)
                  .shimmer(duration: 1000.ms, color: Colors.white24),
        ),
      ),
    );
  }
}
