import 'package:vowl/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/kids_zone/domain/entities/kids_quest.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';

class KidsExplanationCard extends StatefulWidget {
  final KidsQuest quest;
  final Color primaryColor;
  final VoidCallback onTryAgain;

  const KidsExplanationCard({
    super.key,
    required this.quest,
    required this.primaryColor,
    required this.onTryAgain,
  });

  @override
  State<KidsExplanationCard> createState() => _KidsExplanationCardState();
}

class _KidsExplanationCardState extends State<KidsExplanationCard> {
  final ValueNotifier<String?> _translatedText = ValueNotifier(null);

  @override
  void dispose() {
    _translatedText.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _speakExplanation();
  }

  Future<void> _speakExplanation() async {
    final explanation = widget.quest.explanation;
    if (explanation != null && explanation.isNotEmpty) {
      try {
        final tts = di.sl<KidsTTSService>();
        if (await tts.isNarrationEnabled()) {
          await tts.speak(explanation);
        }
      } catch (e) {
        di.sl<AppLogger>().warning("KIDS_TTS_ERROR: $e", tag: 'KidsZone');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String explanation =
        widget.quest.explanation ??
        "Oops! Let's look closely and try that again.";

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32.r),
          topRight: Radius.circular(32.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withValues(alpha: 0.15),
            offset: const Offset(0, -10),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ValueListenableBuilder<String?>(
            valueListenable: _translatedText,
            builder: (context, translatedText, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.sentiment_dissatisfied_rounded,
                          color: Colors.redAccent,
                          size: 28.r,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          context.tr('games.try_again', fallback: 'Try Again'),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                      if (translatedText == null)
                        TranslateButtonWidget(
                          originalText: explanation,
                          onTranslationComplete: (translated) {
                            _translatedText.value = translated;
                          },
                        ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    translatedText ?? explanation,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 24.h),
          ScaleButton(
            onTap: widget.onTryAgain,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.shade900,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  context
                      .tr('games.try_again', fallback: 'Try Again')
                      .toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8.h),
        ],
      ),
    ).animate().slideY(
      begin: 1.0,
      end: 0.0,
      duration: 400.ms,
      curve: Curves.easeOutBack,
    );
  }
}
