import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';

/// Abstract contract defining quest data seeding and administration boundaries.
///
/// Satisfies clean architecture design principles by separating core interfaces.
abstract class QuestUploadService {
  /// Factory constructor to support seamless backwards compatibility for callers.
  factory QuestUploadService({FirebaseFirestore? firestore}) =
      QuestUploadServiceImpl;

  /// Validates and parses a JSON batch of quests, uploading them to Firestore in level-grouped documents.
  ///
  /// Safe against the Firestore 500-document batch limit by utilizing segmented chunking.
  Future<Map<String, dynamic>> uploadBatch({
    required String jsonInput,
    required QuestType skill,
    required GameSubtype subtype,
  });

  /// Wipes all seeded level documents under a specific game subtype.
  ///
  /// Returns the number of documents deleted, for admin-facing confirmation
  /// and audit logging of this irreversible operation.
  Future<int> wipeSubtype(GameSubtype subtype);
}

/// Concrete implementation of [QuestUploadService] utilizing Cloud Firestore batch transactions.
class QuestUploadServiceImpl implements QuestUploadService {
  final FirebaseFirestore _firestore;

  // Maximum batch operation boundary to ensure total compliance with Firestore guidelines
  static const int maxBatchOperationsLimit = 400;

  // Defensive network timeout so a stalled connection fails the admin
  // operation cleanly instead of hanging indefinitely.
  static const Duration _commitTimeout = Duration(seconds: 30);

  QuestUploadServiceImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

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
          'message':
              'Invalid JSON structure: Root element must be an array of maps.',
        };
      }

      final List<Map<String, dynamic>> allQuests = [];
      for (final item in decoded) {
        if (item is! Map) {
          return {
            'success': false,
            'message':
                'Invalid element detected: Array items must be structured map entities.',
          };
        }
        allQuests.add(Map<String, dynamic>.from(item));
      }

      if (allQuests.isEmpty) {
        return {'success': false, 'message': 'No quest records found.'};
      }

      // Group quests into their respective difficulty steps. A safe,
      // non-throwing per-item parse means a single malformed entry produces
      // a clear, actionable error message (which item, what's wrong)
      // instead of a generic cast-exception string from the outer catch.
      final Map<int, List<Map<String, dynamic>>> groupedByLevel = {};
      for (int i = 0; i < allQuests.length; i++) {
        final quest = allQuests[i];
        final rawDifficulty = quest['difficulty'];
        int level;
        if (rawDifficulty == null) {
          level = 1;
        } else if (rawDifficulty is num) {
          level = rawDifficulty.toInt();
        } else if (rawDifficulty is String &&
            int.tryParse(rawDifficulty) != null) {
          level = int.parse(rawDifficulty);
        } else {
          return {
            'success': false,
            'message':
                'Invalid "difficulty" value at quest index $i: expected a number, got "$rawDifficulty".',
          };
        }

        groupedByLevel.putIfAbsent(level, () => []).add(quest);
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
          await batch.commit().timeout(_commitTimeout);
          batch = _firestore.batch();
          batchOperationsCount = 0;
        }
      }

      if (batchOperationsCount > 0) {
        await batch.commit().timeout(_commitTimeout);
      }

      final maxLevel = groupedByLevel.keys.reduce((a, b) => a > b ? a : b);

      return {
        'success': true,
        'message':
            'Successfully uploaded $levelsCount levels (${allQuests.length} quests)!',
        'maxLevel': maxLevel,
      };
    } catch (e) {
      return {'success': false, 'message': 'Upload pipeline failed: $e'};
    }
  }

  @override
  Future<int> wipeSubtype(GameSubtype subtype) async {
    final levels = await _firestore
        .collection('quests')
        .doc(subtype.name)
        .collection('levels')
        .get()
        .timeout(_commitTimeout);

    var batch = _firestore.batch();
    int batchOperationsCount = 0;
    int deletedCount = 0;

    for (final doc in levels.docs) {
      batch.delete(doc.reference);
      batchOperationsCount++;
      deletedCount++;

      // Segment transaction chunks to avoid Google Cloud transaction caps
      if (batchOperationsCount >= maxBatchOperationsLimit) {
        await batch.commit().timeout(_commitTimeout);
        batch = _firestore.batch();
        batchOperationsCount = 0;
      }
    }

    if (batchOperationsCount > 0) {
      await batch.commit().timeout(_commitTimeout);
    }

    return deletedCount;
  }
}
