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

class _MedicalConsultScreenState extends State<MedicalConsultScreen>with TickerProviderStateMixin, RoleplayGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

    
  late AnimationController _sweepController;
  late AnimationController _pulseController;

    final ValueNotifier<List<String>> _diagnosedSymptoms = ValueNotifier([]);
  final ScrollController _scrollController = ScrollController();
        
  // Drag coordinate for physical scanning lens
  final ValueNotifier<Offset> _scanOffset = ValueNotifier(Offset.zero);

  // Set of unlocked nodes that are locked/resolved by the scanner lens
  final ValueNotifier<List<String>> _scannedGlitches = ValueNotifier([]);

  @override
  void initState() {
    super.initState();
    isAnsweredNotifier.addListener(() {
      if (isAnsweredNotifier.value && mounted && _scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    initRoleplayGame();
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _pulseController.dispose();
    _diagnosedSymptoms.dispose();
                    _scanOffset.dispose();
    _scannedGlitches.dispose();
    _scrollController.dispose();
    disposeRoleplayGame();
    super.dispose();
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
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;

    _scanOffset.value += details.delta;

    // Check proximity against all symptoms mentioned in the complaint list
    for (String s in availableSymptoms) {
      final Offset target = _getAnatomicalOffset(s);
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

  void _onSymptomTapped(String symptom) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;

    // Check if item is scanned before selection
    if (!_scannedGlitches.value.contains(symptom)) {
      hapticService.error();
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

  void _submitDiagnosis(String correctAnswer) {
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
      // Wait for Phase 2
    } else {
      hapticService.error();
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      context.read<RoleplayBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (isAnsweredNotifier.value) return;

    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = nailedIt;

    if (nailedIt) {
      hapticService.success();
      soundService.playCorrect();
      context.read<RoleplayBloc>().add(SubmitAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();
      context.read<RoleplayBloc>().add(SubmitAnswer(false));
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
            _scanOffset,
            isFirstStagePassedNotifier,
          ]),
          builder: (context, _) {
            return RoleplayBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered:
                  isAnsweredNotifier.value &&
                  (isCorrectNotifier.value != null || !isFirstStagePassedNotifier.value),
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
                        return Stack(
                          children: [
                            RawScrollbar(
                              controller: _scrollController,
                              thumbColor: theme.primaryColor.withValues(
                                alpha: 0.5,
                              ),
                              radius: Radius.circular(8.r),
                              thickness: 4.w,
                              child: CustomScrollView(
                                physics: const BouncingScrollPhysics(),
                                slivers: [
                                  SliverFillRemaining(
                                    hasScrollBody: true,
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              final isCompact =
                                                  constraints.maxHeight < 580;
                                              return Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 16.w,
                                                  vertical: isCompact
                                                      ? 5.h
                                                      : 10.h,
                                                ),
                                                child: Column(
                                                  children: [
                                                    MedicalConsultInstruction(
                                                      primaryColor:
                                                          theme.primaryColor,
                                                      instruction:
                                                          InstructionHelper.getInstruction(
                                                            quest,
                                                          ),
                                                    ),
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 10.h
                                                          : 16.h,
                                                    ),
                                                    MedicalConsultPatientRecord(
                                                      prompt:
                                                          quest.prompt ?? "",
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                    ),
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 16.h
                                                          : 20.h,
                                                    ),

                                                    // Holographic scan bay
                                                    MedicalConsultScanBay(
                                                      symptoms: symptoms,
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                      scanOffset:
                                                          _scanOffset.value,
                                                      scannedGlitches:
                                                          _scannedGlitches
                                                              .value,
                                                      sweepAnimation:
                                                          _sweepController,
                                                      onScanUpdate:
                                                          _onScanUpdate,
                                                    ),
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 16.h
                                                          : 24.h,
                                                    ),

                                                    // Diagnostic symptoms tiles
                                                    MedicalConsultDiagnosticTray(
                                                      symptoms: symptoms,
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                      scannedGlitches:
                                                          _scannedGlitches
                                                              .value,
                                                      diagnosedSymptoms:
                                                          _diagnosedSymptoms
                                                              .value,
                                                      isAnswered:
                                                          isAnsweredNotifier.value &&
                                                          (isCorrectNotifier.value !=
                                                                  null ||
                                                              !isFirstStagePassedNotifier
                                                                  .value),
                                                      isCorrect:
                                                          isCorrectNotifier.value,
                                                      onSymptomTapped:
                                                          _onSymptomTapped,
                                                    ),
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 20.h
                                                          : 28.h,
                                                    ),

                                                    // Submit controls
                                                    if (!isAnsweredNotifier.value &&
                                                        _diagnosedSymptoms
                                                            .value
                                                            .isNotEmpty)
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          ScaleButton(
                                                            onTap:
                                                                _clearDiagnosis,
                                                            child: Container(
                                                              padding:
                                                                  EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        isCompact
                                                                        ? 16.w
                                                                        : 24.w,
                                                                    vertical:
                                                                        isCompact
                                                                        ? 10.h
                                                                        : 12.h,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: theme
                                                                    .primaryColor
                                                                    .withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      30.r,
                                                                    ),
                                                                border: Border.all(
                                                                  color: theme
                                                                      .primaryColor
                                                                      .withValues(
                                                                        alpha:
                                                                            0.3,
                                                                      ),
                                                                ),
                                                              ),
                                                              child: Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .refresh_rounded,
                                                                    color: theme
                                                                        .primaryColor,
                                                                    size:
                                                                        isCompact
                                                                        ? 16.r
                                                                        : 18.r,
                                                                  ),
                                                                  SizedBox(
                                                                    width: 6.w,
                                                                  ),
                                                                  Text(
                                                                    "RESET SCAN",
                                                                    style: TextStyle(
                                                                      fontFamily:
                                                                          'Outfit',
                                                                      fontSize:
                                                                          isCompact
                                                                          ? 10.sp
                                                                          : 12.sp,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: theme
                                                                          .primaryColor,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: isCompact
                                                                ? 10.w
                                                                : 16.w,
                                                          ),
                                                          ScaleButton(
                                                            onTap: () =>
                                                                _submitDiagnosis(
                                                                  quest.correctAnswer ??
                                                                      "",
                                                                ),
                                                            child: Container(
                                                              padding:
                                                                  EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        isCompact
                                                                        ? 20.w
                                                                        : 32.w,
                                                                    vertical:
                                                                        isCompact
                                                                        ? 10.h
                                                                        : 12.h,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      30.r,
                                                                    ),
                                                                gradient: LinearGradient(
                                                                  colors: [
                                                                    theme
                                                                        .primaryColor,
                                                                    theme
                                                                        .primaryColor
                                                                        .withValues(
                                                                          alpha:
                                                                              0.8,
                                                                        ),
                                                                  ],
                                                                ),
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    color: theme
                                                                        .primaryColor
                                                                        .withValues(
                                                                          alpha:
                                                                              0.35,
                                                                        ),
                                                                    blurRadius:
                                                                        isCompact
                                                                        ? 10
                                                                        : 15,
                                                                  ),
                                                                ],
                                                              ),
                                                              child: Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .medical_services_rounded,
                                                                    color: Colors
                                                                        .white,
                                                                    size:
                                                                        isCompact
                                                                        ? 16.r
                                                                        : 18.r,
                                                                  ),
                                                                  SizedBox(
                                                                    width: 6.w,
                                                                  ),
                                                                  Text(
                                                                    "CONFIRM DIAGNOSIS",
                                                                    style: TextStyle(
                                                                      fontFamily:
                                                                          'Outfit',
                                                                      fontSize:
                                                                          isCompact
                                                                          ? 10.sp
                                                                          : 12.sp,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Colors
                                                                          .white,
                                                                      letterSpacing:
                                                                          1.5,
                                                                    ),
                                                                  ),
                                                                ],
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
                                                        height: isCompact
                                                            ? 12.h
                                                            : 20.h,
                                                      ),
                                                      MedicalConsultBodyDiagram(
                                                        quest: quest,
                                                        primaryColor:
                                                            theme.primaryColor,
                                                        isDark: isDark,
                                                      ),
                                                    ],
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 20.h
                                                          : 40.h,
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SliverToBoxAdapter(
                                    child: SizedBox(
                                      height:
                                          (isFirstStagePassedNotifier.value &&
                                              !isAnsweredNotifier.value)
                                          ? 380.h
                                          : 60.h,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isFirstStagePassedNotifier.value && !isAnsweredNotifier.value)
                              SpeakToConfirmOverlay(
                                expectedText:
                                    quest.correctAnswer ??
                                    _diagnosedSymptoms.value.join(', '),
                                primaryColor: theme.primaryColor,
                                isPositioned: true,
                                onConfirmed: () {
                                  context.read<RoleplayBloc>().add(
                                    const RoleplaySpeakConfirmed(5),
                                  );
                                  _submitVerbalEvaluation(true);
                                },
                                onSkipped: () => _submitVerbalEvaluation(false),
                              ),
                          ],
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
