import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Instruction banner dynamically adapting directions depending on whether the error has been erased.
class FixTheSentenceInstruction extends StatelessWidget {
  /// Whether the flawed section has already been wiped clean.
  final bool isWiped;

  /// The primary theme accent color for badges and text.
  final Color primaryColor;

  /// Fallback instruction text for sentence correction.
  final String instruction;

  /// Optional classification of the grammatical error.
  final String? errorType;

  /// Creates a [FixTheSentenceInstruction] widget.
  const FixTheSentenceInstruction({
    super.key,
    required this.isWiped,
    required this.primaryColor,
    required this.instruction,
    this.errorType,
  });

  String _cleanInstruction(BuildContext context) {
    if (isWiped) {
      return context.tr(
        'games.fixTheSentence_wiped_instruction',
        fallback: 'Choose the correct word to complete the sentence',
      );
    }

    final raw = context.tr('games.fixTheSentence_instruction', fallback: instruction);
    final lower = raw.trim().toLowerCase();
    if (lower.contains('scrub') ||
        lower.contains('restore the sentence') ||
        lower.isEmpty) {
      return 'Tap the mistake in the sentence to fix it';
    }
    return raw;
  }

  String? _formatCategory(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final cleaned = raw
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+Error$', caseSensitive: false), '')
        .trim();
    if (cleaned.isEmpty) return null;
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final displayText = _cleanInstruction(context);
    final category = _formatCategory(errorType);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            displayText,
            textAlign: TextAlign.center,
            softWrap: true,
            maxLines: null,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              height: 1.4,
              letterSpacing: 0.1,
              color: primaryColor,
            ),
          ),
          if (category != null) ...[
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                category,
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
