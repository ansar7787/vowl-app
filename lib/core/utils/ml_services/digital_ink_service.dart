import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class DigitalInkService {
  final DigitalInkRecognizer _recognizer;
  final String _language = 'en'; // English model

  DigitalInkService() : _recognizer = DigitalInkRecognizer(languageCode: 'en');

  /// Downloads the Digital Ink model for the specified language if it's not already downloaded.
  Future<bool> downloadModel() async {
    try {
      final modelManager = DigitalInkRecognizerModelManager();
      final isDownloaded = await modelManager.isModelDownloaded(_language);
      if (!isDownloaded) {
        return await modelManager.downloadModel(_language);
      }
      return true;
    } catch (e) {
      di.sl<AppLogger>().error(
        'DigitalInkService: Failed to download model',
        error: e,
      );
      return false;
    }
  }

  /// Checks if the model is currently downloaded.
  Future<bool> isModelDownloaded() async {
    try {
      final modelManager = DigitalInkRecognizerModelManager();
      return await modelManager.isModelDownloaded(_language);
    } catch (e) {
      return false;
    }
  }

  /// Recognizes text from a list of Ink strokes.
  Future<List<String>> recognize(Ink ink) async {
    try {
      final candidates = await _recognizer.recognize(ink);
      return candidates.map((c) => c.text).toList();
    } catch (e) {
      di.sl<AppLogger>().error(
        'DigitalInkService: Failed to recognize ink',
        error: e,
      );
      return [];
    }
  }

  void dispose() {
    _recognizer.close();
  }
}
