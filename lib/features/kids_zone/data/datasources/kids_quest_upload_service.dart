import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vowl/features/kids_zone/data/models/kids_quest_model.dart';

class KidsQuestUploadService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> uploadKidsBatch({
    required String jsonInput,
    required String gameType,
  }) async {
    try {
      final List<dynamic> decoded = jsonDecode(jsonInput);
      int totalUploaded = 0;
      int levelsCount = 0;
      final Set<int> uniqueLevels = {};

      // Split into chunks of 450 (to stay under the 500 Firestore limit safely)
      for (var i = 0; i < decoded.length; i += 450) {
        final end = (i + 450 < decoded.length) ? i + 450 : decoded.length;
        final chunk = decoded.sublist(i, end);

        final batch = _firestore.batch();
        for (var item in chunk) {
          final quest = KidsQuestModel.fromJson(item as Map<String, dynamic>);
          uniqueLevels.add(quest.level);
          final docRef = _firestore.collection('kids_quests').doc(quest.id);
          batch.set(docRef, quest.toJson());
          totalUploaded++;
        }
        await batch.commit();
      }

      levelsCount = uniqueLevels.length;
      return {
        'success': true,
        'message':
            'Pushed $totalUploaded quests across $levelsCount levels! 🚀',
        'questCount': totalUploaded,
        'levelCount': levelsCount,
      };
    } catch (e) {
      return {'success': false, 'message': 'Push failed: $e ❌'};
    }
  }

  Future<void> deleteGameQuests(String gameType) async {
    // For large collections, we might need multiple passes or a different strategy,
    // but for 200-500 quests per game, a single fetch is okay.
    final snapshot = await _firestore
        .collection('kids_quests')
        .where('gameType', isEqualTo: gameType)
        .get();

    if (snapshot.docs.isEmpty) return;

    // Delete in batches
    for (var i = 0; i < snapshot.docs.length; i += 450) {
      final end = (i + 450 < snapshot.docs.length)
          ? i + 450
          : snapshot.docs.length;
      final chunk = snapshot.docs.sublist(i, end);

      final batch = _firestore.batch();
      for (var doc in chunk) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<Map<String, int>> fetchGameStats(String gameType) async {
    final snapshot = await _firestore
        .collection('kids_quests')
        .where('gameType', isEqualTo: gameType)
        .get();

    final Set<int> levels = {};
    for (var doc in snapshot.docs) {
      final level = doc.data()['level'];
      if (level is int) levels.add(level);
    }

    return {'questCount': snapshot.docs.length, 'levelCount': levels.length};
  }
}
