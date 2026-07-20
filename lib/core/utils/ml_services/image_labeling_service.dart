import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class ImageLabelingService {
  late final ImageLabeler _labeler;

  ImageLabelingService() {
    final options = ImageLabelerOptions(confidenceThreshold: 0.7);
    _labeler = ImageLabeler(options: options);
  }

  /// Extracts labels from the provided image path.
  Future<List<ImageLabel>> labelImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      return await _labeler.processImage(inputImage);
    } catch (e) {
      di.sl<AppLogger>().error('ImageLabelingService: Failed to label image', error: e);
      return [];
    }
  }

  void dispose() {
    _labeler.close();
  }
}
