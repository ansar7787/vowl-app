import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/widgets/roleplay_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';

// Real-time constellation link painter
class ConstellationPainter extends CustomPainter {
  final List<int> selectedIndices;
  final List<Offset> starOffsets;
  final Color themeColor;
  final bool isAnswered;
  final bool? isCorrect;
  final double pulseValue;

  ConstellationPainter({
    required this.selectedIndices,
    required this.starOffsets,
    required this.themeColor,
    required this.isAnswered,
    this.isCorrect,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (selectedIndices.length < 2) return;

    Color lineColor = themeColor;
    if (isAnswered) {
      lineColor = (isCorrect ?? false) ? Colors.greenAccent : Colors.redAccent;
    }

    final Paint paint = Paint()
      ..color = lineColor.withValues(alpha: 0.6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint glowPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.2 + (0.15 * pulseValue))
      ..strokeWidth = 7.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path path = Path();
    final Offset start = starOffsets[selectedIndices.first];
    path.moveTo(start.dx, start.dy);

    for (int i = 1; i < selectedIndices.length; i++) {
      final Offset target = starOffsets[selectedIndices[i]];
      path.lineTo(target.dx, target.dy);
    }

    // Draw background glowing aura path
    canvas.drawPath(path, glowPaint);
    // Draw crisp front path
    canvas.drawPath(path, paint);

    // Draw little cosmic telemetry sparks at connecting hubs
    final Paint sparkPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    for (int idx in selectedIndices) {
      canvas.drawCircle(starOffsets[idx], 4.r, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ConstellationPainter oldDelegate) {
    return oldDelegate.selectedIndices != selectedIndices ||
        oldDelegate.starOffsets != starOffsets ||
        oldDelegate.themeColor != themeColor ||
        oldDelegate.isAnswered != isAnswered ||
        oldDelegate.isCorrect != isCorrect ||
        oldDelegate.pulseValue != pulseValue;
  }
}

class SocialSparkScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SocialSparkScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.socialSpark,
  });

  @override
  State<SocialSparkScreen> createState() => _SocialSparkScreenState();
}

class _SocialSparkScreenState extends State<SocialSparkScreen> with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  late AnimationController _pulseController;
  
  int _lastProcessedIndex = -1;
  
  // Track selected words by their original shuffled index to support duplicate words flawlessly
  final List<int> _selectedIndices = [];
  
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    context.read<RoleplayBloc>().add(FetchRoleplayQuests(gameType: widget.gameType, level: widget.level));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(RoleplayQuest quest) {
    _soundService.playTts(quest.instruction);
  }

  void _onStarTap(int index) {
    if (_isAnswered) return;
    _hapticService.selection();
    _soundService.playHint(); // Play little synth tap note

    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _clearSelection() {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() {
      _selectedIndices.clear();
    });
  }

  void _submitAnswer(List<String> shuffledWords, String correctAnswer) {
    if (_isAnswered || _selectedIndices.isEmpty) return;
    
    // Assemble sentence in correct tapped order
    final String result = _selectedIndices.map((idx) => shuffledWords[idx]).join(' ');
    
    // Sanitize punctuation comparisons cleanly
    final sanitizedResult = result.replaceAll(' ?', '?').trim().toLowerCase();
    final sanitizedAnswer = correctAnswer.replaceAll(' ?', '?').trim().toLowerCase();
    
    final bool isCorrect = sanitizedResult == sanitizedAnswer;

    setState(() {
      _isAnswered = true;
      _isCorrect = isCorrect;
    });

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<RoleplayBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<RoleplayBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('roleplay', level: widget.level);

    return BlocConsumer<RoleplayBloc, RoleplayState>(
      listener: (context, state) {
        if (state is RoleplayLoaded) {
          if (state.currentIndex != _lastProcessedIndex) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedIndices.clear();
            });
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          }
        }
        if (state is RoleplayGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'CONVERSATION STARTER!',
            enableDoubleUp: true,
          );
        } else if (state is RoleplayGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<RoleplayBloc>().add(RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final quest = (state is RoleplayLoaded) ? state.currentQuest : null;
        final words = quest?.shuffledWords ?? [];

        // Build active joined text representation
        final String currentText = _selectedIndices.map((idx) => words[idx]).join(' ');

        return RoleplayBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<RoleplayBloc>().add(NextQuestion()),
          onHint: () => context.read<RoleplayBloc>().add(RoleplayHintUsed()),
          child: quest == null
              ? const SizedBox()
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  child: Column(
                    children: [
                      _buildHeaderInstruction(theme.primaryColor),
                      SizedBox(height: 16.h),
                      _buildConnectionMonitor(currentText, theme.primaryColor, isDark),
                      SizedBox(height: 20.h),
                      _buildGalaxyBoard(words, theme.primaryColor, isDark),
                      SizedBox(height: 20.h),

                      // Trigger Action Buttons
                      if (!_isAnswered && _selectedIndices.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ScaleButton(
                              onTap: _clearSelection,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(30.r),
                                  border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.refresh_rounded, color: theme.primaryColor, size: 18.r),
                                    SizedBox(width: 6.w),
                                    Text(
                                      "CLEAR PATH",
                                      style: GoogleFonts.outfit(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            ScaleButton(
                              onTap: () => _submitAnswer(words, quest.correctAnswer ?? ""),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30.r),
                                  gradient: LinearGradient(
                                    colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.8)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.primaryColor.withValues(alpha: 0.35),
                                      blurRadius: 15,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.bolt_rounded, color: Colors.white, size: 18.r),
                                    SizedBox(width: 6.w),
                                    Text(
                                      "IGNITE SPARK",
                                      style: GoogleFonts.outfit(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(duration: 300.ms),

                      // Post-answer review cards
                      AnimatedCrossFade(
                        firstChild: const SizedBox(),
                        secondChild: _buildExplanationCard(quest, isDark),
                        crossFadeState: _isAnswered
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 400),
                      ),
                      SizedBox(height: 80.h),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildHeaderInstruction(Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Text(
            "CONNECT CONVERSATION NEBULA",
            style: GoogleFonts.outfit(
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 2.5,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          "Link the floating verbal stars in correct syntactic sequence",
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionMonitor(String text, Color color, bool isDark) {
    Color outlineColor = color;
    if (_isAnswered) {
      outlineColor = (_isCorrect ?? false) ? Colors.greenAccent : Colors.redAccent;
    }

    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1B) : Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: outlineColor.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: outlineColor.withValues(alpha: 0.08),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hub_rounded, color: outlineColor, size: 18.r),
              SizedBox(width: 8.w),
              Text(
                _isAnswered
                    ? ((_isCorrect ?? false) ? "ALIGNMENT STABLE" : "SIGNAL COLLAPSED")
                    : "CONSTELLATION HARMONICS",
                style: GoogleFonts.shareTechMono(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  color: outlineColor,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text(
                text.isEmpty ? "SELECT INITIAL STAR NODE..." : text,
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 20.sp,
                  color: text.isEmpty
                      ? Colors.grey.shade600
                      : (isDark ? Colors.white : Colors.black87),
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildGalaxyBoard(List<String> words, Color color, bool isDark) {
    return Container(
      width: 1.sw,
      height: 380.h,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF07070F) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(36.r),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;

          // Deterministic geometric layout to spread stars organically without overlapping
          final List<Offset> starOffsets = List.generate(words.length, (i) {
            double angle = (i * 2 * math.pi / words.length) + (i * 0.15);
            double radiusX = (width / 2) - 60.w;
            double radiusY = (height / 2) - 50.h;
            
            // Alternating wave depth
            double depth = (i % 2 == 0) ? 0.95 : 0.65;

            double x = (width / 2) + radiusX * depth * math.cos(angle);
            double y = (height / 2) + radiusY * depth * math.sin(angle);
            return Offset(x, y);
          });

          return Stack(
            children: [
              // Radial space dust glow
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [color.withValues(alpha: 0.05), Colors.transparent],
                    ),
                  ),
                ),
              ),

              // Interactive laser lines connector paths
              Positioned.fill(
                child: CustomPaint(
                  painter: ConstellationPainter(
                    selectedIndices: _selectedIndices,
                    starOffsets: starOffsets,
                    themeColor: color,
                    isAnswered: _isAnswered,
                    isCorrect: _isCorrect,
                    pulseValue: _pulseController.value,
                  ),
                ),
              ),

              // Orbiting verbal stars
              ...List.generate(words.length, (i) {
                final Offset pos = starOffsets[i];
                return _buildStarNode(i, words[i], pos, color, isDark);
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStarNode(int index, String text, Offset pos, Color color, bool isDark) {
    final bool isSelected = _selectedIndices.contains(index);
    final int selectOrderIndex = _selectedIndices.indexOf(index) + 1;

    Color nodeColor = color;
    if (_isAnswered && isSelected) {
      nodeColor = (_isCorrect ?? false) ? Colors.greenAccent : Colors.redAccent;
    }

    return Positioned(
      left: pos.dx - 48.w,
      top: pos.dy - 32.h,
      child: ScaleButton(
        onTap: () => _onStarTap(index),
        child: Container(
          width: 96.w,
          height: 64.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            color: isSelected ? nodeColor : (isDark ? const Color(0xFF0F0F1B) : Colors.white),
            border: Border.all(
              color: isSelected ? Colors.white : color.withValues(alpha: 0.4),
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isSelected ? nodeColor : color).withValues(alpha: isSelected ? 0.4 : 0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Tiny connection index tag
              if (isSelected)
                Positioned(
                  top: 4.h,
                  left: 6.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      "$selectOrderIndex",
                      style: GoogleFonts.shareTechMono(
                        fontSize: 8.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // Sparkle particle stars
              Positioned(
                right: 6.w,
                top: 4.h,
                child: Icon(
                  Icons.star_rounded,
                  size: 10.r,
                  color: isSelected ? Colors.white : color.withValues(alpha: 0.3),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate(
        onPlay: (c) => c.repeat(reverse: true),
      ).moveY(
        begin: -4,
        end: 4,
        duration: (1.8 + index * 0.35).seconds,
        curve: Curves.easeInOut,
      ),
    );
  }

  Widget _buildExplanationCard(RoleplayQuest quest, bool isDark) {
    final Color cardColor = (_isCorrect ?? false) ? Colors.greenAccent : Colors.orangeAccent;

    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131326) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: cardColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.1),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                (_isCorrect ?? false) ? Icons.verified_rounded : Icons.info_rounded,
                color: cardColor,
                size: 24.r,
              ),
              SizedBox(width: 8.w),
              Text(
                (_isCorrect ?? false) ? "Alignment Locked!" : "Nebula Mismatch!",
                style: GoogleFonts.outfit(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            quest.explanation ?? "Matching icebreaker sequences builds strong conversational openers and syntactic fluency.",
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.3,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }
}
