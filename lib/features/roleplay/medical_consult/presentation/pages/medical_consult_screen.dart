import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_event.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';
import 'package:vowl/features/roleplay/presentation/layout/roleplay_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';
import 'package:vowl/features/roleplay/medical_consult/presentation/widgets/medical_consult_instruction.dart';
import 'package:vowl/features/roleplay/medical_consult/presentation/widgets/medical_consult_patient_record.dart';
import 'package:vowl/features/roleplay/medical_consult/presentation/widgets/medical_consult_scan_bay.dart';
import 'package:vowl/features/roleplay/medical_consult/presentation/widgets/medical_consult_diagnostic_tray.dart';
import 'package:vowl/features/roleplay/medical_consult/presentation/widgets/medical_consult_explanation_card.dart';

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

class _MedicalConsultScreenState extends State<MedicalConsultScreen>
    with TickerProviderStateMixin {
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

    context.read<RoleplayBloc>().add(
      FetchRoleplayQuests(gameType: widget.gameType, level: widget.level),
    );
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

  Offset _getAnatomicalOffset(String text) {
    final lower = text.toLowerCase();
    if (lower.contains("head") ||
        lower.contains("brain") ||
        lower.contains("sensor") ||
        lower.contains("sensory")) {
      return Offset(0, -95.h);
    }
    if (lower.contains("left limb") ||
        lower.contains("left arm") ||
        lower.contains("left hand")) {
      return Offset(-64.w, -5.h);
    }
    if (lower.contains("right wing") ||
        lower.contains("right limb") ||
        lower.contains("right arm") ||
        lower.contains("right hand")) {
      return Offset(64.w, -5.h);
    }
    if (lower.contains("core") ||
        lower.contains("central") ||
        lower.contains("chest") ||
        lower.contains("heart")) {
      return Offset(0, -25.h);
    }
    if (lower.contains("left leg") || lower.contains("left foot")) {
      return Offset(-32.w, 90.h);
    }
    return Offset(32.w, 90.h); // Default Right Leg coordinate
  }

  void _onScanUpdate(
    DragUpdateDetails details,
    List<String> availableSymptoms,
  ) {
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

    final targets = correctAnswer
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .toList();
    final current = _diagnosedSymptoms
        .map((e) => e.trim().toLowerCase())
        .toList();

    bool isCorrect =
        targets.length == current.length &&
        targets.every((t) => current.contains(t));

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
        } else 
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
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxHeight < 580;
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: isCompact ? 5.h : 10.h,
                      ),
                      child: Column(
                        children: [
                          MedicalConsultInstruction(
                            primaryColor: theme.primaryColor,
                            instruction: quest.instruction,
                          ),
                          SizedBox(height: isCompact ? 10.h : 16.h),
                          MedicalConsultPatientRecord(
                            prompt: quest.prompt ?? "",
                            color: theme.primaryColor,
                            isDark: isDark,
                          ),
                          SizedBox(height: isCompact ? 16.h : 20.h),

                          // Holographic scan bay
                          MedicalConsultScanBay(
                            symptoms: symptoms,
                            color: theme.primaryColor,
                            isDark: isDark,
                            scanOffset: _scanOffset,
                            scannedGlitches: _scannedGlitches,
                            sweepAnimation: _sweepController,
                            onScanUpdate: _onScanUpdate,
                          ),
                          SizedBox(height: isCompact ? 16.h : 24.h),

                          // Diagnostic symptoms tiles
                          MedicalConsultDiagnosticTray(
                            symptoms: symptoms,
                            color: theme.primaryColor,
                            isDark: isDark,
                            scannedGlitches: _scannedGlitches,
                            diagnosedSymptoms: _diagnosedSymptoms,
                            isAnswered: _isAnswered,
                            isCorrect: _isCorrect,
                            onSymptomTapped: _onSymptomTapped,
                          ),
                          SizedBox(height: isCompact ? 20.h : 28.h),

                          // Submit controls
                          if (!_isAnswered && _diagnosedSymptoms.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ScaleButton(
                                  onTap: _clearDiagnosis,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isCompact ? 16.w : 24.w,
                                      vertical: isCompact ? 10.h : 12.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(30.r),
                                      border: Border.all(
                                        color: theme.primaryColor.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.refresh_rounded,
                                          color: theme.primaryColor,
                                          size: isCompact ? 16.r : 18.r,
                                        ),
                                        SizedBox(width: 6.w),
                                        Text(
                                          "RESET SCAN",
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: isCompact ? 10.sp : 12.sp,
                                            fontWeight: FontWeight.bold,
                                            color: theme.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: isCompact ? 10.w : 16.w),
                                ScaleButton(
                                  onTap: () => _submitDiagnosis(
                                    quest.correctAnswer ?? "",
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isCompact ? 20.w : 32.w,
                                      vertical: isCompact ? 10.h : 12.h,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30.r),
                                      gradient: LinearGradient(
                                        colors: [
                                          theme.primaryColor,
                                          theme.primaryColor.withValues(
                                            alpha: 0.8,
                                          ),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.primaryColor.withValues(
                                            alpha: 0.35,
                                          ),
                                          blurRadius: isCompact ? 10 : 15,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.medical_services_rounded,
                                          color: Colors.white,
                                          size: isCompact ? 16.r : 18.r,
                                        ),
                                        SizedBox(width: 6.w),
                                        Text(
                                          "CONFIRM DIAGNOSIS",
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: isCompact ? 10.sp : 12.sp,
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
                            secondChild: MedicalConsultExplanationCard(
                              quest: quest,
                              isDark: isDark,
                              isCorrect: _isCorrect,
                            ),
                            crossFadeState: _isAnswered
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 400),
                          ),
                          SizedBox(height: isCompact ? 40.h : 80.h),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
