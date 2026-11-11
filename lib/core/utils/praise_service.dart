import 'dart:math';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/tts_service.dart';

/// Context category driving adaptive positive reinforcement praise.
enum PraiseContext {
  /// Standard correct answer encouragement.
  standard,

  /// Clean completion of all 3 level questions with 0 mistakes.
  flawless,

  /// Extended session milestone: 5 consecutive correct answers across levels.
  hotStreak5,

  /// Extended session milestone: 10 consecutive correct answers across levels.
  hotStreak10,

  /// Daily streak habit secured.
  streakSecured,
}

/// Strategy pattern interface for positive reinforcement praise.
abstract class PraiseStrategy {
  List<String> get encouragements;
  List<String> get flawlessEncouragements;
  List<String> get hotStreak5Encouragements;
  List<String> get hotStreak10Encouragements;
  List<String> get streakSecuredEncouragements;
  String get localizedPrefix;

  List<String> getPhrasesForContext(PraiseContext context) {
    switch (context) {
      case PraiseContext.flawless:
        return flawlessEncouragements;
      case PraiseContext.hotStreak5:
        return hotStreak5Encouragements;
      case PraiseContext.hotStreak10:
        return hotStreak10Encouragements;
      case PraiseContext.streakSecured:
        return streakSecuredEncouragements;
      case PraiseContext.standard:
        return encouragements;
    }
  }
}

/// Praise strategy delivering concise, adult-appropriate positive reinforcement.
class StandardPraiseStrategy extends PraiseStrategy {
  @override
  List<String> get encouragements => const [
    "Correct!",
    "Well done.",
    "Nice work!",
    "Good recall!",
    "Solid answer.",
    "That's right.",
    "Nailed it.",
    "Sharp!",
    "Spot on.",
    "Great progress.",
  ];

  @override
  List<String> get flawlessEncouragements => const [
    "Flawless! 3 out of 3.",
    "Perfect score!",
    "Three for three!",
    "Clean sweep! Zero mistakes.",
    "Masterful accuracy.",
  ];

  @override
  List<String> get hotStreak5Encouragements => const [
    "5 in a row! You're on fire!",
    "Five straight! Unstoppable!",
    "5-streak! Incredible focus!",
  ];

  @override
  List<String> get hotStreak10Encouragements => const [
    "10 in a row! Legendary run!",
    "Ten straight! Total mastery!",
  ];

  @override
  List<String> get streakSecuredEncouragements => const [
    "Today's streak secured!",
    "Daily mission complete! Streak protected.",
  ];

  @override
  String get localizedPrefix => 'praise.standard';
}

/// Abstract contract defining praise and positive reinforcement audio triggers.
///
/// Decouples voice reinforcement logic from calling UI/Bloc controllers,
/// in accordance with Clean Architecture principles.
abstract class PraiseService {
  /// Factory mapping to the concrete reinforcement service.
  factory PraiseService(TtsService ttsService, {LocaleService? localeService}) =
      PraiseServiceImpl;

  /// Plays a randomly selected positive reinforcement praise phrase tailored to [context].
  void givePraise({PraiseContext context = PraiseContext.standard});

  /// Stops any actively playing praise audio.
  void stop();

  /// Releases resources held by this praise service.
  void dispose();
}

/// Concrete implementation of [PraiseService] using [TtsService].
class PraiseServiceImpl implements PraiseService {
  final TtsService _ttsService;
  final LocaleService? _localeService;

  // Single static Random instance to optimize CPU/memory allocation
  static final Random _random = Random();

  const PraiseServiceImpl(this._ttsService, {LocaleService? localeService})
    : _localeService = localeService;

  @override
  void givePraise({PraiseContext context = PraiseContext.standard}) {
    final PraiseStrategy strategy = StandardPraiseStrategy();

    final pool = strategy.getPhrasesForContext(context);
    final index = _random.nextInt(pool.length);
    final phrase = _localizedPhrase(
      strategy: strategy,
      context: context,
      index: index,
      fallback: pool[index],
    );

    // Play through the injected TtsService (DIP compliant) with natural, encouraging rate
    _ttsService.speak(phrase);
  }

  @override
  void stop() {
    _ttsService.stop();
  }

  @override
  void dispose() {
    _ttsService.stop();
  }

  String _localizedPhrase({
    required PraiseStrategy strategy,
    required PraiseContext context,
    required int index,
    required String fallback,
  }) {
    final service = _localeService;
    if (service == null) return fallback;
    final String keySuffix = context == PraiseContext.standard
        ? '$index'
        : '${context.name}.$index';
    return service.tr(
      '${strategy.localizedPrefix}.$keySuffix',
      fallback: fallback,
    );
  }
}
