import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

/// Service providing on-device handwriting and stroke recognition using Google ML Kit Digital Ink.
///
/// Implements transparent, non-blocking background model downloading with memoization,
/// in-flight request deduplication, and graceful offline fallback.
class DigitalInkService {
  final DigitalInkRecognizer _recognizer;
  final String _language = 'en'; // English model

  Future<bool>? _downloadFuture;
  bool _isDownloadedCached = false;

  DigitalInkService() : _recognizer = DigitalInkRecognizer(languageCode: 'en');

  /// Checks if the model is currently downloaded.
  ///
  /// Caches a positive result in memory to avoid repeated asynchronous bridge roundtrips.
  Future<bool> isModelDownloaded() async {
    if (_isDownloadedCached) return true;
    try {
      final modelManager = DigitalInkRecognizerModelManager();
      final downloaded = await modelManager.isModelDownloaded(_language);
      if (downloaded) {
        _isDownloadedCached = true;
      }
      return downloaded;
    } catch (_) {
      return false;
    }
  }

  /// Downloads the Digital Ink model smoothly in the background.
  ///
  /// Deduplicates concurrent download requests by returning the existing in-flight future.
  Future<bool> downloadModel() {
    if (_isDownloadedCached) return Future.value(true);
    if (_downloadFuture != null) return _downloadFuture!;

    _downloadFuture = _performDownload();
    return _downloadFuture!;
  }

  Future<bool> _performDownload() async {
    try {
      final modelManager = DigitalInkRecognizerModelManager();
      final isDownloaded = await modelManager.isModelDownloaded(_language);
      if (!isDownloaded) {
        final success = await modelManager.downloadModel(_language);
        if (success) {
          _isDownloadedCached = true;
        }
        return success;
      }
      _isDownloadedCached = true;
      return true;
    } catch (e) {
      try {
        if (di.sl.isRegistered<AppLogger>()) {
          di.sl<AppLogger>().warning(
            'DigitalInkService: Model download unavailable: $e',
            tag: 'DigitalInkService',
          );
        }
      } catch (_) {}
      return false;
    } finally {
      _downloadFuture = null;
    }
  }

  /// Recognizes text from a list of Ink strokes.
  ///
  /// If a background download is currently finishing, it seamlessly awaits completion.
  /// If the device is offline or the model is unavailable, gracefully returns an empty list
  /// so downstream evaluators seamlessly fall back to geometric heuristic evaluation.
  Future<List<String>> recognize(Ink ink) async {
    try {
      // If a background download is already in flight, seamlessly await it
      if (_downloadFuture != null) {
        await _downloadFuture;
      } else {
        final downloaded = await isModelDownloaded();
        if (!downloaded) {
          final ok = await downloadModel();
          if (!ok) {
            return const [];
          }
        }
      }

      final candidates = await _recognizer.recognize(ink);
      return candidates.map((c) => c.text).toList();
    } catch (e) {
      try {
        if (di.sl.isRegistered<AppLogger>()) {
          di.sl<AppLogger>().warning(
            'DigitalInkService: Recognition fallback: $e',
            tag: 'DigitalInkService',
          );
        }
      } catch (_) {}
      return const [];
    }
  }

  void dispose() {
    _recognizer.close();
  }
}
