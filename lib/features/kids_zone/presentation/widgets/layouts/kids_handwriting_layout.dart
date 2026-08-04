import 'dart:async';
import 'package:flutter/material.dart' hide Ink;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/ml_monetization_controller.dart';
import 'package:vowl/core/utils/ml_services/digital_ink_service.dart';
import 'package:vowl/core/utils/widgets/handwriting_canvas.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/presentation/widgets/vowl_button_spinner.dart';

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
  bool _isDownloading = false;
  bool _isChecking = false;
  bool? _isCorrect;
  int _attemptsCount = 0;
  String? _lastQuestId;
  final GlobalKey<HandwritingCanvasState> _canvasKey = GlobalKey<HandwritingCanvasState>();

  @override
  void initState() {
    super.initState();
    _initModel();
  }

  Future<void> _initModel() async {
    setState(() => _isDownloading = true);
    final service = di.sl<DigitalInkService>();
    final success = await service.downloadModel();
    if (mounted) {
      setState(() => _isDownloading = false);
      if (!success) {
        CustomSnackBar.show(
          context: context,
          message: 'Failed to download handwriting model. Please check your connection.',
          type: CustomSnackBarType.error,
        );
      }
    }
  }

  Future<void> _checkHandwriting(BuildContext context, KidsLoaded state) async {
    if (_currentInk == null || _currentInk!.strokes.isEmpty) return;

    final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;

    if (!isPremium && _attemptsCount >= 5) {
      MlMonetizationController.attemptFeature(
        context,
        featureIcon: Icons.edit_rounded,
        featureTitle: context.tr('kids_zone.handwriting_title', fallback: 'Write & Learn'),
        featureSubtitle: context.tr('kids_zone.handwriting_desc', fallback: 'Practice your handwriting!'),
        adButtonLabel: context.tr('kids_zone.handwriting_ad', fallback: 'Watch Ad to Continue'),
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
        final frameColor = const Color(0xFF38BDF8); // Fun blue toy frame
        final targetWord = state.currentQuest.question ?? '';

        if (_isDownloading) {
          return _MockDownloadProgress(primaryColor: widget.primaryColor);
        }

        return Column(
          children: [
            SizedBox(height: 120.h), // Mascot space reserved by KidsGameBaseScreen

            // Flashcard Target Word Display
            Container(
              width: 300.w,
              padding: EdgeInsets.symmetric(vertical: 20.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(32.r),
                border: Border.all(color: widget.primaryColor.withValues(alpha: 0.3), width: 4.w),
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
                    context.tr('kids_zone.handwriting_instruction', fallback: 'Draw this word:'),
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
            
            // Toy Tablet Canvas Frame
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 24.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(32.r),
                  border: Border.all(
                    color: frameColor,
                    width: 12.w, // Thick playful border
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: frameColor.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: Offset(0, 8.h),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: Stack(
                    children: [
                      HandwritingCanvas(
                        key: _canvasKey,
                        onInkUpdated: (ink) {
                          if (state.lastAnswerCorrect != null) return; // Disallow writing if already checked
                          _currentInk = ink;
                          if (_isCorrect != null) {
                            setState(() => _isCorrect = null);
                          }
                        },
                        onClear: () {
                          if (state.lastAnswerCorrect != null) return; // Disallow clearing if checked
                          _currentInk = null;
                          setState(() {
                            _isCorrect = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // Action Button
            if (state.lastAnswerCorrect == null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: ScaleButton(
                  onTap: _isChecking ? null : () => _checkHandwriting(context, state),
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
                              child: const VowlButtonSpinner(color: Colors.white),
                            )
                          : Text(
                              context.tr('common.check', fallback: 'Check My Answer!'),
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

class _MockDownloadProgress extends StatefulWidget {
  final Color primaryColor;
  const _MockDownloadProgress({required this.primaryColor});

  @override
  State<_MockDownloadProgress> createState() => _MockDownloadProgressState();
}

class _MockDownloadProgressState extends State<_MockDownloadProgress> {
  double _progress = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Simulate download progress up to 95% while waiting for ML model
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_progress < 0.85) {
          _progress += 0.02; // Fast up to 85%
        } else if (_progress < 0.95) {
          _progress += 0.005; // Slow crawl to 95%
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 160.h),
        Icon(Icons.cloud_download_rounded, size: 80.r, color: widget.primaryColor)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: -5, end: 5, duration: 1.seconds),
        SizedBox(height: 24.h),
        Text(
          context.tr(
            'kids_zone.downloading_smart_pen',
            fallback: 'Downloading Smart Pen...',
          ),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: widget.primaryColor,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          context.tr(
            'kids_zone.download_once_note',
            fallback: 'This only happens once!',
          ),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14.sp,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 32.h),
        Container(
          width: 200.w,
          height: 20.h,
          decoration: BoxDecoration(
            color: widget.primaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 200.w * _progress,
                height: 20.h,
                decoration: BoxDecoration(
                  color: widget.primaryColor,
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          "${(_progress * 100).toInt()}%",
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: widget.primaryColor,
          ),
        ),
      ],
    );
  }
}
