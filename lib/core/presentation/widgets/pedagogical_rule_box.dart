import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';

class PedagogicalRuleBox extends StatefulWidget {
  final IconData icon;
  final String capsKey;
  final String capsFallback;
  final String titleKey;
  final String titleFallback;
  final String rule;
  final Color shadowColor;
  final bool isDark;

  const PedagogicalRuleBox({
    super.key,
    required this.icon,
    required this.capsKey,
    required this.capsFallback,
    required this.titleKey,
    required this.titleFallback,
    required this.rule,
    required this.shadowColor,
    required this.isDark,
  });

  @override
  State<PedagogicalRuleBox> createState() => _PedagogicalRuleBoxState();
}

class _PedagogicalRuleBoxState extends State<PedagogicalRuleBox> {
  String? _translatedText;

  @override
  Widget build(BuildContext context) {
    final displayText = _translatedText ?? widget.rule;

    return Container(
      width: 342.w,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: widget.shadowColor.withValues(
          alpha: widget.isDark ? 0.08 : 0.05,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: widget.shadowColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  widget.icon,
                  color: widget.shadowColor,
                  size: 16.r,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  context.tr(
                    widget.capsKey,
                    fallback: widget.capsFallback,
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
                    color: widget.shadowColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              if (_translatedText == null)
                TranslateButtonWidget(
                  originalText: widget.rule,
                  onTranslationComplete: (translated) {
                    if (mounted) {
                      setState(() => _translatedText = translated);
                    }
                  },
                ),
            ],
          ),
          SizedBox(height: 6.h),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 120.h),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Semantics(
                label:
                    '${context.tr(widget.titleKey, fallback: widget.titleFallback)}: $displayText',
                child: Text(
                  displayText,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark
                        ? Colors.white.withValues(alpha: 0.8)
                        : const Color(0xFF475569),
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
