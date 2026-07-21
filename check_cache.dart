import 'dart:io';

void main() {
  var path = Platform.environment['LOCALAPPDATA']! + '\\Pub\\Cache\\hosted\\pub.dev';
  var dir = Directory(path);
  if (dir.existsSync()) {
    for (var d in dir.listSync()) {
      if (d is Directory && d.path.contains('speech_to_text')) {
        print(d.path);
      }
    }
  }
}
