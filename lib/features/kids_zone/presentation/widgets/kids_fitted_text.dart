import 'package:flutter/material.dart';

/// A robust, zero-ellipsis text widget specifically designed for the Kids Zone.
/// It uses a LayoutBuilder to capture the parent's constraints, forces text wrapping
/// up to [maxLines], and then uses a FittedBox to infinitely scale the entire text
/// block down without ever truncating or using ellipses.
class KidsFittedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const KidsFittedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If parent has a bounded width (e.g., inside an Expanded or Container), use it.
        // If unbounded (e.g., Row), fallback to a safe max width to ensure wrapping triggers.
        final maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0;
        
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Text(
              text,
              style: style,
              textAlign: textAlign,
              maxLines: maxLines,
              overflow: overflow ?? TextOverflow.visible,
            ),
          ),
        );
      },
    );
  }
}
