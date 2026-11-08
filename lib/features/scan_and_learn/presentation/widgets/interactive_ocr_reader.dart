import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/scan_and_learn/domain/entities/scanned_word_token.dart';

/// Flowing, interactive reading canvas that converts raw OCR text into
/// tappable vocabulary tokens with visual feedback and challenge triggers.
class InteractiveOcrReader extends StatelessWidget {
  final RecognizedText recognizedText;
  final ScannedWordToken? selectedToken;
  final ValueChanged<ScannedWordToken> onSelectToken;
  final VoidCallback onStartChallenge;

  const InteractiveOcrReader({
    super.key,
    required this.recognizedText,
    required this.selectedToken,
    required this.onSelectToken,
    required this.onStartChallenge,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<ScannedWordToken> tokens = _extractTokens(recognizedText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Challenge Banner Action ──────────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          child: ScaleButton(
            onTap: () {
              if (di.sl.isRegistered<HapticService>()) {
                di.sl<HapticService>().selection();
              }
              onStartChallenge();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.indigo500, AppColors.teal500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.indigo500.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.gamepad2,
                      size: 20.r,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(
                            'scan.snap_quiz_title',
                            fallback: 'SNAP CHALLENGE • 3 QUESTIONS',
                          ),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          context.tr(
                            'scan.snap_quiz_prompt',
                            fallback:
                                'Test Your Real-World Vocabulary (+10 Coins)',
                          ),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.arrowRight, size: 18.r, color: Colors.white),
                ],
              ),
            ),
          ),
        ),

        // ── Flowing Interactive Reading Canvas ───────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.sparkles,
                                size: 14.r,
                                color: AppColors.teal500,
                              ),
                              SizedBox(width: 6.w),
                              Flexible(
                                child: Text(
                                  context.tr(
                                    'scan.interactive_text',
                                    fallback: 'INTERACTIVE TEXT CANVAS',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                    color: AppColors.teal500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          context.tr(
                            'scan.tap_to_inspect',
                            fallback: 'Tap word to inspect',
                          ),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 10.h,
                      children: tokens.map((token) {
                        final isSelected =
                            selectedToken?.cleanWord.toLowerCase() ==
                            token.cleanWord.toLowerCase();

                        return ScaleButton(
                          onTap: () {
                            if (di.sl.isRegistered<HapticService>()) {
                              di.sl<HapticService>().selection();
                            }
                            onSelectToken(token);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.indigo500
                                  : (token.isKeyword
                                        ? AppColors.teal500.withValues(
                                            alpha: isDark ? 0.2 : 0.12,
                                          )
                                        : (isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.08,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.05,
                                                ))),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.indigo400
                                    : (token.isKeyword
                                          ? AppColors.teal500.withValues(
                                              alpha: 0.5,
                                            )
                                          : Colors.transparent),
                                width: isSelected ? 2.w : 1.w,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.indigo500.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              token.text,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 15.sp,
                                fontWeight: token.isKeyword || isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : (token.isKeyword
                                          ? (isDark
                                                ? AppColors.teal400
                                                : AppColors.teal500)
                                          : (isDark
                                                ? Colors.white
                                                : Colors.black87)),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<ScannedWordToken> _extractTokens(RecognizedText text) {
    final List<ScannedWordToken> tokens = [];
    for (final block in text.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          final raw = element.text.trim();
          if (raw.isEmpty) continue;
          final clean = raw
              .replaceAll(RegExp(r'^[^\w]+|[^\w]+$'), '')
              .toLowerCase();
          if (clean.isEmpty) continue;

          tokens.add(
            ScannedWordToken(
              text: raw,
              cleanWord: clean,
              boundingBox: element.boundingBox,
              isKeyword: clean.length > 3,
            ),
          );
        }
      }
    }
    return tokens;
  }
}
