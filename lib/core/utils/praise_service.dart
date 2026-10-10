import 'dart:math';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/age_gate_service.dart';

/// Strategy pattern interface for positive reinforcement praise.
abstract class PraiseStrategy {
  List<String> get encouragements;
  String get localizedPrefix;
}

class StandardPraiseStrategy implements PraiseStrategy {
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
  String get localizedPrefix => 'praise.standard';
}

class KidsPraiseStrategy implements PraiseStrategy {
  @override
  List<String> get encouragements => const [
    "Yay! You did it!",
    "Wow! You're so smart!",
    "Great job, friend!",
    "You found it! Awesome!",
    "Superstar learner!",
    "You're the best!",
    "High five! That's right!",
  ];

  @override
  String get localizedPrefix => 'praise.kids';
}

/// Abstract contract defining praise and positive reinforcement audio triggers.
///
/// Decouples voice reinforcement logic from calling UI/Bloc controllers,
/// in accordance with Clean Architecture principles.
abstract class PraiseService {
  /// Factory mapping to the concrete reinforcement service.
  ///
  /// [localeService] is optional and additive: existing DI registrations
  /// that call `PraiseService(ttsService)` keep compiling unchanged and
  /// keep using the English phrase pool. Passing a [LocaleService] enables
  /// localized praise phrases for the 18 supported languages.
  factory PraiseService(TtsService ttsService, {LocaleService? localeService}) =
      PraiseServiceImpl;

  /// Plays a randomly selected positive reinforcement praise phrase.
  void givePraise();
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
  void givePraise() {
    // Strategy based on age gate
    final PraiseStrategy strategy = AgeGateService.isAdultCached
        ? StandardPraiseStrategy()
        : KidsPraiseStrategy();

    final pool = strategy.encouragements;
    final index = _random.nextInt(pool.length);
    final phrase = _localizedPhrase(
      strategy: strategy,
      index: index,
      fallback: pool[index],
    );

    // Play through the injected TtsService (DIP compliant)
    _ttsService.speak(phrase);
  }

  String _localizedPhrase({
    required PraiseStrategy strategy,
    required int index,
    required String fallback,
  }) {
    final service = _localeService;
    if (service == null) return fallback;
    return service.tr('${strategy.localizedPrefix}.$index', fallback: fallback);
  }
}
