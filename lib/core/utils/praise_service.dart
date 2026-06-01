import 'dart:math';
import 'package:vowl/core/utils/tts_service.dart';

/// Abstract contract defining praise and positive reinforcement audio triggers.
///
/// Decouples voice reinforcement logic from calling UI/Bloc controllers,
/// in accordance with Clean Architecture principles.
abstract class PraiseService {
  /// Factory mapping to the concrete reinforcement service.
  factory PraiseService(TtsService ttsService) = PraiseServiceImpl;

  /// Plays a randomly selected positive reinforcement praise phrase.
  void givePraise({bool isKids = false});
}

/// Concrete implementation of [PraiseService] using [TtsService].
class PraiseServiceImpl implements PraiseService {
  final TtsService _ttsService;

  // Single static Random instance to optimize CPU/memory allocation
  static final Random _random = Random();

  // Static compile-time const collections to optimize heap memory allocations
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

  const PraiseServiceImpl(this._ttsService);

  @override
  void givePraise({bool isKids = false}) {
    final phrases = isKids ? _kidsEncouragements : _encouragements;
    final phrase = phrases[_random.nextInt(phrases.length)];
    
    // Play through the injected TtsService (DIP compliant)
    _ttsService.speak(phrase);
  }
}
