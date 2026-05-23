import 'dart:async';
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
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/widgets/roleplay_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';

// Visual real-time soundwave graph painter
class SoundwaveSpectrumPainter extends CustomPainter {
  final double animationValue;
  final bool isListening;
  final Color themeColor;

  SoundwaveSpectrumPainter({
    required this.animationValue,
    required this.isListening,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isListening) return;

    final Paint paint = Paint()
      ..color = themeColor.withValues(alpha: 0.8)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double width = size.width;
    final double height = size.height;
    final double midY = height / 2;

    final Path path = Path();
    path.moveTo(0, midY);

    final int points = 50;
    for (int i = 0; i <= points; i++) {
      final double x = (width / points) * i;
      // Combine multiple harmonic frequencies for a high-tech biosensor audio wave look
      final double wave1 = math.sin((i * 0.25) - (animationValue * 2 * math.pi * 3));
      final double wave2 = math.cos((i * 0.12) + (animationValue * 2 * math.pi * 1.5));
      final double envelope = math.sin((i / points) * math.pi); // Fade edges to 0
      
      final double y = midY + (wave1 * 12.h + wave2 * 6.h) * envelope;
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SoundwaveSpectrumPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isListening != isListening ||
        oldDelegate.themeColor != themeColor;
  }
}

class ElevatorPitchScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ElevatorPitchScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.elevatorPitch,
  });

  @override
  State<ElevatorPitchScreen> createState() => _ElevatorPitchScreenState();
}

class _ElevatorPitchScreenState extends State<ElevatorPitchScreen> with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _speechService = di.sl<SpeechService>();
  
  late AnimationController _waveController;
  Timer? _gravityTimer;
  
  int _lastProcessedIndex = -1;
  bool _isListening = false;
  String _spokenText = "";
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  
  // Real-time Physics variables
  double _capsuleY = 0.4;    // Position of capsule inside elevator shaft (0.0 to 1.0)
  double _greenZoneY = 0.5;  // Center position of green target zone (0.0 to 1.0)
  
  // Game scores
  int _ticksRecorded = 0;
  int _ticksInAlignment = 0;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    context.read<RoleplayBloc>().add(FetchRoleplayQuests(gameType: widget.gameType, level: widget.level));
  }

  @override
  void dispose() {
    _waveController.dispose();
    _gravityTimer?.cancel();
    super.dispose();
  }

  void _triggerAutoPlay(RoleplayQuest quest) {
    _soundService.playTts(quest.instruction);
    if (quest.prompt != null) {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) _soundService.playTts(quest.prompt!);
      });
    }
  }

  // Propulsion action: fires booster pushing capsule UP
  void _fireBooster() {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() {
      _capsuleY = (_capsuleY - 0.16).clamp(0.0, 1.0);
    });
  }

  // Dynamic Physical Engine loops running while microphone records
  void _startPhysicalEngine() {
    _ticksRecorded = 0;
    _ticksInAlignment = 0;
    _gravityTimer?.cancel();
    
    _gravityTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted || _isAnswered || !_isListening) {
        timer.cancel();
        return;
      }

      setState(() {
        // 1. Gravity acceleration pulls capsule DOWN
        _capsuleY = (_capsuleY + 0.007).clamp(0.0, 1.0);

        // 2. Green target zone floats using a smooth harmonic sine wave
        final double elapsedSec = DateTime.now().millisecondsSinceEpoch / 1000.0;
        _greenZoneY = 0.5 + 0.3 * math.sin(elapsedSec * 1.6);

        // 3. Increment calibration alignments
        _ticksRecorded++;
        final double dist = (_capsuleY - _greenZoneY).abs();
        if (dist < 0.14) {
          _ticksInAlignment++;
        }
      });
    });
  }

  void _startListening() async {
    if (_isAnswered) return;
    _hapticService.selection();
    
    setState(() {
      _isListening = true;
      _spokenText = "Voice capturing initiated...";
      _capsuleY = 0.4;
    });

    _startPhysicalEngine();

    _speechService.listen(
      onResult: (text) {
        setState(() {
          _spokenText = text;
          // Giving small booster lift upon spoken transcript updates
          _capsuleY = (_capsuleY - 0.04).clamp(0.0, 1.0);
        });
      },
      onDone: () {
        if (mounted) {
          setState(() => _isListening = false);
          _gravityTimer?.cancel();
        }
      },
    );
  }

  void _stopListening(String target) async {
    await _speechService.stop();
    _gravityTimer?.cancel();
    setState(() => _isListening = false);
    _verifySpeech(target);
  }

  void _verifySpeech(String target) {
    if (_spokenText.isEmpty || _spokenText.startsWith("Voice capturing")) {
      _spokenText = "No recording input captured.";
      return;
    }

    // Alignment accuracy score
    final double alignmentAccuracy = _ticksRecorded > 0 ? (_ticksInAlignment / _ticksRecorded) : 0.0;
    
    // Core requirements:
    // 1. alignmentAccuracy >= 40% (stayed inside the drifting green elevator target bounds)
    // 2. Length of spoken text >= 12 chars
    bool isCorrect = alignmentAccuracy >= 0.40 && _spokenText.length >= 12;

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
              _spokenText = "";
              _isListening = false;
              _capsuleY = 0.4;
              _greenZoneY = 0.5;
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
            title: 'CHIEF BRAND PITCHER!',
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
                      _buildPitchPromptCard(quest.prompt ?? "", theme.primaryColor, isDark),
                      SizedBox(height: 20.h),

                      // Elevator Physical Chamber Layout
                      _buildChamberConsole(theme.primaryColor, isDark),
                      SizedBox(height: 24.h),

                      // Speech input capture controls
                      if (!_isAnswered)
                        _buildRecordControl(quest.correctAnswer ?? "", theme.primaryColor, isDark),

                      // Post-answer explanation cards
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
            "VOCAL STABILITY LIFT CHAMBER",
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
          "Keep the rocket capsule aligned in the target lift zone while pitching!",
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

  Widget _buildPitchPromptCard(String prompt, Color color, bool isDark) {
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
            child: Icon(Icons.rocket_launch_rounded, color: color, size: 24.r),
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
                  "ELEVATOR SPEECH PROMPT:",
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

  Widget _buildChamberConsole(Color color, bool isDark) {
    final double totalShaftHeight = 240.h;
    final double zoneHeight = 72.h;
    
    // Normalize bounds logic
    final double greenTop = (totalShaftHeight - zoneHeight) * _greenZoneY;
    final double capsuleTop = (totalShaftHeight - 32.h) * _capsuleY;
    
    final bool isAligned = (_capsuleY - _greenZoneY).abs() < 0.14;

    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF07070F) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(36.r),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Row(
        children: [
          // 1. Elevator Vertical Physics Shaft
          GestureDetector(
            onTap: _fireBooster,
            child: Container(
              width: 64.w,
              height: totalShaftHeight,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0B0B14) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(32.r),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                  width: 2,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  // Drifting green harmonic target zone
                  Positioned(
                    top: greenTop,
                    child: Container(
                      width: 58.w,
                      height: zoneHeight,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.6), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent.withValues(alpha: 0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(
                          color: Colors.greenAccent.withValues(alpha: 0.3),
                          duration: 1.5.seconds,
                        ),
                  ),

                  // Capsule Booster Rocket
                  Positioned(
                    top: capsuleTop,
                    child: Container(
                      width: 32.r,
                      height: 32.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isAligned ? Colors.greenAccent : color,
                        boxShadow: [
                          BoxShadow(
                            color: (isAligned ? Colors.greenAccent : color).withValues(alpha: 0.45),
                            blurRadius: 12,
                            spreadRadius: 1.5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.rocket_launch_rounded,
                        color: Colors.white,
                        size: 16.r,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 20.w),

          // 2. Transcript and Soundwave Monitor Board
          Expanded(
            child: Container(
              height: totalShaftHeight,
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
                        "LIVE TELEMETRY SPECTRUM",
                        style: GoogleFonts.shareTechMono(
                          fontSize: 10.sp,
                          color: color,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        width: 10.r,
                        height: 10.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isListening ? Colors.redAccent : Colors.grey,
                        ),
                      ).animate(target: _isListening ? 1.0 : 0.0).scale(begin: const Offset(1,1), end: const Offset(1.2, 1.2)).fadeIn(),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // Dynamic voice sinusoidal graphs
                  SizedBox(
                    height: 48.h,
                    child: AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: SoundwaveSpectrumPainter(
                            animationValue: _waveController.value,
                            isListening: _isListening,
                            themeColor: color,
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 8.h),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        _spokenText.isEmpty ? "Tap the record lens and pitch your concept..." : _spokenText,
                        style: GoogleFonts.outfit(
                          fontSize: 13.sp,
                          fontStyle: _spokenText.isEmpty ? FontStyle.normal : FontStyle.italic,
                          color: _spokenText.isEmpty
                              ? (isDark ? Colors.white30 : Colors.black38)
                              : (isDark ? Colors.white70 : Colors.black87),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordControl(String correctAnswer, Color color, bool isDark) {
    return Column(
      children: [
        GestureDetector(
          onLongPressStart: (_) => _startListening(),
          onLongPressEnd: (_) => _stopListening(correctAnswer),
          child: ScaleButton(
            onTap: () {},
            child: Container(
              width: 90.r,
              height: 90.r,
              decoration: BoxDecoration(
                color: _isListening ? Colors.redAccent : color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isListening ? Colors.redAccent : color).withValues(alpha: 0.35),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                  color: Colors.white,
                  size: 40.r,
                ),
              ),
            ).animate(target: _isListening ? 1.0 : 0.0).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.15, 1.15),
                  duration: 1.seconds,
                  curve: Curves.easeInOut,
                ),
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          _isListening ? "RELEASE TO ANALYZE LIFT PITCH" : "HOLD LENS TO RECORD PITCH & TAP SHAFT TO BOOST",
          textAlign: TextAlign.center,
          style: GoogleFonts.shareTechMono(
            fontSize: 9.sp,
            color: Colors.grey,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildExplanationCard(RoleplayQuest quest, bool isDark) {
    final Color cardColor = (_isCorrect ?? false) ? Colors.greenAccent : Colors.orangeAccent;
    final double accuracy = _ticksRecorded > 0 ? (_ticksInAlignment / _ticksRecorded) * 100 : 0.0;

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
                (_isCorrect ?? false) ? "Stabilization Successful!" : "Stabilization Failure!",
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
            quest.explanation ?? "Keeping speech parameters aligned inside target margins creates robust voice control confidence.",
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.35,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            "Vocal Stability Proximity: ${accuracy.toStringAsFixed(0)}%",
            style: GoogleFonts.shareTechMono(
              fontSize: 11.sp,
              color: cardColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }
}
