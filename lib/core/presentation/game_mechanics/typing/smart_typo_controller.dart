import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/utils/smart_typo_evaluator.dart';

class SmartTypoController extends TextEditingController {
  final String expectedText;
  bool _showDiff = false;
  Color correctColor = Colors.green;
  Color incorrectColor = AppColors.gameIncorrect;

  SmartTypoController({required this.expectedText});

  bool get showDiff => _showDiff;

  set showDiff(bool val) {
    if (_showDiff != val) {
      _showDiff = val;
      notifyListeners();
    }
  }

  @override
  set value(TextEditingValue newValue) {
    if (_showDiff && newValue.text != value.text) {
      _showDiff = false;
    }
    super.value = newValue;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (!_showDiff || text.isEmpty) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }
    return SmartTypoEvaluator.buildDiffSpan(
      text,
      expectedText,
      baseStyle: style ?? const TextStyle(),
      correctColor: correctColor,
      incorrectColor: incorrectColor,
    );
  }
}
