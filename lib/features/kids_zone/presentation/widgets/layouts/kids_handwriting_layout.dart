import 'dart:async';
import 'package:flutter/material.dart' hide Ink;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/ml_monetization_controller.dart';
import 'package:vowl/core/utils/ml_services/digital_ink_service.dart';
import 'package:vowl/core/utils/widgets/handwriting_canvas.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/presentation/widgets/vowl_button_spinner.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class KidsHandwritingLayout extends StatefulWidget {
  final int level;
  final String title;
  final Color primaryColor;

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
  Ink? _currentInk;
  bool _isChecking = false;
  bool? _isCorrect;
  int _attemptsCount = 0;
  String? _lastQuestId;
  final GlobalKey<HandwritingCanvasState> _canvasKey =
      GlobalKey<HandwritingCanvasState>();



  Future<void> _checkHandwriting(BuildContext context, KidsLoaded state) async {
    if (_currentInk == null || _currentInk!.strokes.isEmpty) return;

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
          fallback: 'Practice your handwriting!',
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
    setState(() => _isChecking = true);
    _attemptsCount++;

    final targetWord = state.currentQuest.question?.toUpperCase() ?? '';
    final results = await di.sl<DigitalInkService>().recognize(_currentInk!);

    if (!mounted) return;

    bool correct = false;
    for (final result in results) {
      if (result.toUpperCase().trim() == targetWord) {
        correct = true;
        break;
      }
    }

    setState(() {
      _isChecking = false;
      _isCorrect = correct;
    });

    if (!mounted || !context.mounted) return;

    // Delegate success/failure and lives/score management to KidsBloc
    context.read<KidsBloc>().add(SubmitKidsAnswer(correct));
  }

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: widget.title,
      gameType: 'handwriting',
      level: widget.level,
      primaryColor: widget.primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        // Reset canvas state if the quest changes (next question)
        if (_lastQuestId != state.currentQuest.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _currentInk = null;
                _isCorrect = null;
                _isChecking = false;
                _lastQuestId = state.currentQuest.id;
              });
            }
          });
        }

        if (state.lastAnswerCorrect == null && _isCorrect != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isCorrect = null;
                _isChecking = false;
              });
              _canvasKey.currentState?.clearCanvas();
            }
          });
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final targetWord = state.currentQuest.question ?? '';


        return Column(
          children: [
            SizedBox(
              height: 120.h,
            ), // Mascot space reserved by KidsGameBaseScreen
            // Flashcard Target Word Display
            Container(
              width: 300.w,
              padding: EdgeInsets.symmetric(vertical: 20.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(32.r),
                border: Border.all(
                  color: widget.primaryColor.withValues(alpha: 0.3),
                  width: 4.w,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryColor.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: Offset(0, 8.h),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    context.tr(
                      'kids_zone.handwriting_instruction',
                      fallback: 'Draw this word:',
                    ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  Text(
                    targetWord,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 64.sp,
                      fontWeight: FontWeight.w900,
                      color: widget.primaryColor,
                      letterSpacing: 6,
                    ),
                  ),
                ],
              ),
            ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),

            SizedBox(height: 16.h),

            // Chalkboard Canvas Frame
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 24.w),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: Offset(0, 8.h),
                    ),
                  ],
                ),
                child: HandwritingCanvas(
                  key: _canvasKey,
                  canvasColor: const Color(0xFF1B3B2B), // Deep chalkboard green
                  strokeColor: Colors.white, // White chalk
                  borderColor: const Color(0xFF8B4513), // Wood brown frame
                  borderWidth: 12.w, // Thick wood frame
                  onInkUpdated: (ink) {
                    if (state.lastAnswerCorrect != null) {
                      return;
                    }
                    _currentInk = ink;
                    if (_isCorrect != null) {
                      setState(() => _isCorrect = null);
                    }
                  },
                  onClear: () {
                    if (state.lastAnswerCorrect != null) {
                      return;
                    }
                    _currentInk = null;
                    setState(() {
                      _isCorrect = null;
                    });
                  },
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // Action Button
            if (state.lastAnswerCorrect == null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: ScaleButton(
                  onTap: _isChecking
                      ? null
                      : () => _checkHandwriting(context, state),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 20.h),
                    decoration: BoxDecoration(
                      color: _isChecking ? Colors.grey : widget.primaryColor,
                      borderRadius: BorderRadius.circular(32.r),
                      boxShadow: [
                        if (!_isChecking)
                          BoxShadow(
                            color: widget.primaryColor.withValues(alpha: 0.5),
                            offset: Offset(0, 8.h),
                            blurRadius: 12,
                          ),
                      ],
                    ),
                    child: Center(
                      child: _isChecking
                          ? SizedBox(
                              height: 24.h,
                              width: 24.h,
                              child: const VowlButtonSpinner(
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              context.tr(
                                'common.check',
                                fallback: 'Check My Answer!',
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 26.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),

            SizedBox(height: 32.h), // Padding at bottom for safe area
          ],
        );
      },
    );
  }
}
