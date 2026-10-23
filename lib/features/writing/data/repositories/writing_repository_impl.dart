import '../../domain/entities/writing_quest.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../domain/repositories/writing_repository.dart';

/// Concrete implementation of [WritingRepository] coordinating remote and local data sources.
class WritingRepositoryImpl implements WritingRepository {
  /// Remote data source instance.
  final dynamic remoteDataSource;

  /// Network connectivity service.
  final dynamic networkInfo;

  /// Creates a [WritingRepositoryImpl] instance.
  WritingRepositoryImpl({this.remoteDataSource, this.networkInfo});

  @override
  Future<Either<Failure, List<WritingQuest>>> getWritingQuest({
    required GameSubtype gameType,
    required int level,
  }) async {
    try {
      final remoteQuests = await remoteDataSource.getWritingQuest(
        gameType: gameType,
        level: level,
      );
      return Right(remoteQuests);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
