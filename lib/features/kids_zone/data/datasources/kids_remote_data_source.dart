import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vowl/core/error/exceptions.dart';
import 'package:vowl/features/kids_zone/data/models/kids_quest_model.dart';

/// Remote data source contract for querying Kids Zone quests from Cloud Firestore.
abstract class KidsRemoteDataSource {
  /// Retrieves kids quests for a given [gameType] and [level] from Firestore.
  Future<List<KidsQuestModel>> getQuestsByLevel(String gameType, int level);
}

/// Default implementation of [KidsRemoteDataSource] querying Cloud Firestore collections.
class KidsRemoteDataSourceImpl implements KidsRemoteDataSource {
  /// The Firestore database instance.
  final FirebaseFirestore firestore;

  /// Creates a [KidsRemoteDataSourceImpl] instance with the specified [firestore].
  const KidsRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<KidsQuestModel>> getQuestsByLevel(
    String gameType,
    int level,
  ) async {
    try {
      final query = await firestore
          .collection('kids_quests')
          .where('gameType', isEqualTo: gameType)
          .where('level', isEqualTo: level)
          .get();

      return query.docs
          .map((doc) => KidsQuestModel.fromJson(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Firestore error occurred while loading quests',
        e.code,
      );
    } catch (e) {
      throw ServerException(e.toString(), 'UNKNOWN_REMOTE_ERROR');
    }
  }
}
