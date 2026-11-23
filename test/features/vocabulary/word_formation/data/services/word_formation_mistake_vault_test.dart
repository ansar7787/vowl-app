import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/features/vocabulary/word_formation/data/services/word_formation_mistake_vault.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WordFormationMistakeVault', () {
    late WordFormationMistakeVault vault;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      vault = WordFormationMistakeVault();
    });

    test('recordMistake saves record and marks root as tracked', () async {
      await vault.recordMistake('DECIDE');
      final record = await vault.getRecord('DECIDE');

      expect(record, isNotNull);
      expect(record!.rootWord, 'DECIDE');
      expect(record.mistakeCount, 1);
      expect(record.consecutiveCorrect, 0);
      expect(record.intervalDays, 1);
    });

    test('recordSuccess increases consecutiveCorrect and advances interval', () async {
      await vault.recordMistake('CARE');
      await vault.recordSuccess('CARE');

      final record = await vault.getRecord('CARE');
      expect(record, isNotNull);
      expect(record!.consecutiveCorrect, 1);
      expect(record.intervalDays, 3); // 3 days after 1st successful recall
    });

    test('recordSuccess advances to 7 days on 2nd recall and 30 days on mastery', () async {
      await vault.recordMistake('CREATE');
      await vault.recordSuccess('CREATE');
      await vault.recordSuccess('CREATE');

      var record = await vault.getRecord('CREATE');
      expect(record!.consecutiveCorrect, 2);
      expect(record.intervalDays, 7);

      await vault.recordSuccess('CREATE');
      record = await vault.getRecord('CREATE');
      expect(record!.consecutiveCorrect, 3);
      expect(record.intervalDays, 30);
      expect(record.isMastered, isTrue);
    });

    test('clearVault removes all records', () async {
      await vault.recordMistake('DECIDE');
      await vault.clearVault();

      final record = await vault.getRecord('DECIDE');
      expect(record, isNull);
    });
  });
}
