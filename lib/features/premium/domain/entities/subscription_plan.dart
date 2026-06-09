import 'package:flutter/material.dart';

class SubscriptionPlan {
  final String id;
  final String name;
  final double price;
  final double oldPrice;
  final int days;
  final String tag;
  final String color; // Store as hex string for serialization
  final int displayOrder;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.oldPrice,
    required this.days,
    required this.tag,
    required this.color,
    required this.displayOrder,
  });

  // Convert to Firebase-friendly map
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

  // Create from Firebase map
  factory SubscriptionPlan.fromMap(Map<String, dynamic> map) {
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
  }

  // Convert hex string back to Color
  Color getColorFromHex() {
    return Color(int.parse(color.replaceFirst('#', '0xff')));
  }

  @override
  String toString() => 'SubscriptionPlan($name, ₹$price)';
}
