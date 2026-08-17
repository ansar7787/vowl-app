import 'dart:io';

void main() {
  final filePath = r'c:\Users\asus\Documents\App Projects\vowl\lib\features\daily_words\presentation\pages\daily_words_screen.dart';
  final widgetsFilePath = r'c:\Users\asus\Documents\App Projects\vowl\lib\features\daily_words\presentation\widgets\daily_words_widgets.dart';

  final content = File(filePath).readAsStringSync();
  final index = content.indexOf('class _WordCardFront extends');
  
  if (index == -1) {
    print('Could not find _WordCardFront');
    return;
  }

  var mainContent = content.substring(0, index);
  var widgetsContent = content.substring(index);

  widgetsContent = widgetsContent.replaceAll('class _WordCardFront', 'class WordCardFront');
  widgetsContent = widgetsContent.replaceAll('class _WordCardBack', 'class WordCardBack');
  widgetsContent = widgetsContent.replaceAll('class _PulsingIcon', 'class PulsingIcon');
  widgetsContent = widgetsContent.replaceAll('class _IconButton', 'class DailyWordsIconButton');
  widgetsContent = widgetsContent.replaceAll('_IconButton(', 'DailyWordsIconButton(');
  widgetsContent = widgetsContent.replaceAll('class _SectionLabel', 'class SectionLabel');
  widgetsContent = widgetsContent.replaceAll('class _ActionButton', 'class ActionButton');
  widgetsContent = widgetsContent.replaceAll('class _ErrorView', 'class DailyWordsErrorView');
  widgetsContent = widgetsContent.replaceAll('class _SessionCompleteView', 'class SessionCompleteView');
  
  widgetsContent = widgetsContent.replaceAll('_WordCardFront(', 'WordCardFront(');
  widgetsContent = widgetsContent.replaceAll('_WordCardBack(', 'WordCardBack(');
  widgetsContent = widgetsContent.replaceAll('_PulsingIcon(', 'PulsingIcon(');
  widgetsContent = widgetsContent.replaceAll('_SectionLabel(', 'SectionLabel(');
  widgetsContent = widgetsContent.replaceAll('_ActionButton(', 'ActionButton(');
  widgetsContent = widgetsContent.replaceAll('_ErrorView(', 'DailyWordsErrorView(');
  widgetsContent = widgetsContent.replaceAll('_SessionCompleteView(', 'SessionCompleteView(');

  mainContent = mainContent.replaceAll('_WordCardFront(', 'WordCardFront(');
  mainContent = mainContent.replaceAll('_WordCardBack(', 'WordCardBack(');
  mainContent = mainContent.replaceAll('_ErrorView(', 'DailyWordsErrorView(');
  mainContent = mainContent.replaceAll('_SessionCompleteView(', 'SessionCompleteView(');

  final importStatement = "import 'package:vowl/features/daily_words/presentation/widgets/daily_words_widgets.dart';\n";
  mainContent = mainContent.replaceAll(
    "import 'package:vowl/features/daily_words/presentation/bloc/daily_words_bloc.dart';",
    "import 'package:vowl/features/daily_words/presentation/bloc/daily_words_bloc.dart';\n$importStatement"
  );

  final widgetsFile = '''
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/daily_words/domain/entities/daily_word.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

''' + widgetsContent;

  File(widgetsFilePath).writeAsStringSync(widgetsFile);
  File(filePath).writeAsStringSync(mainContent);

  print('Refactored successfully!');
}
