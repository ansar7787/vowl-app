import '../../domain/entities/accent_quest.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../domain/repositories/accent_repository.dart';
import '../datasources/accent_data_source.dart';
import '../../../../core/network/network_info.dart';

class AccentRepositoryImpl implements AccentRepository {
  final AccentDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AccentRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<AccentQuest>>> getAccentQuests({
    required GameSubtype gameType,
    required int level,
  }) async {
    try {
      final remoteQuests = await remoteDataSource.getAccentQuest(
        gameType: gameType,
        level: level,
      );
      return Right(remoteQuests);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<void> preloadNextBatch({
    required GameSubtype gameType,
    required int currentLevel,
  }) async {
    await remoteDataSource.preloadNextBatch(
      gameType: gameType,
      currentLevel: currentLevel,
    );
  }

  @override
  Future<void> clearQuestCache() async {
    await remoteDataSource.clearQuestCache();
  }
}
