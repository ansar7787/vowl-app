import 'package:flutter/material.dart';

/// Vowl primitive color palette — raw design tokens.
///
/// This is the **single source of truth** for every raw color value used in
/// the Vowl design system (excluding category colors, which live in
/// [CategoryColors]).
///
/// Widgets should NOT reference these directly. Instead, consume
/// [AppColorTokens] via `Theme.of(context).extension<AppColorTokens>()`.
///
/// Only the theme layer ([AppTheme]) and [AppColorTokens] should import this
/// file.
///
/// ### Naming Convention
/// `{hue}{shade}` — e.g. `indigo500`, `slate900`, `emerald500`.
/// Shades follow the Tailwind CSS scale (50–950) for familiarity.
///
/// ### LCD Robustness
/// Every primary color has been tested for visibility on low-brightness LCD
/// panels. Neon / hyper-saturated values (e.g. Material `greenAccent`,
/// `redAccent`) are intentionally excluded.
class AppColors {
  AppColors._();

  // ─────────────────────────────────────────────────────────────────────────
  // Indigo — Brand Primary (Trust + Focus)
  // ─────────────────────────────────────────────────────────────────────────

  /// Indigo 500 — primary brand, CTAs, active states.
  static const Color indigo500 = Color(0xFF6366F1);

  /// Indigo 400 — dark-mode primary accent.
  static const Color indigo400 = Color(0xFF818CF8);

  /// Indigo 600 — pressed / darker variant.
  static const Color indigo600 = Color(0xFF4F46E5);

  /// Indigo 50 — light-mode primary container tint.
  static const Color indigo50 = Color(0xFFEEF2FF);

  /// Indigo 950 — dark-mode primary container.
  static const Color indigo950 = Color(0xFF1E1B4B);

  /// Violet 500 — premium / elevated brand accent.
  static const Color violet500 = Color(0xFF8B5CF6);

  // ─────────────────────────────────────────────────────────────────────────
  // Emerald — Success / Correct / Progress
  // ─────────────────────────────────────────────────────────────────────────

  /// Emerald 600 — secondary brand, success.
  static const Color emerald600 = Color(0xFF059669);

  /// Emerald 500 — success indicators, correct answer.
  static const Color emerald500 = Color(0xFF10B981);

  /// Emerald 400 — success gradient light end.
  static const Color emerald400 = Color(0xFF34D399);

  /// Teal 400 — success gradient start (game feedback).
  static const Color teal400 = Color(0xFF2DD4BF);

  /// Emerald 950 — success container (dark mode).
  static const Color emerald950 = Color(0xFF064E3B);

  /// Emerald 50 — success container (light mode).
  static const Color emerald50 = Color(0xFFECFDF5);

  // ─────────────────────────────────────────────────────────────────────────
  // Amber — Rewards / Stars / Economy
  // ─────────────────────────────────────────────────────────────────────────

  /// Amber 600 — tertiary brand accent.
  static const Color amber600 = Color(0xFFD97706);

  /// Amber 500 — rewards, coins, star accents.
  static const Color amber500 = Color(0xFFF59E0B);

  /// Amber 400 — timer yellow, lighter reward tint.
  static const Color amber400 = Color(0xFFFBBF24);

  /// Amber 200 — reward container (light mode).
  static const Color amber200 = Color(0xFFFDE68A);

  /// Amber 100 — reward container very light.
  static const Color amber100 = Color(0xFFFEF3C7);

  /// Amber 900 — reward container (dark mode).
  static const Color amber900 = Color(0xFF78350F);

  /// Gold — achievement stars, victory.
  static const Color gold = Color(0xFFFFD700);

  /// Orange 500 — gradient pair for gold CTA.
  static const Color orange500 = Color(0xFFFFA500);

  // ─────────────────────────────────────────────────────────────────────────
  // Red / Rose — Error / Incorrect / Fail
  // ─────────────────────────────────────────────────────────────────────────

  /// Red 500 — error, destructive, incorrect.
  static const Color red500 = Color(0xFFEF4444);

  /// Rose 500 — fail gradient light end.
  static const Color rose500 = Color(0xFFF43F5E);

  /// Rose 700 — fail gradient dark end, fail shadow.
  static const Color rose700 = Color(0xFFE11D48);

  /// Red 900 — error container (dark mode).
  static const Color red900 = Color(0xFF7F1D1D);

  /// Red 50 — error container (light mode).
  static const Color red50 = Color(0xFFFEF2F2);

  // ─────────────────────────────────────────────────────────────────────────
  // Blue — Information / Tips
  // ─────────────────────────────────────────────────────────────────────────

  /// Blue 500 — information, tips, secondary actions.
  static const Color blue500 = Color(0xFF3B82F6);

  /// Blue 300 — light info accent.
  static const Color blue300 = Color(0xFF93C5FD);

  /// Blue 900 — info container (dark mode).
  static const Color blue900 = Color(0xFF1E3A8A);

  /// Blue 50 — info container (light mode).
  static const Color blue50 = Color(0xFFEFF6FF);

  // ─────────────────────────────────────────────────────────────────────────
  // Warning (Amber-toned, separate from reward semantics)
  // ─────────────────────────────────────────────────────────────────────────

  /// Warning accent — same hue as reward but used for caution contexts.
  /// Semantically distinct from [amber500] via token layer.
  static const Color warningAmber = Color(0xFFF59E0B);

  /// Warning container (light mode).
  static const Color warningLight = Color(0xFFFFFBEB);

  // ─────────────────────────────────────────────────────────────────────────
  // Slate — Neutral System (backgrounds, text, borders, surfaces)
  // ─────────────────────────────────────────────────────────────────────────
  // NOTE: The project uses Tailwind Slate, NOT Material Grey. All neutral
  // colors should come from this scale. `Colors.grey` should not be used.

  /// Slate 950 — deepest dark surface.
  static const Color slate950 = Color(0xFF020617);

  /// Slate 900 — dark scaffold, primary dark text on light.
  static const Color slate900 = Color(0xFF0F172A);

  /// Slate 800 — dark card surface.
  static const Color slate800 = Color(0xFF1E293B);

  /// Slate 700 — dark borders, strong muted text.
  static const Color slate700 = Color(0xFF334155);

  /// Slate 600 — secondary dark text.
  static const Color slate600 = Color(0xFF475569);

  /// Slate 500 — muted text, disabled, placeholder.
  static const Color slate500 = Color(0xFF64748B);

  /// Slate 400 — subtle text, light borders.
  static const Color slate400 = Color(0xFF94A3B8);

  /// Slate 300 — dividers, faint borders.
  static const Color slate300 = Color(0xFFCBD5E1);

  /// Slate 200 — light borders.
  static const Color slate200 = Color(0xFFE2E8F0);

  /// Slate 100 — light surface variant.
  static const Color slate100 = Color(0xFFF1F5F9);

  /// Slate 50 — light scaffold background.
  static const Color slate50 = Color(0xFFF8FAFC);

  // ─────────────────────────────────────────────────────────────────────────
  // Deep Dark — Midnight / AMOLED surfaces
  // ─────────────────────────────────────────────────────────────────────────

  /// Near-black card base for midnight mode.
  static const Color midnightSurface = Color(0xFF0B0F19);

  /// Deep dark background for immersive game UIs.
  static const Color deepDark = Color(0xFF0F0F1B);

  /// Ultra-deep dark for midnight nested surfaces.
  static const Color ultraDeep = Color(0xFF07070F);

  // ─────────────────────────────────────────────────────────────────────────
  // Functional — Pure values
  // ─────────────────────────────────────────────────────────────────────────

  /// Pure white.
  static const Color white = Color(0xFFFFFFFF);

  /// Pure black.
  static const Color black = Color(0xFF000000);

  // ─────────────────────────────────────────────────────────────────────────
  // Game Feedback — LCD-robust correct/incorrect
  // ─────────────────────────────────────────────────────────────────────────
  // These REPLACE the neon `Colors.greenAccent` (#69F0AE) and
  // `Colors.redAccent` (#FF5252) which fail WCAG AA on white backgrounds
  // and wash out on cheap LCD panels.

  /// Game correct — warm emerald, visible on LCD, deuteranopia-safe
  /// when paired with shape/icon indicators.
  static const Color gameCorrect = Color(0xFF10B981);

  /// Game incorrect — controlled red, not neon, sufficient contrast.
  static const Color gameIncorrect = Color(0xFFEF4444);

  // ─────────────────────────────────────────────────────────────────────────
  // Teal — Accent / Secondary feature
  // ─────────────────────────────────────────────────────────────────────────

  /// Teal 500 — secondary accent for certain features.
  static const Color teal500 = Color(0xFF14B8A6);

  /// Cyan 400 — platinum badge, light teal.
  static const Color cyan400 = Color(0xFF22D3EE);

  // ─────────────────────────────────────────────────────────────────────────
  // Bronze — Badge system
  // ─────────────────────────────────────────────────────────────────────────

  /// Bronze — badge tier color.
  static const Color bronze = Color(0xFFCD7F32);
}
