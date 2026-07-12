import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/features/premium/domain/entities/subscription_plan.dart';
import 'package:vowl/core/utils/injection_container.dart';

/// Service to fetch subscription plans from Firebase
class SubscriptionPlansService {
  final FirebaseFirestore _firestore;
  static const String _plansCollection = 'subscriptionPlans';

  // Cache plans for 1 hour
  List<SubscriptionPlan>? _cachedPlans;
  DateTime? _cacheTime;
  static const Duration _cacheExpiry = Duration(hours: 1);
  static const Duration _fetchTimeout = Duration(seconds: 10);

  /// REQUEST COALESCING: if `fetchPlans()` is already in flight (e.g. the
  /// premium screen and some other screen both call it around the same
  /// moment while the cache is still cold), a second call reuses the same
  /// pending Future instead of firing a second simultaneous Firestore
  /// query. Mirrors the pattern already used in `asset_quest_service.dart`
  /// for the same reason: at scale, duplicate reads are a direct,
  /// avoidable Firestore cost, not just a performance nicety.
  Future<List<SubscriptionPlan>>? _pendingFetch;

  SubscriptionPlansService({required FirebaseFirestore firestore})
    : _firestore = firestore;

  /// Fetch subscription plans from Firebase (with caching)
  Future<List<SubscriptionPlan>> fetchPlans() async {
    // Return cached plans if still valid
    if (_cachedPlans != null && _cacheTime != null) {
      if (DateTime.now().difference(_cacheTime!) < _cacheExpiry) {
        sl<AppLogger>().debug('SubscriptionPlansService: Using cached plans');
        return _cachedPlans!;
      }
    }

    final pending = _pendingFetch;
    if (pending != null) {
      sl<AppLogger>().debug(
        'SubscriptionPlansService: Coalescing concurrent fetchPlans() call',
      );
      return pending;
    }

    final future = _fetchPlansFromFirestore();
    _pendingFetch = future;
    try {
      return await future;
    } finally {
      _pendingFetch = null;
    }
  }

  Future<List<SubscriptionPlan>> _fetchPlansFromFirestore() async {
    try {
      sl<AppLogger>().debug(
        'SubscriptionPlansService: Fetching plans from Firebase',
      );
      final snapshot = await _firestore
          .collection(_plansCollection)
          .orderBy('displayOrder')
          .get()
          .timeout(_fetchTimeout);

      final plans = snapshot.docs
          .map((doc) => SubscriptionPlan.fromMap(doc.data()))
          .toList();

      // Cache the plans
      _cachedPlans = plans;
      _cacheTime = DateTime.now();

      sl<AppLogger>().debug(
        'SubscriptionPlansService: Fetched ${plans.length} plans',
      );
      return plans;
    } catch (e, stackTrace) {
      sl<AppLogger>().error(
        'SubscriptionPlansService: Failed to fetch plans',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Fetch single plan by ID
  Future<SubscriptionPlan?> fetchPlanById(String planId) async {
    try {
      final doc = await _firestore
          .collection(_plansCollection)
          .doc(planId)
          .get()
          .timeout(_fetchTimeout);

      if (!doc.exists) {
        sl<AppLogger>().warning(
          'SubscriptionPlansService: Plan not found - $planId',
        );
        return null;
      }

      return SubscriptionPlan.fromMap(doc.data()!);
    } catch (e, stackTrace) {
      sl<AppLogger>().error(
        'SubscriptionPlansService: Failed to fetch plan $planId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Clear cache manually
  void clearCache() {
    _cachedPlans = null;
    _cacheTime = null;
    sl<AppLogger>().debug('SubscriptionPlansService: Cache cleared');
  }
}
