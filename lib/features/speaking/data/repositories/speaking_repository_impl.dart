import '../../domain/entities/speaking_quest.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../domain/repositories/speaking_repository.dart';

class SpeakingRepositoryImpl implements SpeakingRepository {
  final dynamic remoteDataSource;
  final dynamic networkInfo;
  SpeakingRepositoryImpl({this.remoteDataSource, this.networkInfo});

  @override
  Future<Either<Failure, List<SpeakingQuest>>> getSpeakingQuest({
    required GameSubtype gameType,
    required int level,
  }) async {
    try {
      final remoteQuests = await remoteDataSource.getSpeakingQuest(
        gameType: gameType,
        level: level,
      );
      return Right(remoteQuests);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
