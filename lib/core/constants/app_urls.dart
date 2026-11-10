import 'package:flutter/foundation.dart';

/// Centralized source of truth for all web domains, legal policies, and share URLs.
///
/// Eliminates hardcoded domain strings and guarantees uniform domain routing (`vowl.in`).
@immutable
abstract class AppUrls {
  const AppUrls._();

  /// Production canonical web domain.
  static const String baseDomain = 'https://vowl.in';

  /// Legal & Policy endpoints.
  static const String privacyPolicy = '$baseDomain/privacy.html';
  static const String termsOfService = '$baseDomain/terms.html';
  static const String refundPolicy = '$baseDomain/refund.html';
  static const String contact = '$baseDomain/contact.html';

  /// Dynamic URL builders for multiplayer duels and referral invites.
  static String duel(String code) => '$baseDomain/duel/$code';
  static String invite(String code) => '$baseDomain/invite/$code';
}

