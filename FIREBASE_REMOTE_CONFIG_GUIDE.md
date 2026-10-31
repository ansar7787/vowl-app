# Vowl — Firebase Remote Config Master Guide & Reference

This guide documents every Firebase Remote Config parameter in the Vowl codebase, how each feature works step-by-step, its default values, and how you can manage them in the Firebase Console without releasing a new app update.

---

## 1. Executive Summary & Architecture

Vowl uses **Firebase Remote Config** to remotely control app updates, monetization (ads), virtual currency limits, and game tuning in real time.

* **Offline-Resilient**: The app defines safe, production-grade local fallback defaults inside [`FirebaseRemoteConfigService`](lib/core/utils/remote_config_service.dart). If a user opens the app offline, in airplane mode, or with slow internet, **the app will never crash or hang**—it seamlessly serves local defaults.
* **Smart Caching**:
  * **Production mode**: Caches parameters for **1 hour** (`minimumFetchInterval = Duration(hours: 1)`) to preserve user battery and minimize Firebase network reads.
  * **Debug mode**: Instant live reload (`Duration.zero`) so developers can test parameter changes immediately.
* **Initialization Entrypoint**: Executed in [`main.dart`](lib/main.dart) during the startup boot sequence via `sl<RemoteConfigService>().init()`.

---

## 2. Master Remote Config Parameters Table

| Key in Firebase Console | Data Type | Default Value | Feature Controlled | Active Status |
| :--- | :--- | :--- | :--- | :--- |
| `min_app_version` | **String** | `"1.0.0"` | **Emergency Force-Update Gate** | 🟢 **Active** |
| `latest_app_version` | **String** | `"1.0.0"` | **Flexible In-App Update Prompt** | 🟢 **Active** |
| `update_release_notes` | **String** | `""` *(empty)* | **Custom "What's New" Release Notes** | 🟢 **Active** |
| `update_store_url` | **String** | `""` *(empty)* | **Custom Store URL Override** | 🟢 **Active** |
| `ad_frequency_multiplier` | **Number (double)** | `1.0` | **Ad Frequency & Pacing Controller** | 🟢 **Active** |
| `interstitial_cooldown_minutes` | **Number (int)** | `3` | **Interstitial Ad Cooldown Timer** | 🟢 **Active** |
| `daily_reward_limit` | **Number (int)** | `5` | **Max Daily Rewarded Video Claims** | 🟢 **Active** |
| `triple_rewards_enabled` | **Boolean** | `true` | **VIP 3X Reward Multiplier Switch** | 🟢 **Active** |
| `coins_per_victory` | **Number (int)** | `10` | **Base Quest Coin Reward Tuning** | 🟡 **Configured** |
| `kids_coins_per_victory` | **Number (int)** | `5` | **Kids Zone Base Coin Reward** | 🟡 **Configured** |
| `level_difficulty_modifier` | **Number (double)** | `1.0` | **Global Quiz Engine Difficulty** | 🟡 **Configured** |
| `hint_coin_cost` | **Number (int)** | `15` | **Hint Purchase Coin Price** | 🟡 **Configured** |

---

## 3. Deep Dive for Each Feature (Step-by-Step)

### Feature 1: Force Update Gate (`min_app_version`)
* **Parameter Key**: `min_app_version`
* **Type**: `String`
* **Default**: `"1.0.0"`
* **What it does**: 
  * If a critical security flaw or breaking database schema change occurs in older builds, you can force all older users to update before they can use the app.
  * If the user's installed version is **strictly lower** than `min_app_version`, the app displays a blocking **"Update Required"** modal dialog.
  * **User Experience**: The back button is completely blocked (`PopScope(canPop: false)`), tapping outside the dialog does nothing, and there is no "Maybe Later" button. The user must tap **"Update Now"** to open the Google Play Store.
* **How to use it**:
  * Set `min_app_version` to your latest stable release (e.g. `"1.0.1"`). Any user on `1.0.0` will be blocked until they update.

---

### Feature 2: Flexible Update Announcement (`latest_app_version`)
* **Parameter Key**: `latest_app_version`
* **Type**: `String`
* **Default**: `"1.0.0"`
* **What it does**:
  * Displays a friendly **"New Version Available!"** popup when a newer build is released.
  * Features two buttons: **"Update Now"** (opens Play Store) and **"Maybe Later"**.
  * **Smart 24-Hour Cooldown**: If the user taps "Maybe Later", the app saves their choice in local `SharedPreferences` and will **suppress the prompt for 24 hours** so they are not annoyed on every launch.
* **How to use it**:
  * Whenever Google Play approves a new release (e.g. `1.0.1`), update `latest_app_version` to `"1.0.1"`.

---

### Feature 3: Custom "What's New" Notes (`update_release_notes`)
* **Parameter Key**: `update_release_notes`
* **Type**: `String`
* **Default**: `""` *(empty)*
* **What it does**:
  * Custom bullet points displayed in the update dialog's *"What's New"* box.
  * **Zero-Crash Evergreen Fallback**: If you leave this parameter empty in Firebase Console, Vowl automatically displays universal production release notes:
    * *• Performance enhancements & smoother animations*
    * *• Stability upgrades & user experience polish*
    * *• Bug fixes to keep your learning seamless*
* **Example Value in Firebase**:
  ```text
  • Real-time leaderboard updates & instant rank sync
  • Google Sign-In identity & avatar polish
  • Ultra-smooth 120Hz display optimizations
  ```

---

### Feature 4: Custom Store URL Override (`update_store_url`)
* **Parameter Key**: `update_store_url`
* **Type**: `String`
* **Default**: `""` *(empty)*
* **What it does**:
  * Overrides the store destination when the user taps "Update Now".
  * If left empty `""`, Vowl automatically launches the native Android Play Store scheme:
    `market://details?id=com.vowl.app`
    with an automatic web fallback to `https://play.google.com/store/apps/details?id=com.vowl.app`.

---

### Feature 5: Interstitial Ad Cooldown (`interstitial_cooldown_minutes`)
* **Parameter Key**: `interstitial_cooldown_minutes`
* **Type**: `Number (int)`
* **Default**: `3` *(minutes)*
* **Where used**: [`AdService.interstitialCooldownMinutes`](lib/core/utils/ad_service.dart)
* **What it does**:
  * Prevents ad fatigue and bad Play Store reviews. Even if an energetic player beats 5 levels in 2 minutes, Vowl guarantees that a full-screen interstitial ad will **never show more often than once every 3 minutes**.
* **How to tweak**:
  * If user retention is low: Increase to `4` or `5` minutes for a less intrusive experience.
  * During peak events: Decrease to `2` minutes.

---

### Feature 6: Ad Frequency Multiplier (`ad_frequency_multiplier`)
* **Parameter Key**: `ad_frequency_multiplier`
* **Type**: `Number (double)`
* **Default**: `1.0`
* **Where used**: [`AdService.adFrequencyMultiplier`](lib/core/utils/ad_service.dart)
* **What it does**:
  * A master volume knob for all interstitial ad pacing:
    * `0.0` = **Kill Switch**: Disables all interstitial ads instantly across all users worldwide (ideal for emergency bug mitigation or special holiday promotions).
    * `0.5` = Halves the frequency of ads.
    * `1.0` = Standard balanced pacing.

---

### Feature 7: Daily Rewarded Video Limit (`daily_reward_limit`)
* **Parameter Key**: `daily_reward_limit`
* **Type**: `Number (int)`
* **Default**: `5`
* **Where used**: [`RewardLimitService.dailyRewardLimit`](lib/core/utils/reward_limit_service.dart)
* **What it does**:
  * Sets the maximum number of rewarded ads a player can watch each day to claim free coins, energy, or mystery chests.
  * Protects against ad fraud while keeping the game's economy balanced.
* **How to tweak**:
  * Weekend Special: Raise to `8` or `10` so players can earn extra rewards on Saturdays and Sundays.

---

### Feature 8: VIP 3X Multiplier Switch (`triple_rewards_enabled`)
* **Parameter Key**: `triple_rewards_enabled`
* **Type**: `Boolean`
* **Default**: `true`
* **What it does**:
  * Global switch controlling whether VIP/Pro subscribers receive triple (3X) coin and XP rewards.

---

### Features 9 - 12: Game Economy & Tuning
* `coins_per_victory` *(default: 10)*: Base coins granted when winning a quest.
* `kids_coins_per_victory` *(default: 5)*: Base coins granted in Kids Zone games.
* `hint_coin_cost` *(default: 15)*: Virtual coin cost to buy a hint token.
* `level_difficulty_modifier` *(default: 1.0)*: Global game speed / difficulty scaler.

---

## 4. How to Set Up & Update Parameters in Firebase Console

Follow these exact steps whenever you want to change any setting live:

### Step 1: Open Firebase Remote Config
1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Select your project: **`Vowl - Learn English (vowl-acbc5)`**.
3. In the left navigation menu, expand **Run** (or **Engage**) $\rightarrow$ click **Remote Config**.

### Step 2: Add or Edit a Parameter
1. Click **Add parameter** (or hover over an existing parameter and click the Edit pencil icon).
2. Enter the **Parameter name** (must match the exact key above, e.g. `latest_app_version`).
3. Select the **Data type** (`String`, `Number`, or `Boolean`).
4. Enter the **Default value** (e.g. `1.0.1`).
5. Click **Save**.

### Step 3: Publish Your Changes (Crucial!)
* After clicking Save, Firebase will show a banner at the top:
  `"1 change drafted — Publish changes to make it live"`.
* Click **Publish changes** and confirm.
* **Your changes are now live!** Every active user's app will fetch and activate the new values within 1 hour.

---

## 5. Practical Cheat Sheet for Common Scenarios

### Scenario A: You Just Released Version `1.0.1` on Google Play
In Firebase Console, set:
* `latest_app_version` = `1.0.1`
* `update_release_notes` =
  ```text
  • Google Sign-In profile and leaderboard sync
  • 120Hz high-refresh rate display optimization
  • Bug fixes and performance upgrades
  ```
* *Result:* Every user on `1.0.0` will see the "New Version Available!" popup with "Update Now".

### Scenario B: Critical Emergency Bug in Old Version
In Firebase Console, set:
* `min_app_version` = `1.0.1`
* *Result:* Anyone on `1.0.0` or below will be blocked by the "Update Required" dialog and cannot play until they update.

### Scenario C: Users Complain About Too Many Ads
In Firebase Console, set:
* `interstitial_cooldown_minutes` = `4` or `5`
* *Result:* Ads show much less frequently without releasing an app update.

### Scenario D: Turn Off All Interstitial Ads for 24 Hours (Event / Bug)
In Firebase Console, set:
* `ad_frequency_multiplier` = `0.0`
* *Result:* All interstitial ads stop showing immediately worldwide.
