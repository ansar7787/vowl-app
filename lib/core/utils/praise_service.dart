import 'dart:math';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/tts_service.dart';

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
  void givePraise({bool isKids = false});
}

/// Concrete implementation of [PraiseService] using [TtsService].
class PraiseServiceImpl implements PraiseService {
  final TtsService _ttsService;
  final LocaleService? _localeService;

  // Single static Random instance to optimize CPU/memory allocation
  static final Random _random = Random();

  // Static compile-time const collections to optimize heap memory allocations.
  // These also serve as the English fallback when no LocaleService is wired
  // up, or when a translation key is missing for the active locale.
  static const List<String> _encouragements = [
    "Incredible work!",
    "You're a natural!",
    "Brilliant!",
    "Perfect score!",
    "You're on fire!",
    "Amazing progress!",
    "You're becoming a master!",
    "Outstanding!",
    "Keep it up, hero!",
    "That was super fast!",
  ];

  static const List<String> _kidsEncouragements = [
    "Yay! You did it!",
    "Wow! You're so smart!",
    "Great job, friend!",
    "You found it! Awesome!",
    "Superstar learner!",
    "You're the best!",
    "High five! That's right!",
  ];

  const PraiseServiceImpl(this._ttsService, {LocaleService? localeService})
    : _localeService = localeService;

  @override
  void givePraise({bool isKids = false}) {
    final pool = isKids ? _kidsEncouragements : _encouragements;
    final index = _random.nextInt(pool.length);
    final phrase = _localizedPhrase(
      isKids: isKids,
      index: index,
      fallback: pool[index],
    );

    // Play through the injected TtsService (DIP compliant)
    _ttsService.speak(phrase);
  }

  String _localizedPhrase({
    required bool isKids,
    required int index,
    required String fallback,
  }) {
    final service = _localeService;
    if (service == null) return fallback;
    final keyPrefix = isKids ? 'praise.kids' : 'praise.standard';
    return service.tr('$keyPrefix.$index', fallback: fallback);
  }
}
