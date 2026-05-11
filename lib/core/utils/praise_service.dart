import 'dart:math';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class PraiseService {
  final List<String> _encouragements = [
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

  final List<String> _kidsEncouragements = [
    "Yay! You did it!",
    "Wow! You're so smart!",
    "Great job, friend!",
    "You found it! Awesome!",
    "Superstar learner!",
    "You're the best!",
    "High five! That's right!",
  ];

  void givePraise({bool isKids = false}) {
    final random = Random();
    final phrases = isKids ? _kidsEncouragements : _encouragements;
    final phrase = phrases[random.nextInt(phrases.length)];
    
    // Use the existing TtsService
    di.sl<TtsService>().speak(phrase);
  }
}
