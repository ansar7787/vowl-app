import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/features/kids_zone/theme/kids_colors.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color colordc2626 = Color(0xFFDC2626);
}

class DescribeSituationWritingArea extends StatelessWidget {
  final TextEditingController textController;
  final FocusNode focusNode;
  final int minWords;
  final int wordCount;
  final List<String> usedKeywords;
  final Color color;
  final bool isDark;

  const DescribeSituationWritingArea({
    super.key,
    required this.textController,
    required this.focusNode,
    required this.minWords,
    required this.wordCount,
    required this.usedKeywords,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black87 : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black12,
          width: 1,
        ),
      ),
      padding: EdgeInsets.all(16.r),
      child: Column(
        children: [
          TextField(
            key: const Key('describe_situation_input_field'),
            controller: textController,
            focusNode: focusNode,
            maxLines: 4,
            onTap: () {
              if (focusNode.hasFocus) {
                SystemChannels.textInput.invokeMethod('TextInput.show');
              }
            },
            onTapOutside: (PointerDownEvent event) {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            style: TextStyle(
              fontFamily: 'Outfit',
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14.5.sp,
              height: 1.45,
            ),
            decoration: InputDecoration(
              hintText:
                  "Write your description here... (Tap any emoji below to view and add keywords)",
              hintStyle: TextStyle(
                fontFamily: 'Outfit',
                color: isDark ? Colors.white38 : AppColors.slate400,
                fontSize: 13.5.sp,
                height: 1.4,
              ),
              border: InputBorder.none,
            ),
          ),
          Divider(
            color: isDark ? Colors.white10 : Colors.black12,
            height: 20.h,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  "Keywords used: ${usedKeywords.length}",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Builder(
                builder: (context) {
                  final displayColor = wordCount >= minWords
                      ? (isDark ? tokens.gameCorrect : KidsColors.safeGreen)
                      : (isDark
                            ? tokens.gameIncorrect
                            : _LocalPalette.colordc2626);
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: displayColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      "$wordCount / $minWords words",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.5.sp,
                        color: displayColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
