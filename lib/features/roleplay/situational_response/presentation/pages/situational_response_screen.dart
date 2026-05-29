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
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/widgets/roleplay_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';
import 'package:vowl/features/roleplay/situational_response/presentation/widgets/situational_response_instruction.dart';
import 'package:vowl/features/roleplay/situational_response/presentation/widgets/situational_response_scene_display.dart';
import 'package:vowl/features/roleplay/situational_response/presentation/widgets/situational_response_explanation_panel.dart';
import 'package:vowl/features/roleplay/situational_response/presentation/widgets/tension_wave_painter.dart';

class SituationalResponseScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SituationalResponseScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.situationalResponse,
  });

  @override
  State<SituationalResponseScreen> createState() => _SituationalResponseScreenState();
}

class _SituationalResponseScreenState extends State<SituationalResponseScreen> with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  late AnimationController _timerController;
  late AnimationController _pulseController;
  
  int _lastProcessedIndex = -1;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int? _selectedOrbIndex;
  
  // Real-time ticking sound throttling
  int _lastTickSecond = -1;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _timerController.addListener(() {
      setState(() {});
      _checkTickWarnings();
    });

    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _triggerTimeoutFailure();
      }
    });

    context.read<RoleplayBloc>().add(FetchRoleplayQuests(gameType: widget.gameType, level: widget.level));
  }

  @override
  void dispose() {
    _timerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(RoleplayQuest quest) {
    _soundService.playTts(quest.scene ?? "");
  }

  void _checkTickWarnings() {
    if (_isAnswered) return;
    
    // Warn when time is running out (less than 4 seconds remaining)
    final double elapsedRatio = _timerController.value;
    final int remainingSec = (12 * (1.0 - elapsedRatio)).ceil();
    
    if (remainingSec <= 4 && remainingSec > 0 && remainingSec != _lastTickSecond) {
      _lastTickSecond = remainingSec;
      _hapticService.selection();
      _soundService.playHint(); // Play warning beep
    }
  }

  void _startTimer() {
    _timerController.forward(from: 0.0);
    _lastTickSecond = -1;
  }

  void _stopTimer() {
    _timerController.stop();
  }

  void _triggerTimeoutFailure() {
    if (_isAnswered) return;
    _stopTimer();
    _hapticService.error();
    _soundService.playWrong();
    
    setState(() {
      _isAnswered = true;
      _isCorrect = false;
      _selectedOrbIndex = null;
    });
    
    context.read<RoleplayBloc>().add(SubmitAnswer(false));
  }

  void _onOrbTap(int index, int correctIndex) {
    if (_isAnswered) return;
    _stopTimer();
    
    final isCorrect = index == correctIndex;
    setState(() {
      _isAnswered = true;
      _isCorrect = isCorrect;
      _selectedOrbIndex = index;
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
              _selectedOrbIndex = null;
            });
            _startTimer();
            // Auto play dialogue context
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          }
        }
        if (state is RoleplayGameComplete) {
          _stopTimer();
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'SOCIAL GENIUS!',
            enableDoubleUp: true,
          );
        } else if (state is RoleplayGameOver) {
          _stopTimer();
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<RoleplayBloc>().add(RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final quest = (state is RoleplayLoaded) ? state.currentQuest : null;
        final options = quest?.options ?? [];

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
                      SituationalResponseInstruction(primaryColor: theme.primaryColor),
                      SizedBox(height: 16.h),
                      SituationalResponseSceneDisplay(
                        quest: quest,
                        color: theme.primaryColor,
                        isDark: isDark,
                        onListen: () => _triggerAutoPlay(quest),
                      ),
                      SizedBox(height: 24.h),
                      _buildReactionZone(options, quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark),
                      SizedBox(height: 20.h),
                      
                      // Explanations Card when answered
                      AnimatedCrossFade(
                        firstChild: const SizedBox(),
                        secondChild: SituationalResponseExplanationPanel(
                          quest: quest,
                          isDark: isDark,
                          isCorrect: _isCorrect,
                        ),
                        crossFadeState: _isAnswered
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 450),
                      ),
                      SizedBox(height: 80.h), // Safe spacing for base layouts
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildReactionZone(List<String> options, int correctIndex, Color color, bool isDark) {
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
          final double cx = constraints.maxWidth / 2;
          final double cy = constraints.maxHeight / 2;
          final double r = 115.h;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Radar sweep tension background
              Positioned.fill(
                child: CustomPaint(
                  painter: TensionWavePainter(
                    progress: _timerController.value,
                    pulseValue: _pulseController.value,
                    themeColor: color,
                    isAnswered: _isAnswered,
                    isCorrect: _isCorrect,
                  ),
                ),
              ),

              // Central Tension Core
              _buildTensionCoreCenter(cx, cy, color, isDark),

              // Orbiting Reaction Orbs arranged symmetrically using trigonometry
              ...List.generate(options.length, (i) {
                final double angle = -math.pi / 2 + (i * (2 * math.pi / options.length));
                final double targetX = cx + r * math.cos(angle);
                final double targetY = cy + r * math.sin(angle);

                return _buildOrbNode(i, options[i], targetX, targetY, cx, cy, correctIndex, color, isDark);
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTensionCoreCenter(double cx, double cy, Color color, bool isDark) {
    Color coreColor = color;
    IconData coreIcon = Icons.bolt_rounded;
    String label = "MATRIX ACTIVE";

    if (_isAnswered) {
      if (_isCorrect ?? false) {
        coreColor = Colors.greenAccent;
        coreIcon = Icons.verified_rounded;
        label = "SYNERGY LOCKED";
      } else {
        coreColor = Colors.redAccent;
        coreIcon = Icons.warning_amber_rounded;
        label = "TENSION OVERLOAD";
      }
    } else {
      coreColor = Color.lerp(color, const Color(0xFFFF3366), _timerController.value) ?? color;
      if (_timerController.value > 0.7) {
        coreIcon = Icons.priority_high_rounded;
        label = "TENSION DANGER";
      }
    }

    final double speedFactor = 1.0 + (_timerController.value * 3.5);
    final double pulseScale = 1.0 + (0.08 * math.sin(_pulseController.value * speedFactor * math.pi * 2)).abs();

    return Positioned(
      left: cx - 60.r,
      top: cy - 60.r,
      child: Transform.scale(
        scale: pulseScale,
        child: Container(
          width: 120.r,
          height: 120.r,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F0F1F) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: coreColor, width: 3.5),
            boxShadow: [
              BoxShadow(
                color: coreColor.withValues(alpha: 0.4),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(coreIcon, color: coreColor, size: 40.r),
              SizedBox(height: 6.h),
              Text(
                label,
                style: GoogleFonts.shareTechMono(
                  fontSize: 8.sp,
                  fontWeight: FontWeight.bold,
                  color: coreColor,
                  letterSpacing: 1,
                ),
              ),
              if (!_isAnswered) ...[
                SizedBox(height: 4.h),
                Text(
                  "${(12 * (1.0 - _timerController.value)).ceil()}s",
                  style: GoogleFonts.shareTechMono(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                    color: coreColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrbNode(
    int index,
    String text,
    double targetX,
    double targetY,
    double cx,
    double cy,
    int correctIndex,
    Color color,
    bool isDark,
  ) {
    final bool isSelected = _selectedOrbIndex == index;
    final bool hideOther = _isAnswered && !isSelected;

    // Fly animation coords if selected
    final double currentX = _isAnswered && isSelected ? cx : targetX;
    final double currentY = _isAnswered && isSelected ? cy : targetY;

    Color orbColor = color;
    if (_isAnswered && isSelected) {
      orbColor = (_isCorrect ?? false) ? Colors.greenAccent : Colors.redAccent;
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: Curves.fastOutSlowIn,
      left: currentX - 54.r,
      top: currentY - 54.r,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: hideOther ? 0.0 : 1.0,
        child: ScaleButton(
          onTap: () => _onOrbTap(index, correctIndex),
          child: Container(
            width: 108.r,
            height: 108.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF0F0F1B) : Colors.white,
              border: Border.all(
                color: isSelected ? orbColor : color.withValues(alpha: 0.5),
                width: isSelected ? 3.0 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isSelected ? orbColor : color).withValues(alpha: 0.15),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(12.r),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ).animate(
          onPlay: (c) => c.repeat(),
        ).moveY(
          begin: -3,
          end: 3,
          duration: (1.5 + index * 0.4).seconds,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }
}
