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
import 'package:voxai_quest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:voxai_quest/features/speaking/domain/entities/speaking_quest.dart';
import 'package:voxai_quest/features/speaking/presentation/bloc/speaking_bloc.dart';

class SpeakMissingWordScreen extends StatefulWidget {
  final int level;
  const SpeakMissingWordScreen({super.key, required this.level});

  @override
  State<SpeakMissingWordScreen> createState() => _SpeakMissingWordScreenState();
}

class _SpeakMissingWordScreenState extends State<SpeakMissingWordScreen> {
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
        gameType: GameSubtype.speakMissingWord,
        level: widget.level,
      ),
    );
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
        setState(() => _recognizedText = result);
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

    final SpeakingQuest quest = state.currentQuest;
    final targetText = (quest.missingWord ?? "").toLowerCase().replaceAll(
      RegExp(r'[^\w\s]'),
      '',
    );
    final utteredText = _recognizedText.toLowerCase().replaceAll(
      RegExp(r'[^\w\s]'),
      '',
    );

    bool isCorrect =
        utteredText == targetText || utteredText.contains(targetText);

    context.read<SpeakingBloc>().add(SubmitAnswer(isCorrect));
  }

  void _useHint() {
    _hapticService.selection();
    context.read<SpeakingBloc>().add(SpeakingHintUsed());
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
          title: 'Context Mastered!',
          description:
              'You earned ${state.xpEarned} XP and ${state.coinsEarned} Coins for filling in the linguistic gaps!',
        ),
            );
          } else if (state is SpeakingGameOver) {
            GameDialogHelper.showGameOver(
        context,
        title: 'Context Lost',
        description: 'The blank remained empty. Recharge and try again!',
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
                  gameType: GameSubtype.speakMissingWord,
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
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.05),
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

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
              child: Column(
                children: [
                  Text(
                    "CONTEXT SPEAK",
                    style: GoogleFonts.outfit(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: theme.primaryColor,
                    ),
                  ).animate().fadeIn(),
                  SizedBox(height: 8.h),
                  Text(
                    "Speak the missing word",
                    style: GoogleFonts.outfit(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      SizedBox(height: 20.h),
                      GlassTile(
                        padding: EdgeInsets.all(32.r),
                        borderRadius: BorderRadius.circular(28.r),
                        borderColor: theme.primaryColor.withValues(alpha: 0.3),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    quest.textToSpeak?.split('___').first ?? "",
                                style: GoogleFonts.outfit(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                  height: 1.5,
                                ),
                              ),
                              WidgetSpan(
                                child:
                                    Container(
                                          margin: EdgeInsets.symmetric(
                                            horizontal: 8.w,
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16.w,
                                            vertical: 4.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.primaryColor
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              8.r,
                                            ),
                                            border: Border.all(
                                              color: theme.primaryColor
                                                  .withValues(alpha: 0.5),
                                              width: 2,
                                            ),
                                          ),
                                          child: Text(
                                            " ? ",
                                            style: GoogleFonts.outfit(
                                              fontSize: 22.sp,
                                              fontWeight: FontWeight.w900,
                                              color: theme.primaryColor,
                                            ),
                                          ),
                                        )
                                        .animate(
                                          onPlay: (c) =>
                                              c.repeat(reverse: true),
                                        )
                                        .shimmer(
                                          duration: 2.seconds,
                                          color: theme.primaryColor.withValues(
                                            alpha: 0.2,
                                          ),
                                        ),
                              ),
                              TextSpan(
                                text:
                                    quest.textToSpeak?.split('___').last ?? "",
                                style: GoogleFonts.outfit(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 400.ms).scale(),
                      if (state.hintUsed)
                        Padding(
                          padding: EdgeInsets.only(top: 24.h),
                          child: Container(
                            padding: EdgeInsets.all(16.r),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: theme.primaryColor.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lightbulb_rounded,
                                  color: theme.primaryColor,
                                  size: 20.r,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  "Starts with '${quest.missingWord?[0].toUpperCase() ?? ""}'",
                                  style: GoogleFonts.outfit(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn().slideY(begin: 0.1),
                      SizedBox(height: 48.h),
                      if (_recognizedText.isNotEmpty)
                        Column(
                          children: [
                            Text(
                              "YOU SAID",
                              style: GoogleFonts.outfit(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w800,
                                color: theme.primaryColor.withValues(
                                  alpha: 0.6,
                                ),
                                letterSpacing: 2,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            GlassTile(
                              padding: EdgeInsets.all(20.r),
                              borderRadius: BorderRadius.circular(20.r),
                              color: theme.primaryColor.withValues(alpha: 0.1),
                              child: Text(
                                _recognizedText,
                                style: GoogleFonts.outfit(
                                  fontSize: 20.sp,
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.w800,
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
                          color: isDark ? Colors.white38 : Colors.black38,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 60.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        if (state.lastAnswerCorrect != null)
          ModernGameResultOverlay(
            isCorrect: state.lastAnswerCorrect!,
            title: state.lastAnswerCorrect! ? "BRILLIANT!" : "ALMOST!",
            subtitle: state.lastAnswerCorrect!
                ? "Perfect context analysis."
                : "The missing word was: ${quest.missingWord}",
            onContinue: () {
              setState(() {
                _recognizedText = '';
                _hasAnalyzed = false;
              });
              context.read<SpeakingBloc>().add(NextQuestion());
            },
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
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              used ? Icons.lightbulb_outline_rounded : Icons.lightbulb_rounded,
              color: used ? Colors.grey : primaryColor,
              size: 18.r,
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
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.4),
                blurRadius: _isListening ? 40 : 20,
              ),
            ],
          ),
          child: Icon(
            _isListening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
            color: Colors.white,
            size: 40.r,
          ),
        ),
      ),
    );
  }

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  

  
}
