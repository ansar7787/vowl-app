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
          "My tummy is doing a little rumbly dance! 🥺",
          "Do you have any yummy snacks for me? 🍎",
          "I think it's time for a little treat! 🍰",
          "I'm so hungry I could eat a whole watermelon! 🍉",
          "Feed me, please! I promise I'll be good! 😢",
          "A tiny cookie would make me so happy right now! 🍪",
          "My tummy says it's lunch time! 🥪",
          "Can we share a yummy snack together? 🥕",
          "I need some food to grow big and strong! 💪",
          "I'm dreaming about delicious pancakes! 🥞",
          "Do you hear that? That's my empty tummy! 🍽️",
          "Just one little bite of something sweet? 🍯",
          "I would love some fresh fruit! 🍌",
          "Feeding time is my favorite time! 😋",
          "I'm a very hungry little buddy! 🐾"
        ];
      case 'sleepy':
        return [
          "I'm feeling a little bit snoozy... 😴",
          "My eyes are getting so, so heavy... 💤",
          "Can you tuck me into bed, please? 🛏️",
          "Yawn... excuse me, I'm just so tired! 🥱",
          "Is it time to wear our pajamas? 🌙",
          "Just five more minutes of sleep, okay? 🛌",
          "I want to dream about flying in the sky... ☁️",
          "Let's take a tiny little nap together. 💤",
          "I'm too sleepy to keep my eyes open! 😴",
          "Can you sing me a quiet lullaby? 🎶",
          "It's time for sweet dreams, best friend. 🌠",
          "I need to rest my little paws... 🐾",
          "The dream world is calling my name! 🌌",
          "Goodnight... wait, I'm not asleep yet! 🥱",
          "A soft pillow sounds amazing right now. 🧸"
        ];
      case 'bored':
        return [
          "Let's play a silly game together! 🎮",
          "I want to jump and play and run! 🎈",
          "Can we do something super duper fun? 🎪",
          "I'm waiting for a fun adventure with you! 🗺️",
          "Let's see who can make the funniest face! 🤪",
          "I want to explore the room! 🔭",
          "Sitting still is so tricky, let's wiggle! 🤸‍♂️",
          "Tell me a funny story, please! 📖",
          "I wonder what toys we can play with? 🎯",
          "Let's pretend we are magical wizards! 🧙‍♂️",
          "I'm a little bored, let's learn something new! 🎨",
          "Can we build a tall tower out of blocks? 🧱",
          "Let's play hide and seek! You count first! 🫣",
          "Do you want to sing a song with me? 🎵",
          "I'm ready for playtime whenever you are! 🏃‍♂️"
        ];
      case 'excited':
        return [
          "WOOHOO! Today is the best day ever! 🎉",
          "I love playing and learning with you! 🌟",
          "We are the best team in the whole wide world! 💫",
          "Let's jump up and down together! 🦘",
          "You make me SO happy, best friend! ❤️",
          "I have so many wiggles inside me! ⚡",
          "YAY! Let's play another fun game! 🎊",
          "High five! You are super awesome! ✋",
          "I'm so excited I could do a backflip! 🤸‍♀️",
          "Everything is just so much fun today! 🎈",
          "You always know how to make me smile! 😊",
          "I'm bouncing off the walls with joy! 🌟",
          "Look at us go! We are super smart! 🦉",
          "I can't wait to see what we do next! 🚀",
          "Hooray for playtime with my favorite person! 🏆"
        ];
      default: // happy
        return [
          "You are doing such a great job! 🌟",
          "I love being your special buddy! 🎈",
          "You are getting so smart every day! 🧠",
          "Keep smiling, it makes me happy! ✨",
          "You're my absolute best friend! 🦉",
          "We learned so many cool things today! 📖",
          "I'm so, so proud of you! 💖",
          "I love our cozy little room! 🏡",
          "Spending time with you is my favorite! 😊",
          "You shine brighter than a star! 🌠",
          "Learning new words is like magic! 🎨",
          "Your brain is growing so big and strong! 🌻",
          "Every day is a happy adventure with you! 🌍",
          "I give you a big virtual hug! 🤗",
          "Thanks for taking such good care of me! 🥰"
        ];
    }
  }
}
