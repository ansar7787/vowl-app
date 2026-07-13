import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';

/// Domain contract defining gamification progress, XP, and achievement operations.
///
/// All write operations execute as Firestore transactions to guarantee atomicity
/// and eliminate concurrency race conditions (e.g., simultaneous level
/// completions on multiple devices).
abstract class GamificationRepository {
  /// Records a game-level completion, updating XP, coins, completed levels,
  /// unlocked levels, daily XP history, and the recent-activity feed atomically.
  ///
  /// - Applies a 50 % XP reduction for replayed levels.
  /// - Respects permanent XP boost and active Double-XP power-up multipliers.
  /// - Routes coin rewards to [kidsCoins] for Kids Zone game types.
  /// - Doubles coin rewards for premium users or users at level ≥ 100.
  Future<Either<Failure, void>> updateUserRewards({
    required String gameType,
    required int level,
    required int xpIncrease,
    required int coinIncrease,
    bool isDoubleReward = false,
    bool isVaultReward = false,
    int? starsEarned,
    int? addMagicStars,
    int? claimChestTier,
  });

  /// Advances the unlocked level for [categoryId] to [newLevel] if [newLevel]
  /// exceeds the currently stored value (monotonically increasing only).
  Future<Either<Failure, void>> updateUnlockedLevel(
    String categoryId,
    int newLevel,
  );

  /// Adjusts [categoryStats] for [categoryId] by ±[kCategoryStatStep] based on
  /// [isCorrect], clamped to [[kCategoryStatMin], [kCategoryStatMax]].
  Future<Either<Failure, void>> updateCategoryStats(
    String categoryId,
    bool isCorrect,
  );

  /// Appends [badgeId] to the user's earned badges list (idempotent via
  /// Firestore [FieldValue.arrayUnion]).
  Future<Either<Failure, void>> awardBadge(String badgeId);

  /// Deducts [cost] from the user's coin balance and increments [currentStreak]
  /// to repair a broken streak.
  Future<Either<Failure, void>> repairStreak(int cost);

  /// Repairs a broken streak with no coin cost (e.g. the "watch an ad to
  /// repair" flow) — same streak-restoration formula as [repairStreak], minus
  /// the balance check and deduction. Still runs inside a Firestore
  /// transaction: the streak value itself must be read consistently to avoid
  /// a lost update if this fires from two sessions at once.
  Future<Either<Failure, void>> repairStreakFree();

  /// Deducts [cost] coins and grants one streak-freeze buffer item.
  Future<Either<Failure, void>> purchaseStreakFreeze(int cost);

  /// Deducts [cost] coins and activates the 2× XP power-up for 24 hours.
  Future<Either<Failure, void>> activateDoubleXP(int cost);

  /// Deducts [cost] coins and permanently enables [hasPermanentXPBoost].
  /// Silently succeeds (no charge) if already enabled. Runs atomically
  /// inside a Firestore transaction.
  Future<Either<Failure, void>> purchasePermanentXPBoost(int cost);

  /// Deducts [cost] Golden Keys and explicitly increments the unlocked level
  /// for the specified [gameType] by 3. Used for Toll Gate monetization.
  ///
  /// [isKidsMode] is accepted for API symmetry with [purchaseGoldenKey] but is
  /// not used to select a currency here: Golden Keys are a single universal
  /// currency shared by both Kids Zone and standard content (see
  /// [purchaseGoldenKey], which always credits the same balance regardless of
  /// [isKidsMode]), so there is no separate kids-mode key balance to deduct
  /// from.
  Future<Either<Failure, void>> purchaseLevelUnlock({
    required String gameType,
    required int cost,
    bool isKidsMode = false,
  });

  /// Deducts [cost] from [kidsCoins] (when [isKidsMode] is true) or [coins]
  /// (otherwise) and grants one Golden Key. Golden Keys themselves are a
  /// single universal balance regardless of [isKidsMode].
  Future<Either<Failure, void>> purchaseGoldenKey({
    required int cost,
    required bool isKidsMode,
  });

  /// Credits [amount] Golden Keys with no balance check (a pure grant, e.g.
  /// from a reward or promotion) — atomic via `FieldValue.increment`.
  Future<Either<Failure, void>> addGoldenKey({required int amount});

  /// Claims the coin reward for reaching a [milestone]-day streak.
  ///
  /// The reward amount is **not** accepted from the caller — it is looked up
  /// server-side from `UserGameConstants.kStreakMilestoneRewards`, and the
  /// claim is rejected if [milestone] isn't a recognized threshold or has
  /// already been recorded in [claimedStreakMilestones]. Both checks run
  /// inside the same Firestore transaction that credits the reward, so the
  /// same milestone can never be paid out twice, and a caller can never
  /// request an arbitrary payout — closing a duplicate-claim / arbitrary-
  /// reward vulnerability that existed in the previous client-side
  /// implementation (`ProgressionBloc._onClaimStreakMilestone`, which
  /// trusted a `reward` value passed straight through from the event and
  /// never checked whether the milestone was already claimed).
  Future<Either<Failure, void>> claimStreakMilestone({required int milestone});

  /// Claims the coin reward for reaching a level [milestone].
  ///
  /// Unlike [claimStreakMilestone], there is currently no server-side
  /// level-milestone reward table available to this feature slice (none was
  /// present in any of the reviewed files), so [reward] is still accepted
  /// from the caller — **this method cannot fully close the
  /// arbitrary-reward part of the same vulnerability class for level
  /// milestones**. What it does close: the transaction rejects the claim if
  /// [milestone] is already present in [claimedLevelMilestones] (no more
  /// duplicate claims), and rejects it if [milestone] exceeds the user's own
  /// current [UserEntity.level] (computed server-side from [totalExp], not
  /// caller-supplied — so a claim can't reference a level the user hasn't
  /// actually reached). Add a `kLevelMilestoneRewards` table to
  /// `UserGameConstants` (mirroring `kStreakMilestoneRewards`) and switch
  /// this method to look up [reward] the same way [claimStreakMilestone]
  /// does, the moment the intended level-milestone reward schedule is
  /// decided.
  Future<Either<Failure, void>> claimLevelMilestone({
    required int milestone,
    required int reward,
  });
}
