import 'package:flutter/material.dart' hide Ink;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/vowl_button_spinner.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/ml_monetization_controller.dart';
import 'package:vowl/core/utils/ml_services/digital_ink_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/handwriting/handwriting_canvas.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/handwriting_evaluator.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color chalkboardGreen = Color(0xFF1B3B2B);
  static const Color woodBrown = Color(0xFF8B4513);
}

/// Interactive blackboard pedagogical layout for the Kids Handwriting and letter tracing game.
class KidsHandwritingLayout extends StatefulWidget {
  /// The level number of the current session.
  final int level;

  /// The title of the game.
  final String title;

  /// The primary theme accent color.
  final Color primaryColor;

  /// Creates a [KidsHandwritingLayout] widget.
  const KidsHandwritingLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  State<KidsHandwritingLayout> createState() => _KidsHandwritingLayoutState();
}

class _KidsHandwritingLayoutState extends State<KidsHandwritingLayout> {
  static const HandwritingEvaluator _evaluator = HandwritingEvaluator();

  Ink? _currentInk;
  final ValueNotifier<bool> _isChecking = ValueNotifier(false);
  final ValueNotifier<bool> _hasInk = ValueNotifier(false);
  bool? _isCorrect;
  int _attemptsCount = 0;
  String? _lastQuestId;
  final GlobalKey<HandwritingCanvasState> _canvasKey =
      GlobalKey<HandwritingCanvasState>();

  @override
  void dispose() {
    _isChecking.dispose();
    _hasInk.dispose();
        try {
      if (di.sl.isRegistered<KidsTTSService>()) {
        di.sl<KidsTTSService>().stop();
      }
    } catch (_) {}
    super.dispose();
  }

  Future<void> _checkHandwriting(BuildContext context, KidsLoaded state) async {
    if (_currentInk == null || _currentInk!.strokes.isEmpty) {
      di.sl<HapticService>().warning();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'kids_zone.handwriting_draw_first',
              fallback: 'Use chalk to draw on the board first!',
            ),
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
            ),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          backgroundColor: widget.primaryColor,
        ),
      );
      return;
    }

    final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;

    if (!isPremium && _attemptsCount >= 5) {
      MlMonetizationController.attemptFeature(
        context,
        featureIcon: Icons.edit_rounded,
        featureTitle: context.tr(
          'kids_zone.handwriting_title',
          fallback: 'Write & Learn',
        ),
        featureSubtitle: context.tr(
          'kids_zone.handwriting_desc',
          fallback: 'Practice your handwriting on the chalkboard!',
        ),
        adButtonLabel: context.tr(
          'kids_zone.handwriting_ad',
          fallback: 'Watch Ad to Continue',
        ),
        isKidsZone: true,
        onSuccess: () {
          _attemptsCount = 0;
          _performCheck(context, state);
        },
      );
    } else {
      _performCheck(context, state);
    }
  }

  Future<void> _performCheck(BuildContext context, KidsLoaded state) async {
    _isChecking.value = true;
    _attemptsCount++;

    final targetWord = state.currentQuest.question?.trim() ?? '';
    List<String> recognitionResults = const [];

    try {
      final digitalInkService = di.sl<DigitalInkService>();
      recognitionResults = await digitalInkService.recognize(_currentInk!);
    } catch (e) {
      if (di.sl.isRegistered<AppLogger>()) {
        di.sl<AppLogger>().warning(
          'DigitalInkService recognition fallback to geometric evaluation: $e',
          tag: 'KidsHandwriting',
        );
      }
      recognitionResults = const [];
    }

    if (!mounted) return;

    // Use comprehensive evaluator combining candidates, equivalences, and geometric strokes
    final bool correct = _evaluator.evaluate(
      ink: _currentInk!,
      target: targetWord,
      candidates: recognitionResults,
    );

    if (di.sl.isRegistered<AppLogger>()) {
      di.sl<AppLogger>().debug(
        'Handwriting checked for "$targetWord" -> correct: $correct (candidates: $recognitionResults)',
        tag: 'KidsHandwriting',
      );
    }

    _isChecking.value = false;
    _isCorrect = correct;

    if (!mounted || !context.mounted) return;

    // Delegate success/failure feedback (sound chime, haptic pulse, lives & score) to KidsBloc
    context.read<KidsBloc>().add(SubmitKidsAnswer(correct));
  }


  /// Calculates responsive font size based on string length to guarantee zero text overflow.
  double _calculateTargetFontSize(String target) {
    final len = target.length;
    if (len <= 2) return 54.sp;
    if (len <= 4) return 38.sp;
    if (len <= 7) return 30.sp;
    if (len <= 12) return 24.sp;
    if (len <= 20) return 20.sp;
    return 17.sp;
  }

  /// Calculates letter spacing based on text length.
  double _calculateLetterSpacing(String target) {
    final len = target.length;
    if (len <= 2) return 4.0;
    if (len <= 5) return 2.5;
    if (len <= 10) return 1.5;
    return 0.5;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isCompactScreen = screenHeight < 720;

    return KidsGameBaseScreen(
      title: widget.title,
      gameType: 'handwriting',
      level: widget.level,
      primaryColor: widget.primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        // Reset canvas state and clear drawing when the quest changes (next question)
        if (_lastQuestId != state.currentQuest.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _currentInk = null;
              _isCorrect = null;
              _hasInk.value = false;
              if (_isChecking.value) _isChecking.value = false;
              _lastQuestId = state.currentQuest.id;
              _canvasKey.currentState?.clearCanvas();
            }
          });
        }

        if (state.answerStatus == AnswerStatus.unanswered &&
            _isCorrect != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _isCorrect = null;
              _hasInk.value = false;
              if (_isChecking.value) _isChecking.value = false;
              _canvasKey.currentState?.clearCanvas();
            }
          });
        }

        final targetWord = state.currentQuest.question?.trim() ?? '';
        final instruction = state.currentQuest.instruction.trim();
        final targetFontSize = _calculateTargetFontSize(targetWord);
        final targetLetterSpacing = _calculateLetterSpacing(targetWord);

        return LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                // Mascot space reserved by KidsGameBaseScreen (adaptive for short screens)
                SizedBox(
                  height: isCompactScreen
                      ? 50.h
                      : KidsGameBaseScreen.mascotClearanceHeight,
                ),

                // Responsive Flashcard Target Display
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      maxWidth: 420.w,
                      minHeight: isCompactScreen ? 72.h : 86.h,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: isCompactScreen ? 8.h : 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(
                        color: widget.primaryColor.withValues(alpha: 0.35),
                        width: 3.5.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.primaryColor.withValues(alpha: 0.18),
                          blurRadius: 14,
                          offset: Offset(0, 6.h),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Universal Guidance Label and Audio Listen Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              context.tr(
                                'kids_zone.handwriting_universal_prompt',
                                fallback: 'Trace & Write',
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Semantics(
                              button: true,
                              label: 'Listen to instruction',
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16.r),
                                onTap: () {
                                  di.sl<HapticService>().light();
                                  final speakText = instruction.isNotEmpty
                                      ? instruction
                                      : targetWord;
                                  di.sl<KidsTTSService>().speak(speakText);
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(4.r),
                                  child: Icon(
                                    LucideIcons.volume2,
                                    size: 16.r,
                                    color: widget.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),

                        // Target Character / Stroke / Word Display
                        SelectableText(
                          targetWord,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: targetFontSize,
                            fontWeight: FontWeight.w700,
                            color: widget.primaryColor,
                            letterSpacing: targetLetterSpacing,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().scale(delay: 150.ms, curve: Curves.easeOutCubic),

                SizedBox(height: isCompactScreen ? 10.h : 14.h),

                // Classroom Blackboard Slate Canvas Frame
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 520.w),
                        child: HandwritingCanvas(
                          key: _canvasKey,
                          ghostText: targetWord,
                          canvasColor: _LocalPalette.chalkboardGreen,
                          strokeColor: Colors.white,
                          borderColor: _LocalPalette.woodBrown,
                          borderWidth: isCompactScreen ? 8.w : 10.w,
                          showGuidelines: true,
                          initialShowGuide: widget.level <= 10,
                          onStrokeCountChanged: (count) {
                            _hasInk.value = count > 0;
                          },
                          onInkUpdated: (ink) {
                            if (state.answerStatus.isAnswered || _isChecking.value) return;
                            _currentInk = ink;
                            _hasInk.value = ink.strokes.isNotEmpty;
                            if (_isCorrect != null) _isCorrect = null;
                          },
                          onClear: () {
                            if (state.answerStatus.isAnswered || _isChecking.value) return;
                            _currentInk = null;
                            _hasInk.value = false;
                            _isCorrect = null;
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: isCompactScreen ? 10.h : 14.h),

                // Primary Action Button (Check My Answer)
                if (state.answerStatus == AnswerStatus.unanswered)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _isChecking,
                      builder: (context, isChecking, _) {
                        return ValueListenableBuilder<bool>(
                          valueListenable: _hasInk,
                          builder: (context, hasInk, _) {
                            final Color buttonColor = isChecking
                                ? Colors.grey.shade400
                                : (hasInk
                                    ? widget.primaryColor
                                    : widget.primaryColor.withValues(alpha: 0.65));

                            return ScaleButton(
                              onTap: isChecking
                                  ? null
                                  : () => _checkHandwriting(context, state),
                              child: Container(
                                width: double.infinity,
                                constraints: BoxConstraints(
                                  maxWidth: 420.w,
                                  minHeight: isCompactScreen ? 54.h : 60.h,
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: isCompactScreen ? 14.h : 16.h,
                                ),
                                decoration: BoxDecoration(
                                  color: buttonColor,
                                  borderRadius: BorderRadius.circular(28.r),
                                  boxShadow: [
                                    if (!isChecking && hasInk)
                                      BoxShadow(
                                        color: widget.primaryColor.withValues(
                                          alpha: 0.45,
                                        ),
                                        offset: Offset(0, 6.h),
                                        blurRadius: 14,
                                      ),
                                  ],
                                ),
                                child: Center(
                                  child: isChecking
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            VowlButtonSpinner(
                                              color: Colors.white,
                                              size: 22.h,
                                            ),
                                            SizedBox(width: 10.w),
                                            Text(
                                              context.tr(
                                                'kids_zone.checking_writing',
                                                fallback: 'Checking...',
                                              ),
                                              style: TextStyle(
                                                fontFamily: 'Outfit',
                                                fontSize: 18.sp,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Text(
                                          context.tr(
                                            'common.check',
                                            fallback: 'Check',
                                          ),
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: isCompactScreen ? 20.sp : 22.sp,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                SizedBox(height: isCompactScreen ? 14.h : 22.h),
              ],
            );
          },
        );
      },
    );
  }
}
