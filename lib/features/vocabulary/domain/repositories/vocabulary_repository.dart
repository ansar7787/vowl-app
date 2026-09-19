import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';

abstract class VocabularyRepository {
  Future<Either<Failure, List<VocabularyQuest>>> getVocabularyQuests(
    String gameType,
    int level,
  );
}
