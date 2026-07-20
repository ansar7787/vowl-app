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
import 'package:vowl/core/utils/sound_service.dart';

class KidsHandwritingScreen extends StatefulWidget {
  const KidsHandwritingScreen({super.key});

  @override
  State<KidsHandwritingScreen> createState() => _KidsHandwritingScreenState();
}

class _KidsHandwritingScreenState extends State<KidsHandwritingScreen> {
  final List<String> _wordsToPractice = ['A', 'B', 'C', 'CAT', 'DOG', 'BIRD'];
  int _currentWordIndex = 0;
  int _attemptsCount = 0;
  
  Ink? _currentInk;
  bool _isDownloading = false;
  bool _isChecking = false;
  bool? _isCorrect;

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to download handwriting model.')),
        );
      }
    }
  }

  Future<void> _checkHandwriting() async {
    if (_currentInk == null || _currentInk!.strokes.isEmpty) return;

    final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;

    if (!isPremium && _attemptsCount >= 5) {
      MlMonetizationController.attemptFeature(
        context,
        featureIcon: Icons.edit_rounded,
        featureTitle: context.tr('kids_zone.handwriting_title', fallback: 'Write & Learn'),
        featureSubtitle: context.tr('kids_zone.handwriting_desc', fallback: 'Practice your handwriting!'),
        adButtonLabel: context.tr('kids_zone.handwriting_ad', fallback: 'Watch Ad to Continue'),
        onSuccess: () {
          _attemptsCount = 0;
          _performCheck();
        },
      );
    } else {
      _performCheck();
    }
  }

  Future<void> _performCheck() async {
    setState(() {
      _isChecking = true;
      _isCorrect = null;
    });

    _attemptsCount++;

    final service = di.sl<DigitalInkService>();
    final results = await service.recognize(_currentInk!);
    
    if (!mounted) return;

    final targetWord = _wordsToPractice[_currentWordIndex].toUpperCase();
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

    if (correct) {
      di.sl<SoundService>().playCorrect();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _nextWord();
      });
    } else {
      di.sl<SoundService>().playWrong();
    }
  }

  void _nextWord() {
    setState(() {
      _currentWordIndex = (_currentWordIndex + 1) % _wordsToPractice.length;
      _currentInk = null;
      _isCorrect = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFFF43F5E); // Rose

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        title: Text(
          context.tr('kids_zone.handwriting_title', fallback: 'Write & Learn'),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 24.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
      body: _isDownloading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFFF43F5E)),
                  SizedBox(height: 16.h),
                  Text(
                    context.tr('translation.downloading', fallback: 'Downloading language model... Please wait.'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                children: [
                  // Target Word Display
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(32.r),
                      border: Border.all(color: primaryColor, width: 4.w),
                    ),
                    child: Center(
                      child: Text(
                        _wordsToPractice[_currentWordIndex],
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 64.sp,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
                  
                  SizedBox(height: 24.h),
                  
                  // Handwriting Canvas
                  Expanded(
                    child: Stack(
                      children: [
                        HandwritingCanvas(
                          onInkUpdated: (ink) {
                            _currentInk = ink;
                          },
                          onClear: () {
                            _currentInk = null;
                            setState(() {
                              _isCorrect = null;
                            });
                          },
                        ),
                        if (_isCorrect != null)
                          Positioned.fill(
                            child: Center(
                              child: Icon(
                                _isCorrect! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                color: _isCorrect! ? Colors.green : Colors.red,
                                size: 120.r,
                              ).animate().scale(curve: Curves.easeOutBack).fadeOut(delay: 1500.ms),
                            ),
                          ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),
                  
                  // Action Button
                  ScaleButton(
                    onTap: _isChecking ? null : _checkHandwriting,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      decoration: BoxDecoration(
                        color: _isChecking ? Colors.grey : primaryColor,
                        borderRadius: BorderRadius.circular(24.r),
                        boxShadow: [
                          if (!_isChecking)
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.5),
                              offset: Offset(0, 6.h),
                            ),
                        ],
                      ),
                      child: Center(
                        child: _isChecking
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                context.tr('common.check', fallback: 'Check'),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
