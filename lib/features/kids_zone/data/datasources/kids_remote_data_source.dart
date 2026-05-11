import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vowl/features/kids_zone/data/models/kids_quest_model.dart';

abstract class KidsRemoteDataSource {
  Future<List<KidsQuestModel>> getQuestsByLevel(String gameType, int level);
}

class KidsRemoteDataSourceImpl implements KidsRemoteDataSource {
  final FirebaseFirestore firestore;

  KidsRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<KidsQuestModel>> getQuestsByLevel(
    String gameType,
    int level,
  ) async {
    final query = await firestore
        .collection('kids_quests')
        .where('gameType', isEqualTo: gameType)
        .where('level', isEqualTo: level)
        .get();

    return query.docs
        .map((doc) => KidsQuestModel.fromJson(doc.data()))
        .toList();
  }
}
