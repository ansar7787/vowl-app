import 'package:flutter/material.dart';

/// Domain entity representing a purchasable subscription plan.
///
/// Kept free of any Firebase/Razorpay specific types so it can be used
/// across the data, domain and presentation layers without violating
/// Clean Architecture boundaries.
@immutable
class SubscriptionPlan {
  final String id;
  final String name;
  final double price;
  final double oldPrice;
  final int days;
  final String tag;
  final String color; // Stored as hex string for serialization, e.g. '#F43F5E'
  final int displayOrder;

  /// Fallback color used if [color] cannot be parsed. Chosen to be a neutral,
  /// visually-obvious "something is wrong" indicator without crashing the UI.
  static const Color _fallbackColor = Color(0xFF94A3B8);

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.oldPrice,
    required this.days,
    required this.tag,
    required this.color,
    required this.displayOrder,
  });

  /// Convert to Firebase-friendly map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'oldPrice': oldPrice,
      'days': days,
      'tag': tag,
      'color': color,
      'displayOrder': displayOrder,
    };
  }

  /// Create from Firebase map.
  ///
  /// Throws a descriptive [FormatException] (instead of an opaque
  /// `type 'Null' is not a subtype of type 'String'`-style error) if the
  /// remote document is missing or has malformed fields, so failures are
  /// easy to diagnose from crash reports.
  factory SubscriptionPlan.fromMap(Map<String, dynamic> map) {
    try {
      return SubscriptionPlan(
        id: map['id'] as String,
        name: map['name'] as String,
        price: (map['price'] as num).toDouble(),
        oldPrice: (map['oldPrice'] as num).toDouble(),
        days: map['days'] as int,
        tag: map['tag'] as String,
        color: map['color'] as String,
        displayOrder: map['displayOrder'] as int,
      );
    } catch (e) {
      throw FormatException(
        'Failed to parse SubscriptionPlan from remote data: $e. '
        'Raw map: $map',
      );
    }
  }

  /// Convert hex string ('#RRGGBB' or '#AARRGGBB', '#' optional) to [Color].
  ///
  /// Defensive against malformed remote-config/Firestore data: returns
  /// [_fallbackColor] instead of throwing, so a bad color value can never
  /// crash the premium screen (which would block purchases entirely).
  Color getColorFromHex() {
    try {
      var hex = color.trim().replaceFirst('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex'; // assume full opacity when alpha is omitted
      }
      if (hex.length != 8) {
        return _fallbackColor;
      }
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return _fallbackColor;
    }
  }

  SubscriptionPlan copyWith({
    String? id,
    String? name,
    double? price,
    double? oldPrice,
    int? days,
    String? tag,
    String? color,
    int? displayOrder,
  }) {
    return SubscriptionPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      oldPrice: oldPrice ?? this.oldPrice,
      days: days ?? this.days,
      tag: tag ?? this.tag,
      color: color ?? this.color,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubscriptionPlan &&
        other.id == id &&
        other.name == name &&
        other.price == price &&
        other.oldPrice == oldPrice &&
        other.days == days &&
        other.tag == tag &&
        other.color == color &&
        other.displayOrder == displayOrder;
  }

  @override
  int get hashCode =>
      Object.hash(id, name, price, oldPrice, days, tag, color, displayOrder);

  @override
  String toString() => 'SubscriptionPlan($name, ₹$price)';
}
