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
  const ContextualUsageScreen({
    super.key, 
    required this.level, 
    this.gameType = GameSubtype.contextualUsage
  });

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
        final theme = LevelThemeHelper.getTheme('vocabulary', level: widget.level);
        final quest = (state is VocabularyLoaded) ? state.currentQuest : _lastQuest;
        final loadedState = state is VocabularyLoaded ? state : null;

        if (state is VocabularyLoading || (quest == null && state is! VocabularyGameComplete && state is! VocabularyError)) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            body: GameShimmerLoading(primaryColor: theme.primaryColor),
          );
        }

        _isAnswered = loadedState?.lastAnswerCorrect != null;
        _isCorrect = loadedState?.lastAnswerCorrect;
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        return VocabularyBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
          onHint: () => context.read<VocabularyBloc>().add(VocabularyHintUsed()),
          useScrolling: false,
          disablePadding: true,
          child: quest == null
              ? const SizedBox()
              : Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: GridPainter(
                          theme.primaryColor.withValues(
                            alpha: isDarkMode ? 0.05 : 0.03,
                          ),
                        ),
                      ),
                    ),
                    _buildUnfoldContent(quest, theme.primaryColor, isDarkMode),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildUnfoldContent(VocabularyQuest quest, Color color, bool isDark) {
    String baseSentence = quest.question ?? "";

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 60.h),
        Text(
          "USAGE UNFOLD",
          style: GoogleFonts.shareTechMono(
            fontSize: 11.sp,
            color: color,
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(duration: 800.ms).shimmer(duration: 2.seconds),

        SizedBox(height: 40.h),
        
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 0.8.sw,
                height: 180.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.05),
                ),
              ).animate(target: _isAnswered ? 1 : 0).scale(begin: const Offset(0.5, 0.5), end: const Offset(1.5, 1.5), curve: Curves.easeOutBack),

              AnimatedContainer(
                duration: 600.ms,
                curve: Curves.elasticOut,
                width: 0.88.sw,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(4.r),
                  border: Border.all(
                    color: color.withValues(alpha: _isAnswered ? 0.6 : 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: _isAnswered ? 0.3 : 0.05),
                      blurRadius: _isAnswered ? 40 : 15,
                      offset: Offset(0, _isAnswered ? 15 : 5),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      height: 1,
                      width: double.infinity,
                      color: color.withValues(alpha: 0.1),
                    ),
                    SizedBox(height: 20.h),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: _buildSentenceSpans(baseSentence, color, isDark),
                      ),
                    ).animate(target: _isAnswered ? 1 : 0)
                     .shimmer(duration: 1.5.seconds, color: color.withValues(alpha: 0.2))
                     .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05)),
                    SizedBox(height: 20.h),
                    Container(
                      height: 1,
                      width: double.infinity,
                      color: color.withValues(alpha: 0.1),
                    ),
                  ],
                ),
              ).animate(target: _isAnswered ? 1 : 0)
               .custom(
                 builder: (context, value, child) => Transform(
                   transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateX((1 - value) * 0.2),
                   alignment: Alignment.topCenter,
                   child: child,
                 ),
               ),
            ],
          ),
        ),

        SizedBox(height: 80.h),

        Wrap(
          spacing: 16.w, 
          runSpacing: 16.h,
          alignment: WrapAlignment.center,
          children: (quest.options ?? []).map((o) {
            final isSelected = _selectedOption == o;
            
            Color tileColor = isDark ? color.withValues(alpha: 0.1) : Colors.white;
            Color borderColor = color.withValues(alpha: 0.3);
            Color textColor = isDark ? Colors.white70 : Colors.black87;

            if (isSelected) {
              if (_isCorrect == true) {
                tileColor = Colors.green.withValues(alpha: 0.2);
                borderColor = Colors.green;
                textColor = isDark ? Colors.white : Colors.green.shade700;
              } else if (_isCorrect == false) {
                tileColor = Colors.red.withValues(alpha: 0.2);
                borderColor = Colors.red;
                textColor = isDark ? Colors.white : Colors.red.shade700;
              } else {
                tileColor = color.withValues(alpha: 0.3);
                borderColor = color;
                textColor = isDark ? Colors.white : color;
              }
            }

            return ScaleButton(
              onTap: () => _submitAnswer(o, quest.correctAnswer ?? ""),
              child: AnimatedContainer(
                duration: 300.ms,
                constraints: BoxConstraints(minWidth: 140.w),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                decoration: BoxDecoration(
                  color: tileColor,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: borderColor.withValues(alpha: 0.3),
                        blurRadius: 15,
                      ),
                  ],
                ),
                child: Text(
                  o.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, curve: Curves.easeOutCubic),
        SizedBox(height: 40.h),
      ],
    ),);
  }

  List<TextSpan> _buildSentenceSpans(String sentence, Color color, bool isDark) {
    final parts = sentence.split("_____");
    List<TextSpan> spans = [];

    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(
        text: parts[i],
        style: GoogleFonts.outfit(
          fontSize: 19.sp,
          fontWeight: FontWeight.w400,
          color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
          height: 1.5,
        ),
      ));

      if (i < parts.length - 1) {
        spans.add(TextSpan(
          text: _selectedOption ?? " ________ ",
          style: GoogleFonts.outfit(
            fontSize: 20.sp,
            fontWeight: FontWeight.w900,
            color: _isAnswered
                ? (_isCorrect == true ? Colors.greenAccent : Colors.redAccent)
                : color,
            decoration: _isAnswered ? TextDecoration.none : TextDecoration.underline,
          ),
        ));
      }
    }
    return spans;
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  GridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 0.5;
    const step = 40.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
