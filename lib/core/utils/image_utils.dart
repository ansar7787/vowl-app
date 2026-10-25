import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

/// Utilities for high-performance, cross-platform image processing in pure Dart.
class ImageUtils {
  const ImageUtils._();

  /// Center-crops any image file (camera photo, portrait, landscape, or custom aspect ratio)
  /// into a clean, 1:1 square image (like WhatsApp profile cropping), scaled to [targetDimension]
  /// (default: 512x512).
  ///
  /// Preserves the center subject, discards outside margins equally from both sides,
  /// and writes the output as a high-quality PNG to a temporary file.
  ///
  /// If decoding or processing fails, it gracefully falls back to returning the [sourceFile].
  static Future<File> cropToSquare(
    File sourceFile, {
    int targetDimension = 512,
  }) async {
    try {
      if (!await sourceFile.exists()) {
        return sourceFile;
      }

      final bytes = await sourceFile.readAsBytes();
      if (bytes.isEmpty) {
        return sourceFile;
      }

      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final srcWidth = image.width;
      final srcHeight = image.height;

      // Determine the largest centered square
      final squareSize = math.min(srcWidth, srcHeight);
      final srcX = (srcWidth - squareSize) / 2.0;
      final srcY = (srcHeight - squareSize) / 2.0;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final srcRect = Rect.fromLTWH(
        srcX,
        srcY,
        squareSize.toDouble(),
        squareSize.toDouble(),
      );
      final dstRect = Rect.fromLTWH(
        0,
        0,
        targetDimension.toDouble(),
        targetDimension.toDouble(),
      );

      final paint = Paint()
        ..filterQuality = FilterQuality.high
        ..isAntiAlias = true;

      canvas.drawImageRect(image, srcRect, dstRect, paint);

      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(
        targetDimension,
        targetDimension,
      );
      final byteData =
          await croppedImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        return sourceFile;
      }

      final tempDir = await getTemporaryDirectory();
      final fileName =
          'avatar_square_${DateTime.now().millisecondsSinceEpoch}.png';
      final croppedFile = File('${tempDir.path}/$fileName');

      await croppedFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
      return croppedFile;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ImageUtils.cropToSquare fallback due to error: $e');
      }
      return sourceFile;
    }
  }
}

