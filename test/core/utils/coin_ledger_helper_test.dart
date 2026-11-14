import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/utils/coin_ledger_helper.dart';

void main() {
  group('CoinLedgerHelper', () {
    group('parseMapList', () {
      test('should return empty list when given null or empty', () {
        expect(CoinLedgerHelper.parseMapList(null), isEmpty);
        expect(CoinLedgerHelper.parseMapList([]), isEmpty);
      });

      test('should correctly parse and sanitize map elements', () {
        final raw = [
          {'titleKey': 'chest_reward', 'amount': 100},
          'invalid string',
          42,
          {'titleKey': 'shop_hint', 'amount': -50},
        ];

        final result = CoinLedgerHelper.parseMapList(raw);
        expect(result.length, 2);
        expect(result[0]['titleKey'], 'chest_reward');
        expect(result[0]['amount'], 100);
        expect(result[1]['titleKey'], 'shop_hint');
        expect(result[1]['amount'], -50);
      });
    });

    group('recordEntry', () {
      test('should prepend entry with date and capped to limit', () {
        final initialHistory = [
          {'titleKey': 'old_1', 'amount': 10, 'isEarned': true, 'date': '2026-01-01T00:00:00.000Z'},
          {'titleKey': 'old_2', 'amount': 20, 'isEarned': true, 'date': '2026-01-02T00:00:00.000Z'},
        ];

        final updated = CoinLedgerHelper.recordEntry(
          initialHistory,
          titleKey: 'daily_mystery_chest',
          amount: 50,
          isEarned: true,
          limit: 2,
        );

        expect(updated.length, 2);
        expect(updated[0]['titleKey'], 'daily_mystery_chest');
        expect(updated[0]['amount'], 50);
        expect(updated[0]['isEarned'], true);
        expect(updated[0]['date'], isA<String>());
        // Old 2 should be dropped due to limit=2
        expect(updated[1]['titleKey'], 'old_1');
      });

      test('should correctly store params when provided', () {
        final updated = CoinLedgerHelper.recordEntry(
          [],
          titleKey: 'streak_milestone_coins',
          amount: 25,
          isEarned: true,
          params: {'streak': 7},
        );

        expect(updated.length, 1);
        expect(updated[0]['params'], {'streak': 7});
        expect(updated[0]['isEarned'], true);
      });
    });

    group('parseTransactionDate', () {
      test('should parse ISO 8601 string from date field', () {
        final dt = DateTime(2026, 11, 14, 10, 30);
        final parsed = CoinLedgerHelper.parseTransactionDate({
          'date': dt.toIso8601String(),
        });
        expect(parsed?.year, 2026);
        expect(parsed?.month, 11);
        expect(parsed?.day, 14);
      });

      test('should parse legacy integer milliseconds epoch from timestamp field', () {
        final now = DateTime.now();
        final ms = now.millisecondsSinceEpoch;
        final parsed = CoinLedgerHelper.parseTransactionDate({
          'timestamp': ms,
        });
        expect(parsed?.millisecondsSinceEpoch, ms);
      });

      test('should parse Firestore Timestamp instance', () {
        final now = DateTime.now();
        final ts = Timestamp.fromDate(now);
        final parsed = CoinLedgerHelper.parseTransactionDate({
          'timestamp': ts,
        });
        expect(parsed?.millisecondsSinceEpoch, ts.millisecondsSinceEpoch);
      });

      test('should return null when date and timestamp are absent or invalid', () {
        expect(CoinLedgerHelper.parseTransactionDate({}), isNull);
        expect(CoinLedgerHelper.parseTransactionDate({'date': 'not-a-date'}), isNull);
      });
    });
  });
}
