import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/translation/presentation/widgets/translation_bottom_sheet.dart';

class TranslatableText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLines;

  const TranslatableText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.start,
    this.maxLines,
  });

  void _translateWord(BuildContext context, String word) {
    di.sl<HapticService>().light();
    TranslationBottomSheet.show(context: context, text: word);
  }

  @override
  Widget build(BuildContext context) {
    // Split the text into words and whitespace/punctuation
    // This allows us to make each word clickable while preserving spaces
    final RegExp wordPattern = RegExp(r'(\s+|[^\w\s]+|\w+)');
    final matches = wordPattern.allMatches(text);

    return AutoSizeText.rich(
      TextSpan(
        style: style ?? DefaultTextStyle.of(context).style,
        children: matches.map((match) {
          final String segment = match.group(0)!;
          final bool isWord = RegExp(r'^\w+$').hasMatch(segment);

          if (isWord) {
            return TextSpan(
              text: segment,
              recognizer: LongPressGestureRecognizer()
                ..onLongPress = () => _translateWord(context, segment),
            );
          } else {
            return TextSpan(text: segment);
          }
        }).toList(),
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
    );
  }
}
