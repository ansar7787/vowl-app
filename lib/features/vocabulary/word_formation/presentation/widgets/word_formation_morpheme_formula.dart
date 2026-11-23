import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'word_formation_colors.dart';

/// Linguistic formula widget that visually decomposes a formed word
/// into its morphemic equation: [Prefix] + [Root] + [Suffix].
class WordFormationMorphemeFormula extends StatelessWidget {
  final String rootWord;
  final String formedWord;
  final String? targetRole;

  const WordFormationMorphemeFormula({
    super.key,
    required this.rootWord,
    required this.formedWord,
    this.targetRole,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final breakdown = _deconstruct(rootWord, formedWord);
    final roleColor = WordFormationColors.forRole(targetRole);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: roleColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: roleColor.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_fix_high_rounded,
                color: roleColor,
                size: 13.r,
              ),
              SizedBox(width: 4.w),
              Text(
                'WORD BREAKDOWN',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: roleColor,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (breakdown.prefix != null) ...[
                  _buildMorphemeBadge(
                    label: breakdown.prefix!,
                    type: 'PREFIX',
                    color: WordFormationColors.westOpposite,
                    isDark: isDark,
                  ),
                  _buildOperator('+'),
                ],
                _buildMorphemeBadge(
                  label: rootWord.toUpperCase(),
                  type: 'ROOT',
                  color: const Color(0xFF6366F1), // Indigo
                  isDark: isDark,
                ),
                if (breakdown.suffix != null) ...[
                  _buildOperator('+'),
                  _buildMorphemeBadge(
                    label: breakdown.suffix!,
                    type: 'SUFFIX',
                    color: roleColor,
                    isDark: isDark,
                  ),
                ],
                _buildOperator('='),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gameCorrect.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppColors.gameCorrect.withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    formedWord.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gameCorrect,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperator(String symbol) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      child: Text(
        symbol,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildMorphemeBadge({
    required String label,
    required String type,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            type,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 9.5.sp,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
        ],
      ),
    );
  }

  _MorphemeBreakdown _deconstruct(String root, String formed) {
    final cleanRoot = root.trim().toUpperCase();
    final cleanFormed = formed.trim().toUpperCase();

    String? prefix;
    String remainder = cleanFormed;

    // Detect known English prefixes
    const prefixes = [
      'UN',
      'IN',
      'IM',
      'IL',
      'IR',
      'DIS',
      'MIS',
      'RE',
      'NON',
      'OVER',
      'UNDER',
      'OUT',
    ];

    for (final p in prefixes) {
      if (cleanFormed.startsWith(p) && !cleanRoot.startsWith(p)) {
        prefix = '$p-';
        remainder = cleanFormed.substring(p.length);
        break;
      }
    }

    String? suffix;
    const suffixes = [
      'ATION',
      'ITION',
      'SION',
      'TION',
      'MENT',
      'NESS',
      'ITY',
      'ANCE',
      'ENCE',
      'SHIP',
      'HOOD',
      'ISM',
      'IVELY',
      'FULLY',
      'LESSLY',
      'ABLY',
      'IBLY',
      'ALLY',
      'LY',
      'IVE',
      'OUS',
      'FUL',
      'LESS',
      'ABLE',
      'IBLE',
      'IC',
      'AL',
      'ARY',
      'ORY',
      'ATE',
    ];

    for (final s in suffixes) {
      if (remainder.endsWith(s) && !cleanRoot.endsWith(s)) {
        suffix = '-$s';
        break;
      }
    }

    return _MorphemeBreakdown(prefix: prefix, suffix: suffix);
  }
}

class _MorphemeBreakdown {
  final String? prefix;
  final String? suffix;

  const _MorphemeBreakdown({this.prefix, this.suffix});
}
