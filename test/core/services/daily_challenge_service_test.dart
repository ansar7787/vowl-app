import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/services/daily_challenge_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'DailyChallengeService loads Word Mixer, Word Snap, and Handwriting curriculum',
    () async {
      final mixer = await DailyChallengeService.getTodayWordMixer();
      expect(mixer, isNotNull);
      expect(mixer!['word'], isNotNull);

      final snap = await DailyChallengeService.getTodayWordSnap();
      expect(snap, isNotNull);
      expect(snap!['word'], isNotNull);

      final handwriting = await DailyChallengeService.getTodayHandwriting();
      expect(handwriting, isNotNull);
      expect(
        handwriting!['question'] != null || handwriting['instruction'] != null,
        isTrue,
      );

      final randomHw = await DailyChallengeService.getRandomHandwriting();
      expect(randomHw, isNotNull);
    },
  );
}
