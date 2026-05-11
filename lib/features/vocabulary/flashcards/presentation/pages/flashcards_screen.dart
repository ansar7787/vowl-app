import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/widgets/vocabulary_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';

class FlashcardsScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const FlashcardsScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.flashcards,
  });

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  Offset _dragOffset = Offset.zero;
  double _dragAngle = 0.0;
  bool _isFlipped = false;
  bool _isAnswered = false;
  bool _isRetrying = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(
      FetchVocabularyQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isAnswered) return;
    if (_isRetrying) setState(() => _isRetrying = false);
    setState(() {
      _dragOffset += details.delta;
      _dragAngle = _dragOffset.dx / 500;
      if (_dragOffset.dx.abs() % 10 < 1) _hapticService.selection();
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isAnswered) return;
    if (_dragOffset.dx.abs() > 150) {
      _submitAnswer(_dragOffset.dx > 0);
    } else {
      setState(() {
        _dragOffset = Offset.zero;
        _dragAngle = 0.0;
      });
    }
  }

  void _submitAnswer(bool mastered) {
    if (_isAnswered) return;
    if (mastered) {
      _hapticService.success();
      _soundService.playCorrect();
    } else {
      _hapticService.error();
      _soundService.playWrong();
    }
    setState(() {
      _isAnswered = true;
      _isCorrect = mastered;
      _dragOffset = Offset(mastered ? 1000 : -1000, 0);
    });
    context.read<VocabularyBloc>().add(SubmitAnswer(mastered));
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
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isRetrying = isRetry;
              _isCorrect = null;
              _isFlipped = false;
              _dragOffset = Offset.zero;
              _dragAngle = 0.0;
            });
          }
        }
        if (state is VocabularyGameComplete) {
          if (!_showConfetti) {
            setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'VOCAB MASTERY!',
            enableDoubleUp: true,
          );
        }
      } else if (state is VocabularyGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<VocabularyBloc>().add(RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final quest = (state is VocabularyLoaded) ? state.currentQuest : null;

        return VocabularyBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
          onHint: () =>
              context.read<VocabularyBloc>().add(VocabularyHintUsed()),
          child: quest == null
              ? const SizedBox()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate dynamic card height based on available space
                    // Subtracting some space for instruction and hints
                    final availableHeight = constraints.maxHeight;
                    final cardHeight = (availableHeight * 0.65)
                        .clamp(300.0, 450.0)
                        .h;
                    final cardWidth = (constraints.maxWidth * 0.85)
                        .clamp(280.0, 320.0)
                        .w;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 12.h),
                        _buildInstruction(theme.primaryColor),
                        SizedBox(height: 24.h),
                        _buildCardStack(
                          quest,
                          theme.primaryColor,
                          isDark,
                          cardWidth,
                          cardHeight,
                        ),
                        SizedBox(height: 32.h),
                        _buildSwipeHints(theme.primaryColor),
                        SizedBox(height: 20.h),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildInstruction(Color primaryColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swipe_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              "SWIPE RIGHT TO MASTER, LEFT TO REVIEW",
              style: GoogleFonts.outfit(
                fontSize: 9.sp,
                fontWeight: FontWeight.w900,
                color: primaryColor,
                letterSpacing: 1.2,
              ),
              overflow: TextOverflow.visible,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildCardStack(
    dynamic quest,
    Color color,
    bool isDark,
    double width,
    double height,
  ) {
    return GestureDetector(
      onPanUpdate: _onDragUpdate,
      onPanEnd: _onDragEnd,
      onTap: () {
        _hapticService.light();
        setState(() => _isFlipped = !_isFlipped);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Bottom Card Decoration (Shadow/Stack effect)
          Transform.translate(
            offset: const Offset(0, 10),
            child: Container(
              width: width * 0.95,
              height: height,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24.r),
              ),
            ),
          ),

          // Main Interactive Card
          RepaintBoundary(
            child: AnimatedContainer(
              duration: (_isAnswered || _isRetrying) ? 400.ms : 0.ms,
              curve: Curves.easeOutBack,
              transform: Matrix4.identity()
                ..setTranslationRaw(_dragOffset.dx, _dragOffset.dy, 0.0)
                ..rotateZ(_dragAngle),
              child: TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: _isFlipped ? 1 : 0),
                duration: 400.ms,
                curve: Curves.easeInOutBack,
                builder: (context, value, child) {
                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(value * pi),
                    alignment: Alignment.center,
                    child: value > 0.5
                        ? Transform(
                            transform: Matrix4.identity()..rotateY(pi),
                            alignment: Alignment.center,
                            child: _buildCardBack(
                              quest,
                              color,
                              isDark,
                              width,
                              height,
                            ),
                          )
                        : _buildCardFront(quest, color, isDark, width, height),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFront(
    dynamic quest,
    Color color,
    bool isDark,
    double width,
    double height,
  ) {
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark ? Colors.white10 : color.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              quest.topicEmoji ?? "🏷️",
              style: TextStyle(fontSize: 56.sp),
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          SizedBox(height: 32.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              quest.word?.toUpperCase() ?? "",
              style: GoogleFonts.outfit(
                fontSize: 32.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: 4,
              ),
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 14.r,
                color: color.withValues(alpha: 0.5),
              ),
              SizedBox(width: 8.w),
              Text(
                "TAP TO FLIP",
                style: GoogleFonts.outfit(
                  fontSize: 10.sp,
                  color: color.withValues(alpha: 0.5),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(
    dynamic quest,
    Color color,
    bool isDark,
    double width,
    double height,
  ) {
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: color, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 10.h),
            Text(
              "DEFINITION",
              style: GoogleFonts.outfit(
                fontSize: 10.sp,
                color: color,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              quest.definition ?? "",
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 19.sp,
                color: isDark ? Colors.white : Colors.black87,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 28.h),
            Divider(
              color: color.withValues(alpha: 0.1),
              thickness: 1,
              indent: 40.w,
              endIndent: 40.w,
            ),
            SizedBox(height: 24.h),
            Text(
              "EXAMPLE",
              style: GoogleFonts.outfit(
                fontSize: 10.sp,
                color: Colors.amber.shade700,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              quest.example ?? "",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 15.sp,
                color: isDark ? Colors.white70 : Colors.black54,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
            if (quest.explanation != null && quest.explanation!.isNotEmpty) ...[
              SizedBox(height: 24.h),
              Text(
                "EXPLANATION",
                style: GoogleFonts.outfit(
                  fontSize: 10.sp,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                quest.explanation!,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  color: isDark ? Colors.white60 : Colors.black45,
                  height: 1.5,
                ),
              ),
            ],
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeHints(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildHintIcon(Icons.refresh_rounded, Colors.redAccent, "REVIEW"),
        _buildHintIcon(
          Icons.check_circle_rounded,
          Colors.greenAccent,
          "MASTER",
        ),
      ],
    );
  }

  Widget _buildHintIcon(IconData icon, Color color, String label) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: color, size: 24.r),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10.sp,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 1,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).scale();
  }
}
