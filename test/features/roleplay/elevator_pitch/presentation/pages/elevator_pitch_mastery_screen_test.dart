import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/roleplay/elevator_pitch/presentation/pages/elevator_pitch_mastery_screen.dart';
import 'package:vowl/features/roleplay/elevator_pitch/presentation/pages/elevator_pitch_screen.dart';

void main() {
  test('ElevatorPitchMasteryScreen is an alias of ElevatorPitchScreen', () {
    const screen = ElevatorPitchMasteryScreen(level: 1);
    expect(screen, isA<ElevatorPitchScreen>());
  });
}
