import 'dart:io';

void main() {
  final file = File('lib/features/accent/vowel_distinction/presentation/pages/vowel_distinction_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  content = content.replaceAll('_isFirstStagePassed.value.value', '_isFirstStagePassed.value');
  
  content = content.replaceAll('''                                                                  _isAnswered ||
                                                                  _isFirstStagePassed.value,''', '''                                                                  _isAnswered.value ||
                                                                  _isFirstStagePassed.value,''');
  
  content = content.replaceAll('''                                                              selectedIndex:
                                                                  _selectedIndex,''', '''                                                              selectedIndex:
                                                                  _selectedIndex.value,''');
                                                                  
  content = content.replaceAll('''                                                              sliderValue:
                                                                  _sliderValue,''', '''                                                              sliderValue:
                                                                  _sliderValue.value,''');
                                                                  
  content = content.replaceAll('''                                                        isAnswered:
                                                            _isAnswered ||
                                                            _isFirstStagePassed.value,''', '''                                                        isAnswered:
                                                            _isAnswered.value ||
                                                            _isFirstStagePassed.value,''');
                                                            
  content = content.replaceAll('''                                                        selectedIndex: _selectedIndex,''', '''                                                        selectedIndex: _selectedIndex.value,''');
  
  content = content.replaceAll('''                                                        sliderValue: _sliderValue,''', '''                                                        sliderValue: _sliderValue.value,''');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
