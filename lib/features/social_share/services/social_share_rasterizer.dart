import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class SocialShareRasterizer {
  SocialShareRasterizer._();

  /// Captures a [RepaintBoundary] identified by [boundaryKey] as a high-DPI PNG image,
  /// saves it to local temporary cache, and opens the native OS Share Sheet.
  /// Automatically cleans up the cache file when done.
  static Future<void> captureAndShare({
    required GlobalKey boundaryKey,
    String? shareText,
    String? subject,
  }) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) {
        debugPrint('[SocialShareRasterizer] Boundary context not found.');
        return;
      }

      // High quality 3.0 pixel ratio for crisp rendering on retina/Instagram/WhatsApp
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/vowl_milestone_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: shareText ?? 'Proud of my progress on Vowl! 🚀',
          subject: subject ?? 'My Vowl Milestone',
        ),
      );

      // Clean up temp file
      if (await file.exists()) {
        await file.delete().catchError((_) => file);
      }
    } catch (e) {
      debugPrint('[SocialShareRasterizer] Error capturing share card: $e');
    }
  }
}
