import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/presentation/feature_catalog/app_feature_catalog.dart';

void main() {
  group('AppFeatureCatalog verification', () {
    test('contains comprehensive feature items covering all 6 categories', () {
      final features = AppFeatureCatalog.allFeatures;
      expect(features, isNotEmpty);
      expect(features.length, greaterThanOrEqualTo(20));

      final categories = features.map((f) => f.category).toSet();
      expect(categories.length, equals(FeatureCategory.values.length));
    });

    test('every feature item has non-empty metadata and valid route', () {
      for (final item in AppFeatureCatalog.allFeatures) {
        expect(item.id, isNotEmpty);
        expect(item.title, isNotEmpty);
        expect(item.subtitle, isNotEmpty);
        expect(item.route, isNotEmpty);
        expect(item.route.startsWith('/'), isTrue);
      }
    });

    test('all distinct core pillars are registered', () {
      final ids = AppFeatureCatalog.allFeatures.map((f) => f.id).toSet();
      expect(ids.contains('games_hub'), isTrue);
      expect(ids.contains('speaking_pillar'), isTrue);
      expect(ids.contains('photo_vocab'), isTrue);
      expect(ids.contains('scan_and_learn'), isTrue);
      expect(ids.contains('offline_translate'), isTrue);
      expect(ids.contains('learning_report'), isTrue);
      expect(ids.contains('review_mistakes'), isTrue);
      expect(ids.contains('buddy_boutique'), isTrue);
      expect(ids.contains('kids_zone'), isTrue);
      expect(ids.contains('kids_room'), isTrue);
      expect(ids.contains('kids_handwriting'), isTrue);
      expect(ids.contains('kids_stickers'), isTrue);
      expect(ids.contains('voice_accents'), isTrue);
    });
  });
}
