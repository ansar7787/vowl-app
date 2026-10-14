import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/scan_and_learn/utils/scan_vocabulary_dictionary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScanVocabularyDictionary & OCR Matching Tests', () {
    test('ScanVocabularyDictionary contains entries for all 62 bounties from scan_bounties.json', () async {
      final jsonStr = await rootBundle.loadString('assets/data/scan_bounties.json');
      final List<dynamic> bounties = jsonDecode(jsonStr);

      expect(bounties.length, equals(61));

      for (final item in bounties) {
        final String name = item as String;
        final entry = ScanVocabularyDictionary.getEntry(name);

        expect(entry.meaning.isNotEmpty, isTrue,
            reason: 'Meaning should be non-empty for $name');
        expect(entry.signCategory.isNotEmpty, isTrue,
            reason: 'Sign category should be non-empty for $name');
        expect(entry.realWorldTip.isNotEmpty, isTrue,
            reason: 'Real world tip should be non-empty for $name');
      }
    });

    test('isBountyMatch handles exact matches and case insensitivity', () {
      expect(ScanVocabularyDictionary.isBountyMatch('Exit', 'EXIT'), isTrue);
      expect(ScanVocabularyDictionary.isBountyMatch('Open', 'OPEN NOW'), isTrue);
      expect(ScanVocabularyDictionary.isBountyMatch('Warning', 'Warning: High Voltage'), isTrue);
      expect(ScanVocabularyDictionary.isBountyMatch('Coffee', 'Hot Coffee available inside'), isTrue);
    });

    test('isBountyMatch rejects false substring positives', () {
      // "Bus" must NOT match "Business"
      expect(ScanVocabularyDictionary.isBountyMatch('Bus', 'Open for business hours'), isFalse);

      // "Pay" must NOT match "Payment" when using word boundary, or "Player"
      expect(ScanVocabularyDictionary.isBountyMatch('Pay', 'A basketball player'), isFalse);
    });

    test('isBountyMatch handles plural and singular stem normalization', () {
      expect(ScanVocabularyDictionary.isBountyMatch('Restroom', 'Public Restrooms Ahead'), isTrue);
      expect(ScanVocabularyDictionary.isBountyMatch('Card', 'Debit and Credit Cards Accepted'), isTrue);
      expect(ScanVocabularyDictionary.isBountyMatch('Drinks', 'Cold drink corner'), isTrue);
    });

    test('isBountyMatch handles compound and space/hyphen variations', () {
      expect(ScanVocabularyDictionary.isBountyMatch('No Smoking', 'NO-SMOKING AREA'), isTrue);
      expect(ScanVocabularyDictionary.isBountyMatch('Supermarket', 'City Super Market'), isTrue);
    });

    test('isBountyMatch handles signage domain aliases', () {
      // Restroom / Toilet / WC / Washroom
      expect(ScanVocabularyDictionary.isBountyMatch('Restroom', 'Toilet on 2nd floor'), isTrue);
      expect(ScanVocabularyDictionary.isBountyMatch('Restroom', 'Public WC'), isTrue);
      expect(ScanVocabularyDictionary.isBountyMatch('Toilet', 'Washroom'), isTrue);

      // Entrance / Way In
      expect(ScanVocabularyDictionary.isBountyMatch('Entrance', 'Main Entry'), isTrue);
      expect(ScanVocabularyDictionary.isBountyMatch('Entrance', 'Way In'), isTrue);

      // Exit / Way Out
      expect(ScanVocabularyDictionary.isBountyMatch('Exit', 'Emergency Way Out'), isTrue);

      // Pharmacy / Chemist / Drugstore
      expect(ScanVocabularyDictionary.isBountyMatch('Pharmacy', 'Local Chemist shop'), isTrue);
      expect(ScanVocabularyDictionary.isBountyMatch('Pharmacy', '24h Drugstore'), isTrue);

      // Receipt / Bill
      expect(ScanVocabularyDictionary.isBountyMatch('Receipt', 'Please pay your bill at counter'), isTrue);
    });

    test('isBountyMatch correctly rejects non-matching text', () {
      expect(ScanVocabularyDictionary.isBountyMatch('Exit', 'Please enter through front'), isFalse);
      expect(ScanVocabularyDictionary.isBountyMatch('Coffee', 'Fresh bread on sale'), isFalse);
      expect(ScanVocabularyDictionary.isBountyMatch('Danger', 'Welcome to our peaceful garden'), isFalse);
    });

    test('Smart fallback generates valid entry for unknown arbitrary sign', () {
      final entry = ScanVocabularyDictionary.getEntry('Unknown Sign');
      expect(entry.meaning, contains('Real-world printed text'));
      expect(entry.signCategory, equals('Scanned Printed Sign'));
      expect(entry.realWorldTip, contains('context'));
    });
  });
}

