import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';

/// Abstract contract defining quest data seeding and administration boundaries.
///
/// Satisfies clean architecture design principles by separating core interfaces.
abstract class QuestUploadService {
  /// Factory constructor to support seamless backwards compatibility for callers.
  factory QuestUploadService({
    FirebaseFirestore? firestore,
  }) = QuestUploadServiceImpl;

  /// Validates and parses a JSON batch of quests, uploading them to Firestore in level-grouped documents.
  ///
  /// Safe against the Firestore 500-document batch limit by utilizing segmented chunking.
  Future<Map<String, dynamic>> uploadBatch({
    required String jsonInput,
    required QuestType skill,
    required GameSubtype subtype,
  });

  /// Wipes all seeded level documents under a specific game subtype.
  Future<void> wipeSubtype(GameSubtype subtype);
}

/// Concrete implementation of [QuestUploadService] utilizing Cloud Firestore batch transactions.
class QuestUploadServiceImpl implements QuestUploadService {
  final FirebaseFirestore _firestore;

  // Maximum batch operation boundary to ensure total compliance with Firestore guidelines
  static const int maxBatchOperationsLimit = 400;

  QuestUploadServiceImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Map<String, dynamic>> uploadBatch({
    required String jsonInput,
    required QuestType skill,
    required GameSubtype subtype,
  }) async {
    try {
      if (jsonInput.trim().isEmpty) {
        return {'success': false, 'message': 'JSON input is empty.'};
      }

      final dynamic decoded = jsonDecode(jsonInput);
      if (decoded is! List) {
        return {
          'success': false,
          'message': 'Invalid JSON structure: Root element must be an array of maps.',
        };
      }

      final List<Map<String, dynamic>> allQuests = [];
      for (final item in decoded) {
        if (item is! Map) {
          return {
            'success': false,
            'message': 'Invalid element detected: Array items must be structured map entities.',
          };
        }
        allQuests.add(Map<String, dynamic>.from(item));
      }

      if (allQuests.isEmpty) {
        return {'success': false, 'message': 'No quest records found.'};
      }

      // Group quests into their respective difficulty difficulty steps
      final Map<int, List<Map<String, dynamic>>> groupedByLevel = {};
      for (final quest in allQuests) {
        final level = (quest['difficulty'] as num?)?.toInt() ?? 1;
        if (!groupedByLevel.containsKey(level)) {
          groupedByLevel[level] = [];
        }
        groupedByLevel[level]!.add(quest);
      }

      var batch = _firestore.batch();
      int levelsCount = 0;
      int batchOperationsCount = 0;

      for (final levelNum in groupedByLevel.keys) {
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
        batchOperationsCount++;

        // Chunk commit transactions to completely avoid 500-write cap bounds
        if (batchOperationsCount >= maxBatchOperationsLimit) {
          await batch.commit();
          batch = _firestore.batch();
          batchOperationsCount = 0;
        }
      }

      if (batchOperationsCount > 0) {
        await batch.commit();
      }

      final maxLevel = groupedByLevel.keys.reduce((a, b) => a > b ? a : b);

      return {
        'success': true,
        'message': 'Successfully uploaded $levelsCount levels (${allQuests.length} quests)!',
        'maxLevel': maxLevel,
      };
    } catch (e) {
      return {'success': false, 'message': 'Upload pipeline failed: $e'};
    }
  }

  @override
  Future<void> wipeSubtype(GameSubtype subtype) async {
    final levels = await _firestore
        .collection('quests')
        .doc(subtype.name)
        .collection('levels')
        .get();

    var batch = _firestore.batch();
    int batchOperationsCount = 0;

    for (final doc in levels.docs) {
      batch.delete(doc.reference);
      batchOperationsCount++;

      // Segment transaction chunks to avoid Google Cloud transaction caps
      if (batchOperationsCount >= maxBatchOperationsLimit) {
        await batch.commit();
        batch = _firestore.batch();
        batchOperationsCount = 0;
      }
    }

    if (batchOperationsCount > 0) {
      await batch.commit();
    }
  }
}
