import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vowl/features/premium/domain/entities/subscription_plan.dart';

/// Service to fetch subscription plans from Firebase
class SubscriptionPlansService {
  final FirebaseFirestore _firestore;
  static const String _plansCollection = 'subscriptionPlans';

  // Cache plans for 1 hour
  List<SubscriptionPlan>? _cachedPlans;
  DateTime? _cacheTime;
  static const Duration _cacheExpiry = Duration(hours: 1);

  SubscriptionPlansService({required FirebaseFirestore firestore})
      : _firestore = firestore;

  /// Fetch subscription plans from Firebase (with caching)
  Future<List<SubscriptionPlan>> fetchPlans() async {
    try {
      // Return cached plans if still valid
      if (_cachedPlans != null && _cacheTime != null) {
        if (DateTime.now().difference(_cacheTime!) < _cacheExpiry) {
          debugPrint('SubscriptionPlansService: Using cached plans');
          return _cachedPlans!;
        }
      }

      debugPrint('SubscriptionPlansService: Fetching plans from Firebase');
      final snapshot = await _firestore
          .collection(_plansCollection)
          .orderBy('displayOrder')
          .get();

      final plans = snapshot.docs
          .map((doc) => SubscriptionPlan.fromMap(doc.data()))
          .toList();

      // Cache the plans
      _cachedPlans = plans;
      _cacheTime = DateTime.now();

      debugPrint('SubscriptionPlansService: Fetched ${plans.length} plans');
      return plans;
    } catch (e) {
      debugPrint('SubscriptionPlansService Error: Failed to fetch plans - $e');
      rethrow;
    }
  }

  /// Fetch single plan by ID
  Future<SubscriptionPlan?> fetchPlanById(String planId) async {
    try {
      final doc = await _firestore
          .collection(_plansCollection)
          .doc(planId)
          .get();

      if (!doc.exists) {
        debugPrint('SubscriptionPlansService: Plan not found - $planId');
        return null;
      }

      return SubscriptionPlan.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('SubscriptionPlansService Error: Failed to fetch plan - $e');
      rethrow;
    }
  }

  /// Clear cache manually
  void clearCache() {
    _cachedPlans = null;
    _cacheTime = null;
    debugPrint('SubscriptionPlansService: Cache cleared');
  }
}
