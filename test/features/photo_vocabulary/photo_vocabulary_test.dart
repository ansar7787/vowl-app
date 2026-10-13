import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/photo_vocabulary/utils/photo_vocabulary_dictionary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PhotoVocabularyDictionary & Bounty Matching Tests', () {
    test('PhotoVocabularyDictionary contains all 60 bounties from photo_bounties.json', () async {
      final jsonStr = await rootBundle.loadString('assets/data/photo_bounties.json');
      final List<dynamic> bounties = jsonDecode(jsonStr);

      expect(bounties.length, greaterThanOrEqualTo(60)); // Expanded curriculum (210 items for 2-year retention)

      for (final item in bounties) {
        final String name = item as String;
        final entry = PhotoVocabularyDictionary.getEntry(name);

        expect(entry.definition.isNotEmpty, isTrue,
            reason: 'Definition should be non-empty for $name');
        expect(entry.example.isNotEmpty, isTrue,
            reason: 'Example should be non-empty for $name');
        expect(entry.grammarTip.isNotEmpty, isTrue,
            reason: 'Grammar tip should be non-empty for $name');
      }
    });

    test('isBountyMatch handles exact matches and case insensitivity', () {
      expect(PhotoVocabularyDictionary.isBountyMatch('Coffee cup', 'Coffee cup'), isTrue);
      expect(PhotoVocabularyDictionary.isBountyMatch('backpack', 'Backpack'), isTrue);
      expect(PhotoVocabularyDictionary.isBountyMatch('Chair', 'chair'), isTrue);
    });

    test('isBountyMatch handles plural and singular stem normalization', () {
      expect(PhotoVocabularyDictionary.isBountyMatch('Shoe', 'shoes'), isTrue);
      expect(PhotoVocabularyDictionary.isBountyMatch('Shoes', 'shoe'), isTrue);
      expect(PhotoVocabularyDictionary.isBountyMatch('Key', 'keys'), isTrue);
      expect(PhotoVocabularyDictionary.isBountyMatch('Dog', 'dogs'), isTrue);
      expect(PhotoVocabularyDictionary.isBountyMatch('Apple', 'apples'), isTrue);
    });

    test('isBountyMatch handles compound and space variations', () {
      expect(PhotoVocabularyDictionary.isBountyMatch('Houseplant', 'House plant'), isTrue);
      expect(PhotoVocabularyDictionary.isBountyMatch('House plant', 'houseplant'), isTrue);
      expect(PhotoVocabularyDictionary.isBountyMatch('Picture frame', 'photo frame'), isTrue);
    });

    test('isBountyMatch handles aliases and common computer vision labels', () {
      // Television / TV
      expect(PhotoVocabularyDictionary.isBountyMatch('Television', 'TV'), isTrue);
      expect(PhotoVocabularyDictionary.isBountyMatch('Television', 'screen'), isTrue);

      // Refrigerator / Fridge
      expect(PhotoVocabularyDictionary.isBountyMatch('Refrigerator', 'fridge'), isTrue);

      // Coffee cup / Mug / Cup
      expect(PhotoVocabularyDictionary.isBountyMatch('Coffee cup', 'mug'), isTrue);
      expect(PhotoVocabularyDictionary.isBountyMatch('Coffee cup', 'cup'), isTrue);

      // Glasses / Eyewear / Sunglasses
      expect(PhotoVocabularyDictionary.isBountyMatch('Glasses', 'eyewear'), isTrue);
      expect(PhotoVocabularyDictionary.isBountyMatch('Glasses', 'sunglasses'), isTrue);

      // Shoe / Sneakers / Footwear
      expect(PhotoVocabularyDictionary.isBountyMatch('Shoe', 'sneakers'), isTrue);
      expect(PhotoVocabularyDictionary.isBountyMatch('Shoe', 'footwear'), isTrue);

      // Phone / Smartphone / Cell phone
      expect(PhotoVocabularyDictionary.isBountyMatch('Phone', 'smartphone'), isTrue);
      expect(PhotoVocabularyDictionary.isBountyMatch('Phone', 'cell phone'), isTrue);

      // Bicycle / Bike
      expect(PhotoVocabularyDictionary.isBountyMatch('Bicycle', 'bike'), isTrue);
    });

    test('isBountyMatch correctly rejects non-matching labels', () {
      expect(PhotoVocabularyDictionary.isBountyMatch('Coffee cup', 'Shoe'), isFalse);
      expect(PhotoVocabularyDictionary.isBountyMatch('Dog', 'Cat'), isFalse);
      expect(PhotoVocabularyDictionary.isBountyMatch('Refrigerator', 'Bicycle'), isFalse);
    });

    test('getEntry resolves singular and plural forms bidirectionally', () {
      final keyEntry = PhotoVocabularyDictionary.getEntry('key');
      expect(keyEntry.definition, contains('open locks'));

      final shoesEntry = PhotoVocabularyDictionary.getEntry('shoes');
      expect(shoesEntry.definition, contains('foot'));
    });

    test('Smart fallback generates valid entry for unknown arbitrary word', () {
      final entry = PhotoVocabularyDictionary.getEntry('Xylophone');
      expect(entry.definition, contains('identified in your environment'));
      expect(entry.example, contains('xylophone'));
      expect(entry.grammarTip, contains('Grammar:'));
    });
  });
}
