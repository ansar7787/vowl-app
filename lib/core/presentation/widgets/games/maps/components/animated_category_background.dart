import 'package:flutter/material.dart';

/// Shared shell for the per-category animated map backgrounds
/// (AccentMapBackground, GrammarMapBackground, etc).
///
/// REFACTOR NOTE: these 9 widgets used to each independently repeat the
/// exact same RepaintBoundary + Stack + gradient-Container scaffolding,
/// differing only in their gradient colors and their decorative layer
/// (floating icons, circuit lines, pulses, light beams...). That was a
/// textbook duplicate-widget violation — ~9x copies of identical
/// structural code. This widget is that shared structure; each category
/// file now only supplies its two genuinely-distinct inputs (gradient,
/// decoration) and stays a thin, readable, individually-named widget.
///
/// Employs [RepaintBoundary] layer isolation to protect active map level
/// nodes, indicators, and shop headers from redundant visual repaint
/// passes — exactly as each original file's doc comment promised.
class CategoryMapBackground extends StatelessWidget {
  /// Top-to-bottom gradient colors for the base layer.
  final List<Color> gradientColors;

  /// Builds the category-specific decorative layer (floating icons,
  /// pulses, beams, etc.) that sits above the gradient.
  final WidgetBuilder decorationBuilder;

  const CategoryMapBackground({
    super.key,
    required this.gradientColors,
    required this.decorationBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          decorationBuilder(context),
        ],
      ),
    );
  }
}
