import 'dart:math' as math;
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

class ContextCluesScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ContextCluesScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.contextClues,
  });

  @override
  State<ContextCluesScreen> createState() => _ContextCluesScreenState();
}

class _ContextCluesScreenState extends State<ContextCluesScreen> with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  Offset _lensPosition = Offset.zero;
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

  void _onLensMove(DragUpdateDetails details) {
    if (_isAnswered) return;
    setState(() {
      _lensPosition += details.delta;
    });
    
    // Haptic feedback when crossing central areas
    if (_lensPosition.distance < 50.r) {
      _hapticService.selection();
    }
  }

  void _submitAnswer(String selected, String correct) {
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
          if (state.currentIndex != _lastProcessedIndex || (_isAnswered && state.lastAnswerCorrect == null)) {
            setState(() {
              _lastQuest = state.currentQuest;
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _lensPosition = Offset.zero;
            });
          }
        }
        if (state is VocabularyGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'CASE CLOSED!',
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
          child: quest == null ? const SizedBox() : Stack(
            alignment: Alignment.center,
            children: [
              // Noir Background Glow
              _buildNoirAmbience(theme.primaryColor),

              // The Investigation Scene
              Column(
                children: [
                  SizedBox(height: 20.h),
                  _buildInvestigationStatus(theme.primaryColor),
                  SizedBox(height: 40.h),
                  
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Obscured Passage
                        _buildObscuredPassage(quest.sentence ?? "", isDark),
                        
                        // Interactive Detective Lens
                        if (!_isAnswered) _buildDetectiveLens(quest.sentence ?? "", theme.primaryColor, isDark),
                      ],
                    ),
                  ),

                  // Evidence Options
                  _buildEvidenceOptions(quest.options ?? [], quest.correctAnswer ?? "", theme.primaryColor, isDark),
                  SizedBox(height: 30.h),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoirAmbience(Color color) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              color.withValues(alpha: 0.05),
              Colors.black,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvestigationStatus(Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(5.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_rounded, size: 16.r, color: color),
          SizedBox(width: 10.w),
          Text(
            "REVEAL THE OBSCURED EVIDENCE",
            style: GoogleFonts.shareTechMono(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 3.seconds);
  }

  Widget _buildObscuredPassage(String text, bool isDark) {
    return Container(
      padding: EdgeInsets.all(30.r),
      child: Stack(
        children: [
          // The real text but blurred/obscured
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.specialElite(
              fontSize: 22.sp,
              color: isDark ? Colors.white24 : Colors.black26,
              height: 1.6,
            ),
          ),
          // Additional Ink/Grit Overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(painter: InkGritPainter()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectiveLens(String text, Color color, bool isDark) {
    return Positioned(
      left: 100.w + _lensPosition.dx,
      top: 100.h + _lensPosition.dy,
      child: GestureDetector(
        onPanUpdate: _onLensMove,
        child: Container(
          width: 180.r,
          height: 180.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 6),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 40, spreadRadius: 10),
              const BoxShadow(color: Colors.black, blurRadius: 10, spreadRadius: 2),
            ],
          ),
          child: ClipOval(
            child: Stack(
              children: [
                // Clear view of text
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                  child: Container(
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: Transform.translate(
                      offset: Offset(-_lensPosition.dx, -_lensPosition.dy),
                      child: Container(
                        width: 500.w,
                        padding: EdgeInsets.all(30.r),
                        child: Text(
                          text,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.specialElite(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                            height: 1.6,
                            shadows: [
                              Shadow(color: color.withValues(alpha: 0.5), blurRadius: 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Lens Reflection
                Positioned(
                  top: 10, left: 20,
                  child: Container(
                    width: 40, height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEvidenceOptions(List<String> options, String correct, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          "CASE CONCLUSION:",
          style: GoogleFonts.shareTechMono(
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
            color: color.withValues(alpha: 0.7),
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: 15.h),
        Wrap(
          spacing: 15.w,
          runSpacing: 15.h,
          alignment: WrapAlignment.center,
          children: options.map((o) {
            final isCorrectOption = _isAnswered && o == correct;
            final isWrongOption = _isAnswered && _isCorrect == false && o != correct;

            return ScaleButton(
              onTap: () => _submitAnswer(o, correct),
              child: Container(
                width: 160.w,
                padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
                decoration: BoxDecoration(
                  color: isCorrectOption 
                      ? Colors.green.withValues(alpha: 0.2) 
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(2.r), // Sharp noir edges
                  border: Border.all(
                    color: isCorrectOption 
                        ? Colors.green 
                        : (isWrongOption ? Colors.red : color.withValues(alpha: 0.2)),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 5, offset: const Offset(3, 3)),
                  ],
                ),
                child: Text(
                  o.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.shareTechMono(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0);
  }
}

class InkGritPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0;
    
    final random = math.Random();
    for (int i = 0; i < 100; i++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        random.nextDouble() * 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
