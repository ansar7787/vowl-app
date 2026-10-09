import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'dart:math' as math;
import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/mixins/roleplay_game_screen_mixin.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_event.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';
import 'package:vowl/features/roleplay/presentation/layout/roleplay_base_layout.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/roleplay/medical_consult/presentation/widgets/medical_consult_instruction.dart';
import 'package:vowl/features/roleplay/medical_consult/presentation/widgets/medical_consult_patient_record.dart';
import 'package:vowl/features/roleplay/medical_consult/presentation/widgets/medical_consult_scan_bay.dart';
import 'package:vowl/features/roleplay/medical_consult/presentation/widgets/medical_consult_diagnostic_tray.dart';
import 'package:vowl/features/roleplay/medical_consult/presentation/widgets/medical_consult_body_diagram.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';

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
    with
        TickerProviderStateMixin,
        GameScreenMixin<MedicalConsultScreen>,
        RoleplayGameScreenMixin<MedicalConsultScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  late AnimationController _sweepController;

  final ValueNotifier<List<String>> _diagnosedSymptoms = ValueNotifier([]);
  final ScrollController _scrollController = ScrollController();

  // Drag coordinate for physical scanning lens
  final ValueNotifier<Offset> _scanOffset = ValueNotifier(Offset.zero);
  final ValueNotifier<bool> _isDragging = ValueNotifier(false);

  // Set of unlocked nodes that are locked/resolved by the scanner lens
  final ValueNotifier<List<String>> _scannedGlitches = ValueNotifier([]);

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();

    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    initRoleplayGame();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      if (_sweepController.isAnimating) _sweepController.stop();
    } else {
      if (!_sweepController.isAnimating) _sweepController.repeat();
    }
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _diagnosedSymptoms.dispose();
    _scanOffset.dispose();
    _scannedGlitches.dispose();
    _isDragging.dispose();
    _scrollController.dispose();
    disposeRoleplayGame();
    super.dispose();
  }

  Offset _getAnatomicalOffset(String text, int index, int total) {
    final lower = text.toLowerCase();
    Offset baseOffset = Offset.zero;
    bool found = true;

    if (lower.contains("head") ||
        lower.contains("brain") ||
        lower.contains("headache") ||
        lower.contains("vision") ||
        lower.contains("ear") ||
        lower.contains("throat") ||
        lower.contains("dizzy") ||
        lower.contains("sinus") ||
        lower.contains("nose") ||
        lower.contains("migraine") ||
        lower.contains("concussion") ||
        lower.contains("sensor") ||
        lower.contains("sensory")) {
      baseOffset = Offset(0, -95.h);
    } else if (lower.contains("left limb") ||
        lower.contains("left arm") ||
        lower.contains("left hand") ||
        lower.contains("shoulder")) {
      baseOffset = Offset(-64.w, -25.h);
    } else if (lower.contains("right wing") ||
        lower.contains("right limb") ||
        lower.contains("right arm") ||
        lower.contains("right hand")) {
      baseOffset = Offset(64.w, -25.h);
    } else if (lower.contains("core") ||
        lower.contains("central") ||
        lower.contains("chest") ||
        lower.contains("heart") ||
        lower.contains("breath") ||
        lower.contains("palpitation") ||
        lower.contains("cough") ||
        lower.contains("rib")) {
      baseOffset = Offset(0, -25.h);
    } else if (lower.contains("stomach") ||
        lower.contains("abdomen") ||
        lower.contains("nausea") ||
        lower.contains("constipation") ||
        lower.contains("diarrhea") ||
        lower.contains("reflux") ||
        lower.contains("bloat") ||
        lower.contains("appetite") ||
        lower.contains("cramp")) {
      baseOffset = Offset(0, 30.h);
    } else if (lower.contains("back") || lower.contains("spine")) {
      baseOffset = Offset(30.w, 10.h);
    } else if (lower.contains("left leg") ||
        lower.contains("left foot") ||
        lower.contains("ankle") ||
        lower.contains("knee")) {
      baseOffset = Offset(-32.w, 90.h);
    } else if (lower.contains("right leg") ||
        lower.contains("right foot") ||
        lower.contains("joint")) {
      baseOffset = Offset(32.w, 90.h);
    } else {
      found = false;
    }

    double angle = (index / (total > 0 ? total : 1)) * 2 * 3.141592653589793;

    if (!found) {
      double radius = 120.h;
      baseOffset = Offset(radius * math.cos(angle), radius * math.sin(angle));
    } else {
      double jitterRadius = 18.w;
      baseOffset = Offset(
        baseOffset.dx + jitterRadius * math.cos(angle),
        baseOffset.dy + jitterRadius * math.sin(angle),
      );
    }

    return baseOffset;
  }

  void _onScanUpdate(
    DragUpdateDetails details,
    List<String> availableSymptoms,
  ) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;

    final Offset newOffset = _scanOffset.value + details.delta;

    // Calculate dynamic boundaries (ScanBay is 1.sw x 330.h, lens is 100.r)
    // Origin is center, so max travel is half width/height minus half lens size
    final double maxX = (1.sw / 2) - 50.w;
    final double maxY = (330.h / 2) - 50.h;

    _scanOffset.value = Offset(
      newOffset.dx.clamp(-maxX, maxX),
      newOffset.dy.clamp(-maxY, maxY),
    );

    // Check proximity against all symptoms mentioned in the complaint list
    for (int i = 0; i < availableSymptoms.length; i++) {
      String s = availableSymptoms[i];
      final Offset target = _getAnatomicalOffset(
        s,
        i,
        availableSymptoms.length,
      );
      final double distance = (target - _scanOffset.value).distance;

      // 36r relative proximity locking boundary
      if (distance < 36.r) {
        if (!_scannedGlitches.value.contains(s)) {
          hapticService.selection();
          soundService.playHint(); // Play biometric heartbeat scan pulse
          final glitches = List<String>.from(_scannedGlitches.value);
          glitches.add(s);
          _scannedGlitches.value = glitches;
        }
      }
    }
  }

  void _onSymptomScannedDirectly(String symptom) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;

    if (!_scannedGlitches.value.contains(symptom)) {
      hapticService.selection();
      soundService.playHint(); // Play biometric heartbeat scan pulse
      final glitches = List<String>.from(_scannedGlitches.value);
      glitches.add(symptom);
      _scannedGlitches.value = glitches;
    }
  }

  void _onSymptomTapped(String symptom) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;

    // Check if item is scanned before selection
    if (!_scannedGlitches.value.contains(symptom)) {
      hapticService.error();
      CustomSnackBar.show(
        context: context,
        type: CustomSnackBarType.warning,
        message:
            "Drag the scanner lens over the patient to unlock diagnostics!",
      );
      return;
    }

    hapticService.selection();
    final current = List<String>.from(_diagnosedSymptoms.value);
    if (current.contains(symptom)) {
      current.remove(symptom);
    } else {
      current.add(symptom);
    }
    _diagnosedSymptoms.value = current;
  }

  void _clearDiagnosis() {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;
    hapticService.selection();
    _diagnosedSymptoms.value = [];
    _scannedGlitches.value = [];
    _scanOffset.value = Offset.zero;
  }

  void _submitDiagnosis(String correctAnswer, GameQuest quest) {
    if (isAnsweredNotifier.value ||
        isFirstStagePassedNotifier.value ||
        _diagnosedSymptoms.value.isEmpty) {
      return;
    }

    final targets = correctAnswer
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .toList();
    final current = _diagnosedSymptoms.value
        .map((e) => e.trim().toLowerCase())
        .toList();

    bool isCorrect =
        targets.length == current.length &&
        targets.every((t) => current.contains(t));

    if (isCorrect) {
      hapticService.selection();
      isFirstStagePassedNotifier.value = true;
      _scrollToBottom();
      // Wait for Phase 2
    } else {
      _scrollToBottom();
      submitWrongAnswer(
        quest: quest,
        userAnswer: _diagnosedSymptoms.value.join(', '),
      );
    }
  }

  void _submitVerbalEvaluation(bool nailedIt, GameQuest quest) {
    if (isAnsweredNotifier.value) return;

    if (nailedIt) {
      submitCorrectAnswer();
    } else {
      _scrollToBottom();
      submitWrongAnswer(
        quest: quest,
        userAnswer: _diagnosedSymptoms.value.join(', '),
      );
    }
  }

  @override
  void onQuestionReset() {
    _diagnosedSymptoms.value = [];

    _scanOffset.value = Offset.zero;

    _scannedGlitches.value = [];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('roleplay', level: widget.level);

    return BlocConsumer<RoleplayBloc, RoleplayState>(
      listenWhen: roleplayListenWhen,
      listener: onRoleplayStateChanged,
      builder: (context, state) {
        final quest = (state is RoleplayLoaded) ? state.currentQuest : null;
        final symptoms = quest?.symptoms ?? [];

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _diagnosedSymptoms,
            _scannedGlitches,
            isFirstStagePassedNotifier,
            _isDragging,
          ]),
          builder: (context, _) {
            return RoleplayBaseLayout(
              fullScreenContent: true,
              disablePadding: true,
              gameType: widget.gameType,
              level: widget.level,
              isAnswered:
                  isAnsweredNotifier.value &&
                  (isCorrectNotifier.value != null ||
                      !isFirstStagePassedNotifier.value),
              isCorrect: isCorrectNotifier.value,
              showConfetti: showConfettiNotifier.value,
              onContinue: () =>
                  context.read<RoleplayBloc>().add(NextQuestion()),
              onHint: () =>
                  context.read<RoleplayBloc>().add(RoleplayHintUsed()),
              useScrolling: false,
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return RawScrollbar(
                          controller: _scrollController,
                          thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                          radius: Radius.circular(8.r),
                          thickness: 4.w,
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: _isDragging.value
                                ? const NeverScrollableScrollPhysics()
                                : const BouncingScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                              SliverToBoxAdapter(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final double availableHeight =
                                        MediaQuery.of(context).size.height;
                                    final isCompact = availableHeight < 650;
                                    return Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.w,
                                        vertical: isCompact ? 5.h : 10.h,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          MedicalConsultInstruction(
                                            primaryColor: theme.primaryColor,
                                            instruction:
                                                InstructionHelper.getInstruction(
                                                  quest,
                                                ),
                                          ),
                                          SizedBox(
                                            height: isCompact ? 10.h : 16.h,
                                          ),
                                          MedicalConsultPatientRecord(
                                            prompt: quest.prompt ?? "",
                                            color: theme.primaryColor,
                                            isDark: isDark,
                                          ),
                                          SizedBox(
                                            height: isCompact ? 16.h : 20.h,
                                          ),

                                          // Holographic scan bay
                                          MedicalConsultScanBay(
                                            symptoms: symptoms,
                                            color: theme.primaryColor,
                                            isDark: isDark,
                                            scanOffsetNotifier: _scanOffset,
                                            scannedGlitches:
                                                _scannedGlitches.value,
                                            sweepAnimation: _sweepController,
                                            onScanUpdate: _onScanUpdate,
                                            onScanStart: () =>
                                                _isDragging.value = true,
                                            onScanEnd: () =>
                                                _isDragging.value = false,
                                            onSymptomScannedDirectly:
                                                _onSymptomScannedDirectly,
                                          ),
                                          SizedBox(
                                            height: isCompact ? 16.h : 24.h,
                                          ),

                                          // Diagnostic symptoms tiles
                                          MedicalConsultDiagnosticTray(
                                            symptoms: symptoms,
                                            color: theme.primaryColor,
                                            isDark: isDark,
                                            scannedGlitches:
                                                _scannedGlitches.value,
                                            diagnosedSymptoms:
                                                _diagnosedSymptoms.value,
                                            isAnswered:
                                                isAnsweredNotifier.value &&
                                                (isCorrectNotifier.value !=
                                                        null ||
                                                    !isFirstStagePassedNotifier
                                                        .value),
                                            isCorrect: isCorrectNotifier.value,
                                            onSymptomTapped: _onSymptomTapped,
                                          ),
                                          SizedBox(
                                            height: isCompact ? 20.h : 28.h,
                                          ),

                                          // Submit controls
                                          if (!isAnsweredNotifier.value &&
                                              _diagnosedSymptoms
                                                  .value
                                                  .isNotEmpty)
                                            Column(
                                              children: [
                                                // Confirm Button
                                                ScaleButton(
                                                  onTap: () => _submitDiagnosis(
                                                    quest.correctAnswer ?? "",
                                                    quest,
                                                  ),
                                                  child: Container(
                                                    width: double.infinity,
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          vertical: isCompact
                                                              ? 14.h
                                                              : 16.h,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            30.r,
                                                          ),
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          theme.primaryColor,
                                                          theme.primaryColor
                                                              .withValues(
                                                                alpha: 0.8,
                                                              ),
                                                        ],
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: theme
                                                              .primaryColor
                                                              .withValues(
                                                                alpha: 0.35,
                                                              ),
                                                          blurRadius: isCompact
                                                              ? 10
                                                              : 15,
                                                        ),
                                                      ],
                                                    ),
                                                    child: Center(
                                                      child: FittedBox(
                                                        fit: BoxFit.scaleDown,
                                                        child: Text(
                                                          "Confirm",
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'Outfit',
                                                            fontSize: isCompact
                                                                ? 14.sp
                                                                : 16.sp,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: 12.h),
                                                // Reset Button
                                                ScaleButton(
                                                  onTap: _clearDiagnosis,
                                                  child: Container(
                                                    width: double.infinity,
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          vertical: isCompact
                                                              ? 14.h
                                                              : 16.h,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: theme.primaryColor
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            30.r,
                                                          ),
                                                      border: Border.all(
                                                        color: theme
                                                            .primaryColor
                                                            .withValues(
                                                              alpha: 0.3,
                                                            ),
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: FittedBox(
                                                        fit: BoxFit.scaleDown,
                                                        child: Text(
                                                          "Reset Scan",
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'Outfit',
                                                            fontSize: isCompact
                                                                ? 14.sp
                                                                : 16.sp,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: theme
                                                                .primaryColor,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ).animate().fadeIn(
                                              duration: 300.ms,
                                            ),

                                          // Explanations cards post-selection
                                          if (isAnsweredNotifier.value) ...[
                                            SizedBox(
                                              height: isCompact ? 12.h : 20.h,
                                            ),
                                            MedicalConsultBodyDiagram(
                                              quest: quest,
                                              primaryColor: theme.primaryColor,
                                              isDark: isDark,
                                            ),
                                          ],
                                          SizedBox(
                                            height: isCompact ? 20.h : 40.h,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),

                              if (isFirstStagePassedNotifier.value &&
                                  !isAnsweredNotifier.value)
                                SliverToBoxAdapter(
                                  child: SpeakToConfirmOverlay(
                                    expectedText:
                                        quest.correctAnswer ??
                                        _diagnosedSymptoms.value.join(', '),
                                    primaryColor: theme.primaryColor,
                                    isPositioned: false,
                                    onConfirmed: () {
                                      context.read<RoleplayBloc>().add(
                                        const RoleplaySpeakConfirmed(5),
                                      );
                                      _submitVerbalEvaluation(true, quest);
                                    },
                                    onSkipped: () =>
                                        _submitVerbalEvaluation(false, quest),
                                  ),
                                ),
                              SliverToBoxAdapter(
                                child: SizedBox(
                                  height:
                                      MediaQuery.of(context).viewInsets.bottom >
                                          0
                                      ? MediaQuery.of(
                                              context,
                                            ).viewInsets.bottom +
                                            40.h
                                      : 120.h,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            );
          },
        );
      },
    );
  }
}
