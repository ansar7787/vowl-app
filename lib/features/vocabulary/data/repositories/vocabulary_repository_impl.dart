import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/features/vocabulary/domain/repositories/vocabulary_repository.dart';
import 'package:vowl/features/vocabulary/data/datasources/vocabulary_remote_data_source.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';

/// Default implementation of [VocabularyRepository] mediating remote and local quest data sources.
class VocabularyRepositoryImpl implements VocabularyRepository {
  /// Remote data source for vocabulary quests.
  final VocabularyRemoteDataSource remoteDataSource;

  /// Creates a [VocabularyRepositoryImpl] with the specified [remoteDataSource].
  VocabularyRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<VocabularyQuest>>> getVocabularyQuests(
    String gameType,
    int level,
  ) async {
    try {
      final quests = await remoteDataSource.getVocabularyQuests(
        gameType,
        level,
      );
      return Right(quests);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
