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

class CollocationsScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const CollocationsScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.collocations,
  });

  @override
  State<CollocationsScreen> createState() => _CollocationsScreenState();
}

class _CollocationsScreenState extends State<CollocationsScreen>
    with TickerProviderStateMixin {
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
    context.read<VocabularyBloc>().add(
      FetchVocabularyQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _submitAnswer(String selected, String correct) {
    if (_isAnswered) return;

    setState(() {
      _selectedOption = selected;
      _isAnswered = true;
    });

    bool isCorrect =
        selected.trim().toLowerCase() == correct.trim().toLowerCase();

    Future.delayed(400.ms, () {
      if (!mounted) return;

      if (isCorrect) {
        _hapticService.success();
        _soundService.playCorrect();
      } else {
        _hapticService.error();
        _soundService.playWrong();
      }

      setState(() => _isCorrect = isCorrect);
      context.read<VocabularyBloc>().add(SubmitAnswer(isCorrect));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: (context, state) {
        if (state is VocabularyLoaded) {
          if (state.currentIndex != _lastProcessedIndex ||
              (_isAnswered && state.lastAnswerCorrect == null)) {
            setState(() {
              _lastQuest = state.currentQuest;
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedOption = null;
            });
          }
          if (state.lastAnswerCorrect != null && _isCorrect == null) {
            setState(() => _isCorrect = state.lastAnswerCorrect);
          }
        }
        if (state is VocabularyGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'PAIR MASTER!',
            enableDoubleUp: true,
          );
        } else if (state is VocabularyGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<VocabularyBloc>().add(RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final theme = LevelThemeHelper.getTheme(
          'vocabulary',
          level: widget.level,
        );

        if (state is VocabularyLoading ||
            (state is! VocabularyGameComplete &&
                state is! VocabularyLoaded &&
                state is! VocabularyError)) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            body: GameShimmerLoading(primaryColor: theme.primaryColor),
          );
        }

        final quest = (state is VocabularyLoaded)
            ? state.currentQuest
            : _lastQuest;

        return VocabularyBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () {
            final currentState = context.read<VocabularyBloc>().state;
            if (currentState is VocabularyLoaded &&
                !currentState.isFinalFailure &&
                _isCorrect == false) {
              setState(() {
                _isAnswered = false;
                _isCorrect = null;
                _selectedOption = null;
              });
            } else {
              context.read<VocabularyBloc>().add(NextQuestion());
            }
          },
          onHint: () =>
              context.read<VocabularyBloc>().add(VocabularyHintUsed()),
          useScrolling: true,
          child: quest == null
              ? const SizedBox()
              : _buildPairPopGame(
                  quest,
                  theme.primaryColor,
                  isDark,
                  (state is VocabularyLoaded) ? state.isFinalFailure : false,
                ),
        );
      },
    );
  }

  Widget _buildPairPopGame(
    VocabularyQuest quest,
    Color color,
    bool isDark,
    bool isFinalFailure,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 10.h),
        _buildInstruction(color, isDark),
        SizedBox(height: 30.h),

        // Anchor Word Bubble
        Center(child: _buildAnchorBubble(quest.word ?? "", color, isDark)),

        SizedBox(height: 40.h),

        // Options Bubbles
        Wrap(
          spacing: 20.w,
          runSpacing: 40.h,
          alignment: WrapAlignment.center,
          children: (quest.options ?? []).asMap().entries.map((entry) {
            return _buildOptionBubble(
              entry.value,
              quest.correctAnswer ?? "",
              color,
              isDark,
              isFinalFailure,
              entry.key,
            );
          }).toList(),
        ),
        SizedBox(height: 60.h),
      ],
    );
  }

  Widget _buildInstruction(Color color, bool isDark) {
    return Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isDark
                ? color.withValues(alpha: 0.1)
                : color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            "FUSE THE COLLOCATION PAIR",
            textAlign: TextAlign.center,
            style: GoogleFonts.shareTechMono(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1.5,
            ),
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 2.seconds);
  }

  Widget _buildAnchorBubble(String text, Color color, bool isDark) {
    return Container(
          padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 25.h),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(40.r),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 25,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Text(
            text.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 28.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: -5, end: 5, duration: 2.seconds, curve: Curves.easeInOut);
  }

  Widget _buildOptionBubble(
    String text,
    String correct,
    Color color,
    bool isDark,
    bool isFinalFailure,
    int index,
  ) {
    final isSelected = _selectedOption == text;
    final showCorrect =
        (_isAnswered && _isCorrect == true && text == correct) ||
        (_isAnswered && isFinalFailure && text == correct);
    final showWrong = _isAnswered && isSelected && _isCorrect == false;

    Color bubbleColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);
    Color borderColor = color.withValues(alpha: 0.3);
    Color textColor = isDark ? Colors.white : Colors.black87;

    if (showCorrect) {
      bubbleColor = Colors.green.withValues(alpha: 0.2);
      borderColor = Colors.green;
      textColor = Colors.green;
    } else if (showWrong) {
      bubbleColor = Colors.red.withValues(alpha: 0.2);
      borderColor = Colors.red;
      textColor = Colors.red;
    } else if (isSelected) {
      bubbleColor = color.withValues(alpha: 0.2);
      borderColor = color;
      textColor = color;
    }

    Widget bubble = GestureDetector(
          onTap: () {
            if (!_isAnswered) {
              _hapticService.light();
              _submitAnswer(text, correct);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: 130.w,
            height: 130.w,
            decoration: BoxDecoration(
              color: bubbleColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor,
                width: isSelected || showCorrect || showWrong ? 3 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: showCorrect || isSelected 
                      ? borderColor.withValues(alpha: 0.3) 
                      : Colors.transparent,
                  blurRadius: showCorrect || isSelected ? 15 : 0,
                  spreadRadius: showCorrect || isSelected ? 2 : 0,
                ),
              ],
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(15.r),
                child: Text(
                  text.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        );

    // Apply the "Selected" bump
    Widget animatedBubble = bubble.animate(target: isSelected && !showCorrect ? 1 : 0)
        .scale(end: const Offset(1.05, 1.05), duration: 200.ms);

    // Apply the massive "Pop Fusion" explosion if correct
    animatedBubble = animatedBubble.animate(target: showCorrect ? 1 : 0)
        .scale(end: const Offset(1.8, 1.8), duration: 600.ms, curve: Curves.easeOutBack)
        .fadeOut(duration: 500.ms);

    // Apply the staggered vertical offset and continuous floating
    double staggeredOffset = index % 2 == 0 ? -20.0 : 20.0;
    
    return Transform.translate(
      offset: Offset(0, staggeredOffset),
      child: animatedBubble
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(
            begin: -6,
            end: 6,
            duration: (1500 + (index * 300)).ms,
            curve: Curves.easeInOut,
          ),
    );
  }
}
