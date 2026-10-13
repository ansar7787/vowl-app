import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/services/daily_challenge_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DailyChallengeService loads Word Mixer and Word Snap curriculum', () async {
    final mixer = await DailyChallengeService.getTodayWordMixer();
    expect(mixer, isNotNull);
    expect(mixer!['word'], isNotNull);

    final snap = await DailyChallengeService.getTodayWordSnap();
    expect(snap, isNotNull);
    expect(snap!['word'], isNotNull);
  });
}

