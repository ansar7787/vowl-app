import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

      // Guard: skip Firestore query if the user is not authenticated.
      // Firestore rules require `request.auth != null`, so querying
      // without auth would always return PERMISSION_DENIED.
      if (FirebaseAuth.instance.currentUser == null) {
        debugPrint('SubscriptionPlansService: No authenticated user, using fallback plans');
        final fallbackPlans = _getFallbackPlans();
        _cachedPlans = fallbackPlans;
        _cacheTime = DateTime.now();
        return fallbackPlans;
      }

      debugPrint('SubscriptionPlansService: Fetching plans from Firebase');
      final snapshot = await _firestore
          .collection(_plansCollection)
          .orderBy('displayOrder')
          .get();

      List<SubscriptionPlan> plans = snapshot.docs
          .map((doc) => SubscriptionPlan.fromMap(doc.data()))
          .toList();

      if (plans.isEmpty) {
        debugPrint('SubscriptionPlansService: Collection empty, using fallback plans');
        plans = _getFallbackPlans();
      }

      // Cache the plans
      _cachedPlans = plans;
      _cacheTime = DateTime.now();

      debugPrint('SubscriptionPlansService: Fetched ${plans.length} plans');
      return plans;
    } catch (e) {
      debugPrint('SubscriptionPlansService Error: Failed to fetch plans - $e');
      // Use fallback plans on network/permission error
      final fallbackPlans = _getFallbackPlans();
      _cachedPlans = fallbackPlans;
      _cacheTime = DateTime.now();
      return fallbackPlans;
    }
  }

  List<SubscriptionPlan> _getFallbackPlans() {
    return [
      SubscriptionPlan(
        id: 'weekly_offer',
        name: 'Weekly',
        price: 39.0,
        oldPrice: 49.0,
        days: 7,
        tag: 'FESTIVE OFFER',
        color: '#FFF43F5E', // Rose
        displayOrder: 0,
      ),
      SubscriptionPlan(
        id: 'monthly_offer',
        name: 'Monthly',
        price: 99.0,
        oldPrice: 149.0,
        days: 30,
        tag: 'MOST POPULAR',
        color: '#FF6366F1', // Indigo
        displayOrder: 1,
      ),
      SubscriptionPlan(
        id: 'yearly_offer',
        name: 'Yearly',
        price: 799.0,
        oldPrice: 1499.0,
        days: 365,
        tag: 'BEST VALUE',
        color: '#FF10B981', // Emerald
        displayOrder: 2,
      ),
    ];
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
