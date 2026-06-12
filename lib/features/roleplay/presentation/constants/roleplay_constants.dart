// Centralised constants for the Roleplay feature.
//
// Every magic number and string lives here so rule changes (XP, attempt
// caps, timing) touch exactly one file and propagate automatically.

// ── Game-play rules ────────────────────────────────────────────────────────

/// Maximum wrong attempts before a question is marked as finally failed
/// and the player is allowed to continue regardless.
const int kRoleplayMaxWrongAttempts = 2;

/// Default life count — overridden per-quest by [RoleplayQuest.livesAllowed].
const int kRoleplayDefaultLives = 3;

/// Lives remaining at or below which the low-life nudge and hint glow fire.
const int kRoleplayLowLifeThreshold = 2;

// ── Rewards ────────────────────────────────────────────────────────────────

/// XP awarded on level completion.
const int kRoleplayLevelCompleteXp = 10;

/// Coins awarded on level completion.
const int kRoleplayLevelCompleteCoins = 10;

// ── Infrastructure ─────────────────────────────────────────────────────────

/// Preloading begins when `level % kRoleplayPreloadTriggerModulo == 0`.
const int kRoleplayPreloadTriggerModulo = 9;

/// Badge ID granted on level completion.
const String kRoleplayBadgeId = 'roleplay_master';

/// Fallback mascot asset ID when the user profile has no mascot set.
const String kRoleplayDefaultMascotId = 'vowl_prime';

// ── UX timing ──────────────────────────────────────────────────────────────

/// Delay after a correct tap before the answer is confirmed to the player.
/// Simulates the AI character composing a response.
const Duration kRoleplayCorrectAnswerDelay = Duration(milliseconds: 800);

/// Delay after an incorrect tap before the option deselects or locks.
const Duration kRoleplayWrongAnswerDelay = Duration(milliseconds: 600);

/// Delay before the low-life voice nudge fires.
const Duration kRoleplayNudgeDelay = Duration(milliseconds: 1200);

// ── UI ─────────────────────────────────────────────────────────────────────

/// Levels that show the briefing overlay on entry.
const Set<int> kRoleplayBriefingLevels = {1, 100};

/// Maximum width of the content column on large screens / tablets.
const double kRoleplayMaxContentWidth = 680;
