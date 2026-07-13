import 'package:flutter/material.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Single source of truth for all Accent game-tuning constants.
///
/// Keeping these here means a designer or PM can change game balance
/// (lives, XP, quest count) without touching business logic files.
abstract final class AccentGameConstants {
  AccentGameConstants._();

  // ── Session config ────────────────────────────────────────────────────────
  /// How many quests are loaded per level session.
  static const int questLimit = 3;

  /// Starting (and maximum) lives a player has per session.
  static const int maxLives = 3;

  /// Hard ceiling on the quests list after Mastery Loop appends.
  /// Worst case: every quest is failed once → questLimit + (questLimit - 1)
  /// additional retries, bounded by maxLives exhaustion.
  static const int maxQuestsHardCap = questLimit * 2;

  // ── Rewards ───────────────────────────────────────────────────────────────
  /// XP awarded on successful level completion.
  static const int rewardXp = 10;

  /// Coins awarded on successful level completion.
  static const int rewardCoins = 10;

  // ── Badge identifiers ─────────────────────────────────────────────────────
  static const String accentMasterBadge = 'accent_master';

  // ── TTS nudge ─────────────────────────────────────────────────────────────
  /// Delay (ms) before TTS fires after a life-drop sound effect.
  static const int nudgeDelayMs = 1200;

  /// Message spoken when the player drops to their last life.
  static String nudgeMessage(BuildContext context) =>
      context.tr('games.kids_nudge', fallback: 'Let\'s go!');

  // ── Briefing ──────────────────────────────────────────────────────────────
  /// Levels that auto-show the quest briefing overlay on entry.
  static const Set<int> briefingAutoShowLevels = {1, 100};
}
