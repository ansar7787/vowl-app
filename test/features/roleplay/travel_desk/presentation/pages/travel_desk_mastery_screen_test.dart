import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/roleplay/travel_desk/presentation/pages/travel_desk_mastery_screen.dart';
import 'package:vowl/features/roleplay/travel_desk/presentation/pages/travel_desk_screen.dart';

void main() {
  test('TravelDeskMasteryScreen is an alias of TravelDeskScreen', () {
    const screen = TravelDeskMasteryScreen(level: 1);
    expect(screen, isA<TravelDeskScreen>());
  });
}
