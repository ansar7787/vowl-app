import 'package:flutter/material.dart';
import 'package:vowl/core/utils/widgets/language_selection_bottom_sheet.dart';

/// Unified bottom sheet wrapper ensuring offline pack management uses
/// [LanguageSelectionBottomSheet] across all translation features.
class LanguageManagerSheet extends StatelessWidget {
  /// Whether the host screen is rendered in dark mode.
  final bool isDark;

  const LanguageManagerSheet({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return const LanguageSelectionBottomSheet(isSource: false);
  }
}
