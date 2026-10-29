import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Translations Integrity and Zero-Contamination Suite', () {
    const supportedLangs = [
      'en',
      'ar',
      'bn',
      'de',
      'es',
      'fr',
      'gu',
      'hi',
      'ja',
      'kn',
      'ko',
      'ml',
      'mr',
      'pt',
      'ru',
      'ta',
      'te',
      'zh',
    ];

    Map<String, dynamic> flatten(Map<String, dynamic> map, [String prefix = '']) {
      final result = <String, dynamic>{};
      for (final entry in map.entries) {
        final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
        if (entry.value is Map<String, dynamic>) {
          result.addAll(flatten(entry.value as Map<String, dynamic>, key));
        } else {
          result[key] = entry.value;
        }
      }
      return result;
    }

    List<String> extractPlaceholders(String text) {
      final regex = RegExp(r'\{[^}]+\}');
      final matches = regex.allMatches(text).map((m) => m.group(0)!).toList();
      matches.sort();
      return matches;
    }

    late Map<String, dynamic> enFlat;

    setUpAll(() {
      final enFile = File('assets/translations/en.json');
      expect(enFile.existsSync(), isTrue, reason: 'assets/translations/en.json must exist');
      final enJson = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
      enFlat = flatten(enJson);
      expect(enFlat.length, equals(3758), reason: 'en.json must have exactly 3758 leaf keys');
    });

    for (final lang in supportedLangs.where((l) => l != 'en')) {
      test('[$lang] matches en.json structure, key count, and placeholders', () {
        final file = File('assets/translations/$lang.json');
        expect(file.existsSync(), isTrue, reason: 'assets/translations/$lang.json must exist');

        final content = file.readAsStringSync();
        final Map<String, dynamic> rawJson = jsonDecode(content) as Map<String, dynamic>;
        final flat = flatten(rawJson);

        // 1. Exact key count
        expect(flat.length, equals(enFlat.length),
            reason: '$lang.json has ${flat.length} keys, expected ${enFlat.length}');

        // 2. Exact key parity
        for (final enKey in enFlat.keys) {
          expect(flat.containsKey(enKey), isTrue,
              reason: '$lang.json is missing key "$enKey"');

          final enVal = enFlat[enKey];
          final langVal = flat[enKey];

          if (enVal is String && langVal is String) {
            final enPlaceholders = extractPlaceholders(enVal);
            final langPlaceholders = extractPlaceholders(langVal);
            expect(langPlaceholders, equals(enPlaceholders),
                reason: 'Placeholder mismatch in [$lang] for "$enKey": expected $enPlaceholders, got $langPlaceholders');
          }
        }
      });

      test('[$lang] has zero foreign script contamination or broken characters', () {
        final file = File('assets/translations/$lang.json');
        final Map<String, dynamic> rawJson = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final flat = flatten(rawJson);

        final contaminatedKeys = <String>[];

        for (final entry in flat.entries) {
          if (entry.value is! String) continue;
          final str = entry.value as String;

          for (int i = 0; i < str.length; i++) {
            final code = str.codeUnitAt(i);
            if (code < 128) continue;
            if (code <= 0x024F) continue; // Latin
            if (code >= 0x0300 && code <= 0x036F) continue; // Combining marks
            if (code >= 0x2000 && code <= 0x2BFF) continue; // Punctuation & symbols
            if (code >= 0x3000 && code <= 0x303F) continue; // CJK Punctuation
            if (code >= 0xD800 && code <= 0xDFFF) continue; // Surrogates (emojis)
            if (code >= 0xFF00 && code <= 0xFFEF) continue; // Fullwidth forms

            // Language-specific allowed ranges:
            if (lang == 'ar' && ((code >= 0x0600 && code <= 0x08FF) || (code >= 0xFB50 && code <= 0xFDFF) || (code >= 0xFE70 && code <= 0xFEFF))) continue;
            if (lang == 'ru' && (code >= 0x0400 && code <= 0x04FF)) continue;
            if (lang == 'bn' && ((code >= 0x0980 && code <= 0x09FF) || code == 0x0964 || code == 0x0965)) continue;
            if ((lang == 'hi' || lang == 'mr') && (code >= 0x0900 && code <= 0x097F)) continue;
            if (lang == 'gu' && (code >= 0x0A80 && code <= 0x0AFF)) continue;
            if (lang == 'ta' && (code >= 0x0B80 && code <= 0x0BFF)) continue;
            if (lang == 'te' && (code >= 0x0C00 && code <= 0x0C7F)) continue;
            if (lang == 'kn' && (code >= 0x0C80 && code <= 0x0CFF)) continue;
            if (lang == 'ml' && (code >= 0x0D00 && code <= 0x0D7F)) continue;
            if (lang == 'ko' && ((code >= 0xAC00 && code <= 0xD7AF) || (code >= 0x1100 && code <= 0x11FF) || (code >= 0x3130 && code <= 0x318F))) continue;
            if (lang == 'ja' && ((code >= 0x3040 && code <= 0x309F) || (code >= 0x30A0 && code <= 0x30FF) || (code >= 0x4E00 && code <= 0x9FFF) || (code >= 0x3400 && code <= 0x4DBF))) continue;
            if (lang == 'zh' && ((code >= 0x4E00 && code <= 0x9FFF) || (code >= 0x3400 && code <= 0x4DBF))) continue;

            contaminatedKeys.add('${entry.key}: U+${code.toRadixString(16).toUpperCase()} ("${str[i]}") in "$str"');
            break;
          }
        }

        expect(contaminatedKeys, isEmpty,
            reason: 'Found ${contaminatedKeys.length} contaminated strings in $lang.json:\n${contaminatedKeys.take(10).join('\n')}');
      });
    }
  });
}

