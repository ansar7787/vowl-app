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
import 'package:vowl/core/utils/custom_snack_bar.dart';

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
        CustomSnackBar.show(
          context: context,
          message: 'Failed to download handwriting model. Please check your connection.',
          type: CustomSnackBarType.error,
        );
      }
    }
  }

  Future<void> _checkHandwriting() async {
    if (_currentInk == null || _currentInk!.strokes.isEmpty) return;

    // KIDS ZONE EXEMPTION:
    // Kids games should NEVER show third-party ads (like Google AdMob or rewarded video gates)
    // to comply with COPPA (Children's Online Privacy Protection Act) and Play Store Family policies.
    // Handwriting practice is 100% free and unlimited for all users.
    
    _performCheck();
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
    final frameColor = const Color(0xFF38BDF8); // Fun blue toy frame

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFFFDF4FF), const Color(0xFFE0E7FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _isDownloading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFFF43F5E)),
                      SizedBox(height: 16.h),
                      Text(
                        context.tr('translation.downloading', fallback: 'Getting your classroom ready...'),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  child: Column(
                    children: [
                      // Custom Cute Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ScaleButton(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF334155) : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: Offset(0, 4.h),
                                  )
                                ],
                              ),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: primaryColor,
                                size: 28.sp,
                              ),
                            ),
                          ),
                          Text(
                            context.tr('kids_zone.handwriting_title', fallback: 'Write & Learn!'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 28.sp,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          SizedBox(width: 52.w), // Balance for centering
                        ],
                      ),
                      
                      SizedBox(height: 24.h),
                      
                      // Flashcard Target Word Display
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 20.h),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(32.r),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 4.w),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.2),
                              blurRadius: 16,
                              offset: Offset(0, 8.h),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Draw this word:',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            Text(
                              _wordsToPractice[_currentWordIndex],
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 64.sp,
                                fontWeight: FontWeight.w900,
                                color: primaryColor,
                                letterSpacing: 6,
                              ),
                            ),
                          ],
                        ),
                      ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
                      
                      SizedBox(height: 24.h),
                      
                      // Toy Tablet Canvas Frame
                      Expanded(
                        child: Container(
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
                                      child: Container(
                                        padding: EdgeInsets.all(24.w),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.1),
                                              blurRadius: 12,
                                              offset: Offset(0, 6.h),
                                            )
                                          ]
                                        ),
                                        child: Icon(
                                          _isCorrect! ? Icons.star_rounded : Icons.close_rounded,
                                          color: _isCorrect! ? const Color(0xFFFBBF24) : Colors.red,
                                          size: 80.r,
                                        ),
                                      ).animate().scale(curve: Curves.elasticOut, duration: 800.ms).fadeOut(delay: 1500.ms),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 32.h),
                      
                      // Action Button (Already playful, just refined)
                      ScaleButton(
                        onTap: _isChecking ? null : _checkHandwriting,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 20.h),
                          decoration: BoxDecoration(
                            color: _isChecking ? Colors.grey : primaryColor,
                            borderRadius: BorderRadius.circular(32.r),
                            boxShadow: [
                              if (!_isChecking)
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.5),
                                  offset: Offset(0, 8.h),
                                  blurRadius: 12,
                                ),
                            ],
                          ),
                          child: Center(
                            child: _isChecking
                                ? const CircularProgressIndicator(color: Colors.white)
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
                      SizedBox(height: 16.h),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
