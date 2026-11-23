import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'word_formation_colors.dart';
import 'word_formation_morpheme_formula.dart';

/// Renders the inner content of the animated morphological slot.
class WordFormationSlotContent extends StatelessWidget {
  final bool isAnswered;
  final String? formedWord;
  final String? targetRole;
  final bool? isCorrect;
  final String? rootWord;
  final Color roleColor;

  const WordFormationSlotContent({
    super.key,
    required this.isAnswered,
    this.formedWord,
    this.targetRole,
    this.isCorrect,
    this.rootWord,
    required this.roleColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!isAnswered || formedWord == null) {
      return Text(
        targetRole != null ? '[$targetRole]' : '_______',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
          color: roleColor,
          letterSpacing: 0.4,
        ),
      );
    }

    if (isCorrect != true || rootWord == null) {
      return Text(
        formedWord!.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.gameIncorrect,
          letterSpacing: 0.4,
        ),
      );
    }

    final cleanFormed = formedWord!.trim().toUpperCase();
    final breakdown = MorphemeBreakdown.deconstruct(rootWord!, cleanFormed);

    if (breakdown.prefix == null && breakdown.suffix == null) {
      return Text(
        cleanFormed,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.gameCorrect,
          letterSpacing: 0.4,
        ),
      );
    }

    final pfx = breakdown.prefix?.replaceAll('-', '');
    final sfx = breakdown.suffix?.replaceAll('-', '');
    final middle = breakdown.stem ?? cleanFormed;

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
        children: [
          if (pfx != null)
            TextSpan(
              text: pfx,
              style: TextStyle(color: WordFormationColors.westOpposite),
            ),
          TextSpan(
            text: middle,
            style: const TextStyle(color: Color(0xFF6366F1)),
          ),
          if (sfx != null)
            TextSpan(
              text: sfx,
              style: TextStyle(color: roleColor),
            ),
        ],
      ),
    );
  }
}
