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

// Biometric radar grid custom painter
class BiometricRadarPainter extends CustomPainter {
  final double animationValue;
  final Color themeColor;

  BiometricRadarPainter({
    required this.animationValue,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = themeColor.withValues(alpha: 0.05)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final double width = size.width;
    final double height = size.height;

    // Draw horizontal scan grids
    for (double y = 0; y < height; y += 24.h) {
      canvas.drawLine(Offset(0, y), Offset(width, y), linePaint);
    }
    // Draw vertical grids
    for (double x = 0; x < width; x += 24.w) {
      canvas.drawLine(Offset(x, 0), Offset(x, height), linePaint);
    }

    // Draw sweeping green medical laser line moving from top to bottom
    final Paint laserPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.25)
      ..strokeWidth = 2.0;

    final double laserY = height * animationValue;
    canvas.drawLine(Offset(0, laserY), Offset(width, laserY), laserPaint);

    final Paint laserGlowPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, laserY - 8.h, width, 16.h), laserGlowPaint);
  }

  @override
  bool shouldRepaint(covariant BiometricRadarPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.themeColor != themeColor;
  }
}

class MedicalConsultScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const MedicalConsultScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.medicalConsult,
  });

  @override
  State<MedicalConsultScreen> createState() => _MedicalConsultScreenState();
}

class _MedicalConsultScreenState extends State<MedicalConsultScreen> with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  late AnimationController _sweepController;
  late AnimationController _pulseController;
  
  int _lastProcessedIndex = -1;
  final List<String> _diagnosedSymptoms = [];
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  
  // Drag coordinate for physical scanning lens
  Offset _scanOffset = Offset.zero;
  
  // Set of unlocked nodes that are locked/resolved by the scanner lens
  final List<String> _scannedGlitches = [];

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    context.read<RoleplayBloc>().add(FetchRoleplayQuests(gameType: widget.gameType, level: widget.level));
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(RoleplayQuest quest) {
    _soundService.playTts(quest.instruction);
    if (quest.prompt != null) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) _soundService.playTts(quest.prompt!);
      });
    }
  }

  // Maps symptom vocabulary text to relative layout coordinates on silhouette body
  Offset _getAnatomicalOffset(String text) {
    final lower = text.toLowerCase();
    if (lower.contains("head") || lower.contains("brain") || lower.contains("sensor") || lower.contains("sensory")) {
      return Offset(0, -95.h);
    }
    if (lower.contains("left limb") || lower.contains("left arm") || lower.contains("left hand")) {
      return Offset(-64.w, -5.h);
    }
    if (lower.contains("right wing") || lower.contains("right limb") || lower.contains("right arm") || lower.contains("right hand")) {
      return Offset(64.w, -5.h);
    }
    if (lower.contains("core") || lower.contains("central") || lower.contains("chest") || lower.contains("heart")) {
      return Offset(0, -25.h);
    }
    if (lower.contains("left leg") || lower.contains("left foot")) {
      return Offset(-32.w, 90.h);
    }
    return Offset(32.w, 90.h); // Default Right Leg coordinate
  }

  void _onScanUpdate(DragUpdateDetails details, List<String> availableSymptoms) {
    if (_isAnswered) return;
    
    setState(() {
      _scanOffset += details.delta;
    });

    // Check proximity against all symptoms mentioned in the complaint list
    for (String s in availableSymptoms) {
      final Offset target = _getAnatomicalOffset(s);
      final double distance = (target - _scanOffset).distance;

      // 36r relative proximity locking boundary
      if (distance < 36.r) {
        if (!_scannedGlitches.contains(s)) {
          _hapticService.selection();
          _soundService.playHint(); // Play biometric heartbeat scan pulse
          setState(() {
            _scannedGlitches.add(s);
          });
        }
      }
    }
  }

  void _onSymptomTapped(String symptom) {
    if (_isAnswered) return;

    // Check if item is scanned before selection
    if (!_scannedGlitches.contains(symptom)) {
      _hapticService.error();
      return;
    }

    _hapticService.selection();
    setState(() {
      if (_diagnosedSymptoms.contains(symptom)) {
        _diagnosedSymptoms.remove(symptom);
      } else {
        _diagnosedSymptoms.add(symptom);
      }
    });
  }

  void _clearDiagnosis() {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() {
      _diagnosedSymptoms.clear();
      _scannedGlitches.clear();
      _scanOffset = Offset.zero;
    });
  }

  void _submitDiagnosis(String correctAnswer) {
    if (_isAnswered || _diagnosedSymptoms.isEmpty) return;

    final targets = correctAnswer.split(',').map((e) => e.trim().toLowerCase()).toList();
    final current = _diagnosedSymptoms.map((e) => e.trim().toLowerCase()).toList();

    bool isCorrect = targets.length == current.length && targets.every((t) => current.contains(t));

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
              _diagnosedSymptoms.clear();
              _scannedGlitches.clear();
              _scanOffset = Offset.zero;
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
            title: 'CHIEF SURGEON!',
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
        final symptoms = quest?.symptoms ?? [];

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
                      _buildPatientRecord(quest.prompt ?? "", theme.primaryColor, isDark),
                      SizedBox(height: 20.h),

                      // Holographic scan bay
                      _buildScanBay(symptoms, theme.primaryColor, isDark),
                      SizedBox(height: 24.h),

                      // Diagnostic symptoms tiles
                      _buildDiagnosticTray(symptoms, theme.primaryColor, isDark),
                      SizedBox(height: 28.h),

                      // Submit controls
                      if (!_isAnswered && _diagnosedSymptoms.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ScaleButton(
                              onTap: _clearDiagnosis,
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
                                      "RESET SCAN",
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
                              onTap: () => _submitDiagnosis(quest.correctAnswer ?? ""),
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
                                    Icon(Icons.medical_services_rounded, color: Colors.white, size: 18.r),
                                    SizedBox(width: 6.w),
                                    Text(
                                      "CONFIRM DIAGNOSIS",
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

                      // Explanations cards post-selection
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
            "BIOMETRIC DIAGNOSIS SLIP",
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
          "Drag the scan lens to locate active patient glitches",
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  Widget _buildPatientRecord(String prompt, Color color, bool isDark) {
    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1B) : Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 15,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.favorite_rounded, color: color, size: 24.r),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(1, 1),
                end: const Offset(1.15, 1.15),
                duration: 1.5.seconds,
                curve: Curves.easeInOut,
              ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ADMITTED CLINICAL COMPLAINT:",
                  style: GoogleFonts.shareTechMono(
                    fontSize: 10.sp,
                    color: color,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  prompt,
                  style: GoogleFonts.fredoka(
                    fontSize: 17.sp,
                    color: isDark ? Colors.white : Colors.black87,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanBay(List<String> symptoms, Color color, bool isDark) {
    return Container(
      width: 1.sw,
      height: 330.h,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF07070F) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(36.r),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Cybernetic scan matrix background grids
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36.r),
              child: AnimatedBuilder(
                animation: _sweepController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: BiometricRadarPainter(
                      animationValue: _sweepController.value,
                      themeColor: color,
                    ),
                  );
                },
              ),
            ),
          ),

          // Glowing wireframe patient body
          Center(
            child: Icon(
              Icons.accessibility_new_rounded,
              size: 260.r,
              color: color.withValues(alpha: 0.1),
            ).animate(
              onPlay: (c) => c.repeat(reverse: true),
            ).shimmer(
              duration: 2.2.seconds,
              color: color.withValues(alpha: 0.35),
            ),
          ),

          // Render active symptom glitch circles dynamically mapped anatomically
          ...symptoms.map((s) {
            final Offset pos = _getAnatomicalOffset(s);
            final bool isResolved = _scannedGlitches.contains(s);

            return Positioned(
              left: (1.sw / 2) - 16.w + pos.dx,
              top: (330.h / 2) - 16.h + pos.dy,
              child: Container(
                width: 32.r,
                height: 32.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isResolved
                      ? color.withValues(alpha: 0.2)
                      : Colors.redAccent.withValues(alpha: 0.08),
                  border: Border.all(
                    color: isResolved ? color : Colors.redAccent.withValues(alpha: 0.7),
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isResolved ? color : Colors.redAccent).withValues(alpha: 0.25),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isResolved ? Icons.check_circle_outline_rounded : Icons.warning_rounded,
                    color: isResolved ? color : Colors.redAccent,
                    size: 14.r,
                  ),
                ),
              ).animate(
                onPlay: (c) => c.repeat(reverse: true),
              ).scale(
                begin: const Offset(1, 1),
                end: const Offset(1.15, 1.15),
                duration: 1.5.seconds,
                curve: Curves.easeInOut,
              ),
            );
          }),

          // Interactive Drag-to-Scan lens
          Positioned(
            left: (1.sw / 2) - 50.w + _scanOffset.dx,
            top: (330.h / 2) - 50.h + _scanOffset.dy,
            child: GestureDetector(
              onPanUpdate: (d) => _onScanUpdate(d, symptoms),
              child: Container(
                width: 100.r,
                height: 100.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 3.0),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 15,
                    ),
                  ],
                  color: color.withValues(alpha: 0.05),
                ),
                child: Center(
                  child: Icon(
                    Icons.center_focus_strong_rounded,
                    color: color,
                    size: 36.r,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticTray(List<String> symptoms, Color color, bool isDark) {
    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1B) : Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ANATOMICAL DIAGNOSTICS SLATE",
                style: GoogleFonts.shareTechMono(
                  fontSize: 10.sp,
                  color: color,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.health_and_safety_rounded, color: color.withValues(alpha: 0.5), size: 16.r),
            ],
          ),
          SizedBox(height: 16.h),

          // Symptoms grid chips
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10.w,
            runSpacing: 10.h,
            children: symptoms.map((s) {
              final bool isScanned = _scannedGlitches.contains(s);
              final bool isChecked = _diagnosedSymptoms.contains(s);

              Color cardColor = color;
              if (_isAnswered && isChecked) {
                cardColor = (_isCorrect ?? false) ? Colors.greenAccent : Colors.redAccent;
              }

              return ScaleButton(
                onTap: () => _onSymptomTapped(s),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: isChecked
                        ? cardColor
                        : (isDark ? const Color(0xFF131326) : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isChecked
                          ? Colors.white
                          : isScanned
                              ? color.withValues(alpha: 0.4)
                              : color.withValues(alpha: 0.08),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isChecked ? cardColor : color).withValues(alpha: isChecked ? 0.25 : 0.04),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isChecked
                            ? Icons.check_circle_rounded
                            : isScanned
                                ? Icons.biotech_rounded
                                : Icons.lock_outline_rounded,
                        color: isChecked
                            ? Colors.white
                            : isScanned
                                ? color
                                : (isDark ? Colors.white24 : Colors.black26),
                        size: 14.r,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        s.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w900,
                          color: isChecked
                              ? Colors.white
                              : isScanned
                                  ? (isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87)
                                  : (isDark ? Colors.white24 : Colors.black26),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationCard(RoleplayQuest quest, bool isDark) {
    final Color cardColor = (_isCorrect ?? false) ? Colors.greenAccent : Colors.orangeAccent;

    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131326) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: cardColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.15),
            blurRadius: 15,
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
                (_isCorrect ?? false) ? "Glitch Purified!" : "Diagnostics Contamination!",
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
            quest.explanation ?? "Correlating patient symptoms to physiological glitch vectors builds strong diagnostic and context vocabulary recall.",
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.35,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }
}
