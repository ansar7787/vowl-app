import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/utils/app_router.dart';

void main() {
  group('AppRouter.normalizeDeepLink', () {
    test('normalizes custom scheme vowl://invite/CODE', () {
      final uri = Uri.parse('vowl://invite/VOWL-VIP-100');
      expect(AppRouter.normalizeDeepLink(uri), '/invite/VOWL-VIP-100');
    });

    test('normalizes custom scheme vowl://invite?code=CODE', () {
      final uri = Uri.parse('vowl://invite?code=SUMMER2026');
      expect(AppRouter.normalizeDeepLink(uri), '/invite/SUMMER2026');
    });

    test('normalizes custom scheme with authority vowl://vowl.in/invite/CODE', () {
      final uri = Uri.parse('vowl://vowl.in/invite/GOLDENPASS');
      expect(AppRouter.normalizeDeepLink(uri), '/invite/GOLDENPASS');
    });

    test('normalizes custom scheme with query vowl://vowl.in/invite?code=CODE', () {
      final uri = Uri.parse('vowl://vowl.in/invite?code=BONUS50');
      expect(AppRouter.normalizeDeepLink(uri), '/invite/BONUS50');
    });

    test('normalizes 3-slash custom scheme vowl:///invite/CODE', () {
      final uri = Uri.parse('vowl:///invite/SLASHCODE');
      expect(AppRouter.normalizeDeepLink(uri), '/invite/SLASHCODE');
    });

    test('normalizes HTTPS invite URL https://vowl.in/invite/CODE', () {
      final uri = Uri.parse('https://vowl.in/invite/HTTPSCODE');
      expect(AppRouter.normalizeDeepLink(uri), '/invite/HTTPSCODE');
    });

    test('normalizes HTTPS invite with query param https://vowl.in/invite?code=CODE', () {
      final uri = Uri.parse('https://vowl.in/invite?code=QUERYPASS');
      expect(AppRouter.normalizeDeepLink(uri), '/invite/QUERYPASS');
    });

    test('normalizes custom scheme duel vowl://duel/ROOM777', () {
      final uri = Uri.parse('vowl://duel/ROOM777');
      expect(AppRouter.normalizeDeepLink(uri), '/duel/ROOM777');
    });

    test('normalizes custom scheme duel with query param vowl://duel?roomCode=ROOM888', () {
      final uri = Uri.parse('vowl://duel?roomCode=ROOM888');
      expect(AppRouter.normalizeDeepLink(uri), '/duel/ROOM888');
    });

    test('normalizes custom scheme duel with authority vowl://vowl.in/duel/ROOM999', () {
      final uri = Uri.parse('vowl://vowl.in/duel/ROOM999');
      expect(AppRouter.normalizeDeepLink(uri), '/duel/ROOM999');
    });

    test('normalizes HTTPS duel URL https://vowl.in/duel/ROOM123', () {
      final uri = Uri.parse('https://vowl.in/duel/ROOM123');
      expect(AppRouter.normalizeDeepLink(uri), '/duel/ROOM123');
    });

    test('normalizes custom scheme verify-email vowl://verify-email and vowl://vowl.in/verify-email', () {
      expect(AppRouter.normalizeDeepLink(Uri.parse('vowl://verify-email')), '/verify-email');
      expect(AppRouter.normalizeDeepLink(Uri.parse('vowl://vowl.in/verify-email')), '/verify-email');
    });

    test('normalizes custom scheme login vowl://login and vowl://vowl.in/login', () {
      expect(AppRouter.normalizeDeepLink(Uri.parse('vowl://login')), '/login');
      expect(AppRouter.normalizeDeepLink(Uri.parse('vowl://vowl.in/login')), '/login');
    });

    test('normalizes custom scheme referral hub vowl://referral', () {
      expect(AppRouter.normalizeDeepLink(Uri.parse('vowl://referral')), '/referral');
    });

    test('returns null for non-deep-link paths (internal navigation)', () {
      expect(AppRouter.normalizeDeepLink(Uri.parse('/home')), isNull);
      expect(AppRouter.normalizeDeepLink(Uri.parse('/profile')), isNull);
    });
  });
}
