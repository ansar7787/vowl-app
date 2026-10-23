import 'package:flutter/material.dart';

/// Text widget that scales dynamically to fit parent constraints without ellipsis truncation.
class KidsFittedText extends StatelessWidget {
  /// The text content to display.
  final String text;

  /// Optional text style.
  final TextStyle? style;

  /// Horizontal text alignment.
  final TextAlign? textAlign;

  /// Maximum number of lines permitted before scaling occurs.
  final int? maxLines;

  /// Visual overflow handling.
  final TextOverflow? overflow;

  /// Alignment geometry within the fitted box.
  final AlignmentGeometry? alignment;

  /// Creates a [KidsFittedText] widget.
  const KidsFittedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If parent has a bounded width (e.g., inside an Expanded or Container), use it.
        // If unbounded (e.g., Row), fallback to a safe max width to ensure wrapping triggers.
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 300.0;

        final effectiveAlignment = alignment ??
            (textAlign == TextAlign.start || textAlign == TextAlign.left
                ? AlignmentDirectional.centerStart
                : Alignment.center);

        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: effectiveAlignment,
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
