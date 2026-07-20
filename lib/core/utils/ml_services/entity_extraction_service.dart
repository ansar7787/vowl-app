import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:flutter/material.dart';

class EntityExtractionService {
  final EntityExtractor _extractor;

  EntityExtractionService()
      : _extractor = EntityExtractor(language: EntityExtractorLanguage.english);

  /// Downloads the English entity extraction model if not present.
  Future<bool> downloadModel() async {
    try {
      final modelManager = EntityExtractorModelManager();
      final isDownloaded = await modelManager.isModelDownloaded(EntityExtractorLanguage.english.name);
      if (!isDownloaded) {
        return await modelManager.downloadModel(EntityExtractorLanguage.english.name);
      }
      return true;
    } catch (e) {
      di.sl<AppLogger>().error('EntityExtractionService: Failed to download model', error: e);
      return false;
    }
  }

  /// Extracts entities from the provided text.
  Future<List<EntityAnnotation>> extractEntities(String text) async {
    try {
      return await _extractor.annotateText(text);
    } catch (e) {
      di.sl<AppLogger>().error('EntityExtractionService: Failed to extract entities', error: e);
      return [];
    }
  }

  /// Helper to get a consistent color for an entity type.
  Color getColorForEntity(EntityType type) {
    switch (type) {
      case EntityType.address:
        return Colors.green;
      case EntityType.dateTime:
        return Colors.orange;
      case EntityType.email:
        return Colors.blue;
      case EntityType.flightNumber:
        return Colors.cyan;
      case EntityType.iban:
        return Colors.amber;
      case EntityType.isbn:
        return Colors.teal;
      case EntityType.money:
        return Colors.yellow.shade700;
      case EntityType.paymentCard:
        return Colors.pink;
      case EntityType.phone:
        return Colors.indigo;
      case EntityType.trackingNumber:
        return Colors.purple;
      case EntityType.url:
        return Colors.lightBlue;
      default:
        return Colors.grey;
    }
  }

  void dispose() {
    _extractor.close();
  }
}
