import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/utils/image_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImageUtils Tests', () {
    test('returns original sourceFile if it does not exist', () async {
      final nonExistent = File('path/to/nothing/avatar.png');
      final result = await ImageUtils.cropToSquare(nonExistent);
      expect(result.path, nonExistent.path);
    });

    test('returns original sourceFile if it is empty', () async {
      final tempDir = await Directory.systemTemp.createTemp('vowl_test_img');
      final emptyFile = File('${tempDir.path}/empty.png');
      await emptyFile.writeAsBytes([]);

      final result = await ImageUtils.cropToSquare(emptyFile);
      expect(result.path, emptyFile.path);

      await tempDir.delete(recursive: true);
    });
  });
}

