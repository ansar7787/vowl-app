import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/roleplay/medical_consult/presentation/pages/medical_consult_mastery_screen.dart';
import 'package:vowl/features/roleplay/medical_consult/presentation/pages/medical_consult_screen.dart';

void main() {
  test('MedicalConsultMasteryScreen is an alias of MedicalConsultScreen', () {
    const screen = MedicalConsultMasteryScreen(level: 1);
    expect(screen, isA<MedicalConsultScreen>());
  });
}
