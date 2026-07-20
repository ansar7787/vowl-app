import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/injection_container.dart';

class CoinPack {
  final String id;
  final String titleKey;
  final String titleFallback;
  final int coins;
  final int keys;
  final double price; // INR
  final String iconName; // e.g. "monetization_on_rounded"
  final String colorHex; // e.g. "#F59E0B"
  final bool isBestValue;
  final int displayOrder;

  const CoinPack({
    required this.id,
    required this.titleKey,
    required this.titleFallback,
    required this.coins,
    required this.keys,
    required this.price,
    required this.iconName,
    required this.colorHex,
    this.isBestValue = false,
    required this.displayOrder,
  });

  factory CoinPack.fromMap(Map<String, dynamic> map, String id) {
    return CoinPack(
      id: id,
      titleKey: map['titleKey'] ?? 'store.pack',
      titleFallback: map['titleFallback'] ?? 'Coin Pack',
      coins: (map['coins'] ?? 0).toInt(),
      keys: (map['keys'] ?? 0).toInt(),
      price: (map['price'] ?? 0).toDouble(),
      iconName: map['iconName'] ?? 'monetization_on_rounded',
      colorHex: map['colorHex'] ?? '#F59E0B',
      isBestValue: map['isBestValue'] ?? false,
      displayOrder: (map['displayOrder'] ?? 99).toInt(),
    );
  }

  String get priceString => '₹${price.toInt()}';
}

/// Service to fetch coin packs from Firebase
class CoinPacksService {
  final FirebaseFirestore _firestore;
  static const String _packsCollection = 'coinPacks';

  // Cache packs for 1 hour
  List<CoinPack>? _cachedPacks;
  DateTime? _cacheTime;
  static const Duration _cacheExpiry = Duration(hours: 1);
  static const Duration _fetchTimeout = Duration(seconds: 10);

  Future<List<CoinPack>>? _pendingFetch;

  CoinPacksService({required FirebaseFirestore firestore})
    : _firestore = firestore;

  /// Fetch coin packs from Firebase (with caching)
  Future<List<CoinPack>> fetchPacks() async {
    if (_cachedPacks != null && _cacheTime != null) {
      if (DateTime.now().difference(_cacheTime!) < _cacheExpiry) {
        sl<AppLogger>().debug('CoinPacksService: Using cached packs');
        return _cachedPacks!;
      }
    }

    final pending = _pendingFetch;
    if (pending != null) {
      sl<AppLogger>().debug(
        'CoinPacksService: Coalescing concurrent fetchPacks() call',
      );
      return pending;
    }

    final future = _fetchPacksFromFirestore();
    _pendingFetch = future;
    try {
      return await future;
    } finally {
      _pendingFetch = null;
    }
  }

  Future<List<CoinPack>> _fetchPacksFromFirestore() async {
    try {
      sl<AppLogger>().debug(
        'CoinPacksService: Fetching packs from Firebase',
      );
      final snapshot = await _firestore
          .collection(_packsCollection)
          .orderBy('displayOrder')
          .get()
          .timeout(_fetchTimeout);

      final packs = snapshot.docs
          .map((doc) => CoinPack.fromMap(doc.data(), doc.id))
          .toList();

      _cachedPacks = packs;
      _cacheTime = DateTime.now();

      sl<AppLogger>().debug(
        'CoinPacksService: Fetched ${packs.length} packs',
      );
      return packs;
    } catch (e, stackTrace) {
      sl<AppLogger>().error(
        'CoinPacksService: Failed to fetch packs',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  void clearCache() {
    _cachedPacks = null;
    _cacheTime = null;
    sl<AppLogger>().debug('CoinPacksService: Cache cleared');
  }
}
