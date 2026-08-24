# 🪙 VOWL Coin Ledger — Complete Audit & Task Tracker

> **Goal:** Every main-coin (non-kids) transaction that earns or spends coins MUST write a `coinHistory` entry with a **stable `titleKey`** and the **exact amount** — so the Coin Ledger screen always shows the truth.

---

## 📊 Full Transaction Map

### ✅ Already Logging to coinHistory (9 operations)

| # | Operation | File | titleKey | Status |
|---|-----------|------|----------|--------|
| 1 | **Quest Reward** (level complete) | `gamification_repository_impl.dart:330` | `coin_history.quest_reward` | ✅ OK |
| 2 | **Streak Repair** (coin spend) | `gamification_repository_impl.dart:475` | `coin_history.repaired_streak` | ✅ OK |
| 3 | **Streak Freeze Purchase** | `gamification_repository_impl.dart:563` | `coin_history.purchased_streak_freeze` | ✅ OK |
| 4 | **Double XP Purchase** | `gamification_repository_impl.dart:607` | `coin_history.purchased_double_xp` | ✅ OK |
| 5 | **Permanent XP Boost Purchase** | `gamification_repository_impl.dart:661` | `coin_history.purchased_permanent_xp_boost` | ✅ OK |
| 6 | **Streak Milestone Reward** | `gamification_repository_impl.dart:842` | `coin_history.streak_milestone_reward` | ✅ OK |
| 7 | **Level Milestone Reward** | `gamification_repository_impl.dart:903` | `coin_history.level_milestone_reward` | ✅ OK |
| 8 | **Hint Pack Purchase** | `shop_repository_impl.dart:319` | `coin_history.purchased_hint_pack` | ✅ OK |
| 9 | **Generic Coin Add** (via updateUserCoins) | `shop_repository_impl.dart:76` | *(caller-supplied)* | ✅ OK |

### ❌ MISSING coinHistory (7 operations) — **Needs Fix**

| # | Operation | File:Line | Coins | Direction | Priority |
|---|-----------|-----------|-------|-----------|----------|
| A | **Ad Triple Reward** | `economy_bloc.dart:338` | +20 (coins×2) | Earn | ✅ DONE |
| B | **Daily Gift Claim** | `shop_repository_impl.dart:149` | +var | Earn | ✅ DONE |
| C | **Daily Chest Claim** | `shop_repository_impl.dart:201` | +var | Earn | ✅ DONE |
| D | **VIP Daily Gift** | `user_repository_impl.dart:170` | +const | Earn | ✅ DONE |
| E | **Buy Vowl Mascot** | `shop_repository_impl.dart:537` | −cost | Spend | ✅ DONE |
| F | **Buy Vowl Accessory** | `shop_repository_impl.dart:587` | −cost | Spend | ✅ DONE |
| G | **Purchase Golden Key** (main coins) | `gamification_repository_impl.dart:768` | −cost | Spend | ✅ DONE |

### 🔧 Already Fixed (Previous Session)

| # | Operation | File | Fix Applied |
|---|-----------|------|-------------|
| H | **Ad Reward (standalone)** | `ad_reward_card.dart:55` | `'Watched Rewarded Ad'` → `'coin_history.ad_reward'` |
| I | **Ad Reward (profile)** | `rewarded_ad_card.dart:58` | `'Watched Rewarded Ad'` → `'coin_history.ad_reward'` |

### ⚠️ Raw English Titles — **Needs Stable Key**

| # | Operation | File:Line | Current Title | Proposed Key |
|---|-----------|-----------|---------------|--------------|
| J | **Speaking Bonus** (Accent) | `accent_bloc.dart:392` | `'Speaking Bonus'` | ✅ DONE (`'coin_history.speaking_bonus'`) |
| K | **Speaking Bonus** (Roleplay) | `roleplay_bloc.dart:366` | `'Speaking Bonus'` | ✅ DONE (`'coin_history.speaking_bonus'`) |

### 🐛 Multiplier Clarification

> **"Triple" math is correct:** The base `coins` (e.g. 10) is already awarded by `updateUserRewards` during level completion. The triple-up ad only needs to add the **bonus** portion: `coins * 2 = 20`, making the total `10 + 20 = 30`. The arithmetic is correct; only the **ledger logging** was missing.

---

## 📋 Task Tracker

| Task | File(s) | Status | Notes |
|------|---------|--------|-------|
| **T1.** Fix `_onTripleUp` to use `updateUserCoins` with `coin_history.ad_triple_reward` | `economy_bloc.dart` | ✅ DONE | Coins now recorded in ledger |
| **T2.** Fix coin screen to read `titleKey` instead of `title` | `quest_coins_screen.dart` | ✅ DONE | Falls back to `title` for legacy |
| **T3.** Add `_localizeTransactionKey()` to display human-readable titles | `quest_coins_screen.dart` | ✅ DONE | 14 keys mapped |
| **T4.** Fix ad_reward_card raw English → stable key | `ad_reward_card.dart` | ✅ DONE | `coin_history.ad_reward` |
| **T5.** Fix rewarded_ad_card raw English → stable key | `rewarded_ad_card.dart` | ✅ DONE | `coin_history.ad_reward` |
| **T6.** Add coinHistory to `claimDailyGift` | `shop_repository_impl.dart` | ✅ DONE | Key: `coin_history.daily_gift` |
| **T7.** Add coinHistory to `claimDailyChest` | `shop_repository_impl.dart` | ✅ DONE | Key: `coin_history.daily_chest` |
| **T8.** Add coinHistory to `claimVipGift` | `user_repository_impl.dart` | ✅ DONE | Key: `coin_history.vip_gift` |
| **T9.** Add coinHistory to `buyVowlMascot` | `shop_repository_impl.dart` | ✅ DONE | Key: `coin_history.purchased_mascot` |
| **T10.** Add coinHistory to `buyVowlAccessory` | `shop_repository_impl.dart` | ✅ DONE | Key: `coin_history.purchased_accessory` |
| **T11.** Add coinHistory to `purchaseGoldenKey` (main coins only) | `gamification_repository_impl.dart` | ✅ DONE | Key: `coin_history.purchased_golden_key` |
| **T12.** Fix speaking bonus raw English → stable key | `accent_bloc.dart`, `roleplay_bloc.dart` | ✅ DONE | Key: `coin_history.speaking_bonus` |
| **T13.** Add new keys to `_localizeTransactionKey` in coin screen | `quest_coins_screen.dart` | ✅ DONE | Add T6-T12 display strings |
| **T14.** Run `dart analyze` — zero warnings | All files | ✅ DONE | Final verification |

---

## 🎯 Expected Coin Ledger After All Fixes

Every possible coin transaction will show a **clean, short, recognizable label**:

| titleKey | Display Text | Direction |
|----------|-------------|-----------|
| `coin_history.quest_reward` | Quest Reward – vocabulary | +🟢 |
| `coin_history.ad_triple_reward` | Ad Triple Reward 🎬 | +🟢 |
| `coin_history.ad_reward` | Ad Reward 🎬 | +🟢 |
| `coin_history.daily_gift` | Daily Gift 🎁 | +🟢 |
| `coin_history.daily_chest` | Daily Chest 🎁 | +🟢 |
| `coin_history.vip_gift` | VIP Gift ⭐ | +🟢 |
| `coin_history.speaking_bonus` | Speaking Bonus 🎤 | +🟢 |
| `coin_history.earned_coins` | Earned Coins | +🟢 |
| `coin_history.streak_milestone_reward` | Streak Milestone (7🔥) 🏆 | +🟢 |
| `coin_history.level_milestone_reward` | Level Milestone (Lv.10) 🏆 | +🟢 |
| `coin_history.purchased_hint_pack` | Purchased Hint Pack | −🔴 |
| `coin_history.repaired_streak` | Repaired Streak 🔥 | −🔴 |
| `coin_history.purchased_streak_freeze` | Streak Freeze ❄️ | −🔴 |
| `coin_history.purchased_double_xp` | Double XP Boost ⚡ | −🔴 |
| `coin_history.purchased_permanent_xp_boost` | Permanent XP Boost 🚀 | −🔴 |
| `coin_history.purchased_mascot` | Purchased Mascot 🦉 | −🔴 |
| `coin_history.purchased_accessory` | Purchased Accessory ✨ | −🔴 |
| `coin_history.purchased_golden_key` | Purchased Golden Key 🔑 | −🔴 |

---

## 🔎 Final Deep Dive Audit (Added Aug 5)

A secondary, exhaustive deep dive of the codebase uncovered three final edge cases that were bypassing the ledger:

1. **Backend Coin Pack Purchases (Cloud Functions):**
   - **Issue:** The `verifyCoinPurchase` cloud function in `functions/index.js` was directly incrementing user balances upon successful Razorpay payments but omitting the `coinHistory` array update.
   - **Fix:** Refactored the transaction inside the cloud function to unshift a `coin_history.purchased_coin_pack` object into the `coinHistory` array (capped at 20 entries) before committing the write.

2. **EconomyBloc Bonus Rewards (`_onAddBonusRewards`):**
   - **Issue:** Similar to the old `_onTripleUp` bug, `_onAddBonusRewards` was using a full-document `updateUser` call instead of the atomic `updateUserCoins` path, bypassing the ledger.
   - **Fix:** Refactored the method to dispatch `updateUserCoins` with the `coin_history.earned_coins` key, ensuring consistency.

3. **Missing Localization (`quest_coins_screen.dart`):**
   - **Fix:** Added mapping for `coin_history.purchased_coin_pack` to resolve as `"Purchased Coin Pack 💎"`.

**Status:** ALL known coin balance mutating paths (Client & Backend) are now definitively confirmed to be perfectly synced with the transaction ledger. ✅
