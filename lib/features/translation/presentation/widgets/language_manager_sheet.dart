import 'package:flutter/material.dart';
import 'package:vowl/core/utils/widgets/language_selection_bottom_sheet.dart';

/// Unified wrapper ensuring offline pack management uses the single production-grade
/// LanguageSelectionBottomSheet across all features.
class LanguageManagerSheet extends StatelessWidget {
  final bool isDark;

  const LanguageManagerSheet({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return const LanguageSelectionBottomSheet(isSource: false);
  }
}
