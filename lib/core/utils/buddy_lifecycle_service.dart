import 'package:vowl/features/auth/domain/entities/user_entity.dart';

/// Determines buddy mood, energy/hunger decay, and care streak logic
/// for the Kids Room screen.
///
/// This service is stateless — it reads persisted fields from [UserEntity]
/// and computes derived values (current mood, whether feed is on cooldown,
/// whether care streak is active today, etc.) without side effects.
class BuddyLifecycleService {
  const BuddyLifecycleService();

  // ---------------------------------------------------------------------------
  // Mood calculation
  // ---------------------------------------------------------------------------

  /// Valid mood values: happy, hungry, sleepy, bored, excited.
  static const moods = ['happy', 'hungry', 'sleepy', 'bored', 'excited'];

  /// Computes the current mood based on energy, hunger, and time since
  /// last interaction. Returns one of [moods].
  String computeMood(UserEntity user) {
    // Priority order: hunger > sleepiness > boredom > happy
    if (user.kidsBuddyHunger >= 70) return 'hungry';
    if (user.kidsBuddyEnergy <= 30) return 'sleepy';

    final lastCare = user.kidsLastCareDate;
    if (lastCare != null) {
      final hoursSinceCare =
          DateTime.now().difference(lastCare).inHours;
      if (hoursSinceCare >= 2) return 'bored';
    } else {
      // Never cared for → bored
      return 'bored';
    }

    // If recently interacted and hunger/energy are fine
    if (user.kidsBuddyEnergy >= 80 && user.kidsBuddyHunger <= 20) {
      return 'excited';
    }

    return 'happy';
  }

  // ---------------------------------------------------------------------------
  // Energy & Hunger decay (called on room entry)
  // ---------------------------------------------------------------------------

  /// Calculates how much energy has decayed since [user.kidsLastCareDate].
  /// Energy decays at ~5 points per hour, clamped to [0, 100].
  int computeDecayedEnergy(UserEntity user) {
    final lastCare = user.kidsLastCareDate;
    if (lastCare == null) return 50; // Default for first-ever visit

    final hoursSince = DateTime.now().difference(lastCare).inMinutes / 60.0;
    final decayed = (user.kidsBuddyEnergy - (hoursSince * 5).toInt())
        .clamp(0, 100);
    return decayed;
  }

  /// Calculates how much hunger has increased since [user.kidsLastFeedTime].
  /// Hunger increases at ~8 points per hour, clamped to [0, 100].
  int computeIncreasedHunger(UserEntity user) {
    final lastFeed = user.kidsLastFeedTime;
    if (lastFeed == null) return 60; // Default for first-ever visit

    final hoursSince = DateTime.now().difference(lastFeed).inMinutes / 60.0;
    final increased = (user.kidsBuddyHunger + (hoursSince * 8).toInt())
        .clamp(0, 100);
    return increased;
  }

  // ---------------------------------------------------------------------------
  // Feed cooldown
  // ---------------------------------------------------------------------------

  /// Returns true if the buddy can be fed (30-minute cooldown has elapsed).
  bool canFeed(UserEntity user) {
    final lastFeed = user.kidsLastFeedTime;
    if (lastFeed == null) return true;
    return DateTime.now().difference(lastFeed).inMinutes >= 30;
  }

  /// Returns remaining cooldown minutes for feeding, or 0 if ready.
  int feedCooldownMinutes(UserEntity user) {
    final lastFeed = user.kidsLastFeedTime;
    if (lastFeed == null) return 0;
    final elapsed = DateTime.now().difference(lastFeed).inMinutes;
    return (30 - elapsed).clamp(0, 30);
  }

  // ---------------------------------------------------------------------------
  // Care streak
  // ---------------------------------------------------------------------------

  /// Returns true if the user has already cared for their buddy today.
  bool hasCompletedCareToday(UserEntity user) {
    final lastCare = user.kidsLastCareDate;
    if (lastCare == null) return false;
    final now = DateTime.now();
    return lastCare.year == now.year &&
        lastCare.month == now.month &&
        lastCare.day == now.day;
  }

  /// Computes the new care streak value.
  /// If the last care was yesterday → streak + 1.
  /// If the last care was today → same streak.
  /// If more than 1 day gap → reset to 1.
  int computeUpdatedStreak(UserEntity user) {
    final lastCare = user.kidsLastCareDate;
    if (lastCare == null) return 1;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(lastCare.year, lastCare.month, lastCare.day);
    final diff = today.difference(lastDay).inDays;

    if (diff == 0) return user.kidsCareStreak; // Already cared today
    if (diff == 1) return user.kidsCareStreak + 1; // Consecutive day
    return 1; // Streak broken, restart
  }

  // ---------------------------------------------------------------------------
  // Room level
  // ---------------------------------------------------------------------------

  /// Returns the total care actions needed for the given room level.
  /// Level 1 = 0, Level 2 = 10, Level 3 = 25, Level 4 = 50, Level 5 = 100.
  static const _levelThresholds = [0, 10, 25, 50, 100, 200, 500];

  /// Returns coins bonus for reaching a room level.
  int roomLevelBonus(int level) {
    switch (level) {
      case 2: return 50;
      case 3: return 100;
      case 4: return 200;
      case 5: return 500;
      default: return 25;
    }
  }

  // ---------------------------------------------------------------------------
  // Mood-aware messages
  // ---------------------------------------------------------------------------

  /// Returns a greeting based on the buddy's current mood and the time of day.
  String getGreeting(UserEntity user) {
    final hour = DateTime.now().hour;
    final mood = user.kidsBuddyMood;

    if (hour < 6) return _nightGreeting(mood);
    if (hour < 12) return _morningGreeting(mood);
    if (hour < 18) return _afternoonGreeting(mood);
    return _eveningGreeting(mood);
  }

  String _morningGreeting(String mood) {
    switch (mood) {
      case 'hungry': return "Good morning! I'm so hungry... 🥺";
      case 'sleepy': return "Mmm... still so sleepy... 😴";
      case 'bored': return "Finally! I missed you! 🎈";
      case 'excited': return "GOOD MORNING! Let's learn! 🌟";
      default: return "Good morning, best friend! ☀️";
    }
  }

  String _afternoonGreeting(String mood) {
    switch (mood) {
      case 'hungry': return "My tummy is rumbling! 🍽️";
      case 'sleepy': return "I need a little nap... 💤";
      case 'bored': return "Can we play something? 🎮";
      case 'excited': return "This is so much fun! 🎉";
      default: return "Hey there, buddy! 🌈";
    }
  }

  String _eveningGreeting(String mood) {
    switch (mood) {
      case 'hungry': return "Dinner time please! 🍕";
      case 'sleepy': return "I'm getting really sleepy... 🌙";
      case 'bored': return "One more game before bed? 🎲";
      case 'excited': return "What a great day! ⭐";
      default: return "It's getting late! 🌅";
    }
  }

  String _nightGreeting(String mood) {
    switch (mood) {
      case 'hungry': return "A midnight snack? 🍪";
      case 'sleepy': return "Zzz... let me sleep... 💤";
      default: return "Shh... it's bedtime! 🌙";
    }
  }

  /// Returns a context-aware encouragement based on mood.
  List<String> getMoodMessages(String mood) {
    switch (mood) {
      case 'hungry':
        return [
          "Feed me something yummy! 🍎",
          "My tummy is making noises! 🥺",
          "A snack would be amazing! 🍰",
          "Please, I'm starving! 😢",
        ];
      case 'sleepy':
        return [
          "I could use a nap... 😴",
          "My eyes are getting heavy... 💤",
          "Tuck me in? 🛏️",
          "So... tired... 🥱",
        ];
      case 'bored':
        return [
          "Let's do something fun! 🎮",
          "I'm bored! Play with me! 🎈",
          "Teach me something new! 📚",
          "Adventure awaits! 🗺️",
        ];
      case 'excited':
        return [
          "WOOHOO! You're amazing! 🎉",
          "I love learning with you! 🌟",
          "We're the best team! 💪",
          "Let's conquer the world! 🚀",
          "You make me SO happy! ❤️",
        ];
      default: // happy
        return [
          "You are doing amazing! 🌟",
          "I love playing with you! 🎈",
          "You are getting so smart! 🧠",
          "Keep up the great work! ✨",
          "You're my best friend! 🦉",
          "We learned so much today! 📖",
          "I'm proud of you! 💖",
        ];
    }
  }
}
