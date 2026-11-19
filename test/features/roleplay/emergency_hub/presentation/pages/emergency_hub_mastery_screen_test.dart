import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/roleplay/emergency_hub/presentation/pages/emergency_hub_mastery_screen.dart';
import 'package:vowl/features/roleplay/emergency_hub/presentation/pages/emergency_hub_screen.dart';

void main() {
  test('EmergencyHubMasteryScreen is an alias of EmergencyHubScreen', () {
    const screen = EmergencyHubMasteryScreen(level: 1);
    expect(screen, isA<EmergencyHubScreen>());
  });
}
