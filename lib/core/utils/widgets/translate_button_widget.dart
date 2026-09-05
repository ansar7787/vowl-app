import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/utils/translation_service.dart';
import 'package:vowl/core/utils/translation_monetization_controller.dart';
import 'package:vowl/core/utils/widgets/language_selection_bottom_sheet.dart';
import 'package:vowl/core/utils/widgets/translation_download_sheet.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A reusable button that triggers the translation flow.
///
/// Handles:
/// 1. Checking if native language is configured (shows selection sheet if not).
/// 2. Requesting translation (via monetization controller).
/// 3. Showing loading state while translating.
/// 4. Returning the translated string via callback.
class TranslateButtonWidget extends StatefulWidget {
  final String originalText;
  final bool isKidsZone;
  final Function(String translatedText) onTranslationComplete;

  const TranslateButtonWidget({
    super.key,
    required this.originalText,
    required this.onTranslationComplete,
    this.isKidsZone = false,
  });

  @override
  State<TranslateButtonWidget> createState() => _TranslateButtonWidgetState();
}

class _TranslateButtonWidgetState extends State<TranslateButtonWidget> {
  final ValueNotifier<bool> _isTranslating = ValueNotifier(false);

  Future<void> _handleTranslatePress() async {
    _isTranslating.value = true;

    try {
      // 1. Check if they selected a language yet
      final isConfigured = await TranslationService().isLanguageConfigured();
      if (!isConfigured) {
        if (!mounted) return;
        await LanguageSelectionBottomSheet.show(context);

        // If they still didn't configure it (dismissed the sheet), abort.
        final recheck = await TranslationService().isLanguageConfigured();
        if (!recheck) {
          _isTranslating.value = false;
          return;
        }
      }

      // 2. Check if we need to show the download UI
      final isDownloaded = await TranslationService().isTargetModelDownloaded();

      // 3. Pass to monetization controller (Free users watch an ad, Premium instantly translates)
      if (!mounted) return;
      await TranslationMonetizationController.attemptTranslation(
        context,
        isKidsZone: widget.isKidsZone,
        onSuccess: () async {
          if (!isDownloaded && mounted) {
            // Show the cool dopamine UI while the model is downloading
            await TranslationDownloadSheet.show(
              context,
              TranslationService().ensureModelDownloaded(),
            );
          }
          // 4. Perform the actual ML Kit translation
          final translated = await TranslationService().translate(
            widget.originalText,
          );
          widget.onTranslationComplete(translated);
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Translation failed. Please check internet connection.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        _isTranslating.value = false;
      }
    }
  }

  @override
  void dispose() {
    _isTranslating.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isTranslating,
      builder: (context, isTranslating, _) {
        if (isTranslating) {
          return Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              color: widget.isKidsZone
                  ? Colors.white24
                  : Theme.of(context).primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child:
                  Icon(
                        LucideIcons.sparkles,
                        size: 18.r,
                        color: widget.isKidsZone
                            ? Colors.white
                            : Theme.of(context).primaryColor,
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.2, 1.2),
                      ),
            ),
          );
        }

        return IconButton(
          onPressed: _handleTranslatePress,
          icon: Icon(LucideIcons.languages, size: 24.r, color: Colors.grey),
          tooltip: 'Translate',
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
        );
      },
    );
  }
}
