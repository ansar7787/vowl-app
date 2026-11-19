import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/roleplay/social_spark/presentation/pages/social_spark_mastery_screen.dart';
import 'package:vowl/features/roleplay/social_spark/presentation/pages/social_spark_screen.dart';

void main() {
  test('SocialSparkMasteryScreen is an alias of SocialSparkScreen', () {
    const screen = SocialSparkMasteryScreen(level: 1);
    expect(screen, isA<SocialSparkScreen>());
  });
}
