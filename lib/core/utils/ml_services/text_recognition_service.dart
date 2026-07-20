import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

/// Service for on-device Text Recognition (OCR) using Google ML Kit.
class TextRecognitionService {
  late final TextRecognizer _textRecognizer;

  TextRecognitionService() {
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  }

  /// Processes an image from the given file path and returns the recognized text.
  Future<RecognizedText?> recognizeFromFile(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      di.sl<AppLogger>().error('TextRecognitionService: File not found at $imagePath');
      return null;
    }

    try {
      final inputImage = InputImage.fromFile(file);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText;
    } catch (e) {
      di.sl<AppLogger>().error('TextRecognitionService: Failed to process image', error: e);
      return null;
    }
  }

  /// Releases resources used by the ML model.
  void dispose() {
    _textRecognizer.close();
  }
}
