import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';

import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';

class PedagogicalRuleBox extends StatefulWidget {
  final IconData icon;
  final String capsKey;
  final String capsFallback;
  final String titleKey;
  final String titleFallback;
  final String rule;
  final Color shadowColor;
  final bool isDark;
  final bool isKids;

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
    this.isKids = false,
  });

  @override
  State<PedagogicalRuleBox> createState() => _PedagogicalRuleBoxState();
}

class _PedagogicalRuleBoxState extends State<PedagogicalRuleBox> {
  final ValueNotifier<String?> _translatedText = ValueNotifier(null);
  String? _translatedLocale;

  @override
  void didUpdateWidget(covariant PedagogicalRuleBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rule != widget.rule) {
      _translatedText.value = null;
      _translatedLocale = null;
    }
  }

  @override
  void dispose() {
    _translatedText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: _translatedText,
      builder: (context, translatedTextValue, _) {
        final displayText = translatedTextValue ?? widget.rule;

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
                      context.tr(widget.capsKey, fallback: widget.capsFallback),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w900,
                        color: widget.shadowColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TtsSpeakerButtonWidget(
                        text: displayText,
                        color: widget.shadowColor,
                        isKids: widget.isKids,
                        locale: translatedTextValue != null
                            ? _translatedLocale
                            : null,
                      ),
                      if (translatedTextValue == null) ...[
                        SizedBox(width: 8.w),
                        TranslateButtonWidget(
                          originalText: widget.rule,
                          isKidsZone: widget.isKids,
                          onTranslationComplete: (translated) {
                            TtsSpeakerButtonWidget.stopAll();
                            if (mounted) {
                              _translatedText.value = translated;
                            }
                          },
                          onTranslationWithLanguage: (translated, langCode) {
                            TtsSpeakerButtonWidget.stopAll();
                            if (mounted) {
                              _translatedLocale = langCode;
                              _translatedText.value = translated;
                            }
                          },
                        ),
                      ] else ...[
                        SizedBox(width: 8.w),
                        ScaleButton(
                          onTap: () {
                            TtsSpeakerButtonWidget.stopAll();
                            if (mounted) {
                              setState(() {
                                _translatedLocale = null;
                                _translatedText.value = null;
                              });
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: widget.shadowColor.withValues(
                                alpha: widget.isDark ? 0.2 : 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: widget.shadowColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.undo_rounded,
                                  size: 12.r,
                                  color: widget.shadowColor,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'EN',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: widget.shadowColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
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
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: widget.isDark
                            ? Colors.white.withValues(alpha: 0.8)
                            : AppColors.slate600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
