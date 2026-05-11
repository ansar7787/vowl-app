import '../../domain/entities/reading_quest.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../domain/repositories/reading_repository.dart';

class ReadingRepositoryImpl implements ReadingRepository {
  final dynamic remoteDataSource;
  final dynamic networkInfo;
  ReadingRepositoryImpl({this.remoteDataSource, this.networkInfo});

  @override
  Future<Either<Failure, List<ReadingQuest>>> getReadingQuest({
    required GameSubtype gameType,
    required int level,
  }) async {
    try {
      final remoteQuests = await remoteDataSource.getReadingQuest(
        gameType: gameType,
        level: level,
      );
      return Right(remoteQuests);
    } catch (e) {
      return Left(
        ServerFailure(
          e.toString(),
        ),
      );
    }
  }
}
