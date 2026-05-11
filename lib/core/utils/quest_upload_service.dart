import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';

class QuestUploadService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> uploadBatch({
    required String jsonInput,
    required QuestType skill,
    required GameSubtype subtype,
  }) async {
    try {
      final List decoded = jsonDecode(jsonInput);
      final List<Map<String, dynamic>> allQuests = decoded
          .cast<Map<String, dynamic>>();

      if (allQuests.isEmpty) {
        return {'success': false, 'message': 'JSON array is empty.'};
      }

      final Map<int, List<Map<String, dynamic>>> groupedByLevel = {};
      for (var quest in allQuests) {
        final level = quest['difficulty'] ?? 1;
        if (!groupedByLevel.containsKey(level)) {
          groupedByLevel[level] = [];
        }
        groupedByLevel[level]!.add(quest);
      }

      final batch = _firestore.batch();
      int levelsCount = 0;

      for (var levelNum in groupedByLevel.keys) {
        final questsForThisLevel = groupedByLevel[levelNum]!;

        final levelData = {
          'id': 'level_$levelNum',
          'levelNumber': levelNum,
          'skill': skill.name,
          'gameType': subtype.name,
          'quests': questsForThisLevel,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        final docRef = _firestore
            .collection('quests')
            .doc(subtype.name)
            .collection('levels')
            .doc(levelNum.toString());

        batch.set(docRef, levelData, SetOptions(merge: true));
        levelsCount++;
      }

      await batch.commit();

      return {
        'success': true,
        'message':
            'Successfully uploaded $levelsCount levels (${allQuests.length} quests)!',
        'maxLevel': groupedByLevel.keys.reduce((a, b) => a > b ? a : b),
      };
    } catch (e) {
      return {'success': false, 'message': 'Upload failed: $e'};
    }
  }

  Future<void> wipeSubtype(GameSubtype subtype) async {
    final levels = await _firestore
        .collection('quests')
        .doc(subtype.name)
        .collection('levels')
        .get();

    final batch = _firestore.batch();
    for (var doc in levels.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
