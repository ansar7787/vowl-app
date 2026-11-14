import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vowl/features/auth/domain/constants/user_game_constants.dart';

/// Centralized utility for managing the [coinHistory] ledger across all
/// repositories and presentation components in VOWL.
///
/// Guarantees consistent serialization, standard schema, and chronological
/// retention limit across the entire codebase.
abstract final class CoinLedgerHelper {
  /// Default ledger retention limit.
  static const int defaultLimit = 20;

  /// Defensively parses a dynamic Firestore raw value into a typed list of maps.
  static List<Map<String, dynamic>> parseMapList(dynamic raw) {
    if (raw == null) return <Map<String, dynamic>>[];
    if (raw is! List) return <Map<String, dynamic>>[];

    return raw
        .whereType<Map<Object?, Object?>>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }

  /// Prepends a new transaction entry to [existing] and trims to [limit].
  ///
  /// Index `0` is always the NEWEST transaction.
  /// Standard schema:
  /// - `titleKey`: String (localization key)
  /// - `amount`: int (positive for earnings, negative for spends)
  /// - `isEarned`: bool
  /// - `date`: ISO-8601 String
  /// - `params`: `Map<String, dynamic>?` (optional interpolation data)
  static List<Map<String, dynamic>> recordEntry(
    List<Map<String, dynamic>> existing, {
    required String titleKey,
    required int amount,
    required bool isEarned,
    Map<String, dynamic>? params,
    int? limit,
  }) {
    final effectiveLimit = limit ?? UserGameConstants.kActivityHistoryLimit;
    final updated = List<Map<String, dynamic>>.from(existing)
      ..insert(0, {
        'titleKey': titleKey,
        // ignore: use_null_aware_elements
        if (params != null) 'params': params,
        'amount': amount,
        'isEarned': isEarned,
        'date': DateTime.now().toIso8601String(),
      });

    if (updated.length > effectiveLimit) {
      return updated.sublist(0, effectiveLimit);
    }
    return updated;
  }

  /// Defensively parses the transaction timestamp from either:
  /// 1. Standard ISO-8601 String in `'date'`
  /// 2. Legacy Firestore `Timestamp` or int in `'timestamp'` or `'date'`
  static DateTime? parseTransactionDate(Map<String, dynamic> txn) {
    final rawDate = txn['date'] ?? txn['timestamp'];
    if (rawDate == null) return null;

    if (rawDate is String) {
      return DateTime.tryParse(rawDate);
    }
    if (rawDate is Timestamp) {
      return rawDate.toDate();
    }
    if (rawDate is int) {
      return DateTime.fromMillisecondsSinceEpoch(rawDate);
    }
    return null;
  }
}
