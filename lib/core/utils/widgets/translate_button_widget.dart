import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/utils/translation_service.dart';
import 'package:vowl/core/utils/translation_monetization_controller.dart';
import 'package:vowl/core/utils/widgets/language_selection_bottom_sheet.dart';

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
  bool _isTranslating = false;

  Future<void> _handleTranslatePress() async {
    setState(() => _isTranslating = true);

    try {
      // 1. Check if they selected a language yet
      final isConfigured = await TranslationService().isLanguageConfigured();
      if (!isConfigured) {
        if (!mounted) return;
        await LanguageSelectionBottomSheet.show(context);
        
        // If they still didn't configure it (dismissed the sheet), abort.
        final recheck = await TranslationService().isLanguageConfigured();
        if (!recheck) {
          setState(() => _isTranslating = false);
          return;
        }
      }

      // 2. Pass to monetization controller (Free users watch an ad, Premium instantly translates)
      if (!mounted) return;
      await TranslationMonetizationController.attemptTranslation(
        context,
        isKidsZone: widget.isKidsZone,
        onSuccess: () async {
          // 3. Perform the actual ML Kit translation
          final translated = await TranslationService().translate(widget.originalText);
          widget.onTranslationComplete(translated);
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Translation failed. Please check internet connection.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTranslating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isTranslating) {
      return SizedBox(
        width: 24.r,
        height: 24.r,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return IconButton(
      onPressed: _handleTranslatePress,
      icon: Icon(
        LucideIcons.languages,
        size: 24.r,
        color: Colors.grey,
      ),
      tooltip: 'Translate',
      constraints: const BoxConstraints(),
      padding: EdgeInsets.zero,
    );
  }
}
