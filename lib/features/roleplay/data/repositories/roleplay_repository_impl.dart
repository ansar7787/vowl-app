import '../../domain/entities/roleplay_quest.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../domain/repositories/roleplay_repository.dart';

import '../../../../core/network/network_info.dart';
import '../datasources/roleplay_remote_data_source.dart';

class RoleplayRepositoryImpl implements RoleplayRepository {
  final RoleplayRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  RoleplayRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<RoleplayQuest>>> getRoleplayQuests({
    required GameSubtype gameType,
    required int level,
  }) async {
    try {
      final remoteQuests = await remoteDataSource.getRoleplayQuest(
        gameType: gameType,
        level: level,
      );
      return Right(remoteQuests);
    } catch (e) {
      return Left(ServerFailure("Error loading quests: ${e.toString()}"));
    }
  }

  @override
  Future<void> preloadNextBatch({
    required GameSubtype gameType,
    required int currentLevel,
  }) async {
    await remoteDataSource.preloadNextBatch(
      gameType: gameType,
      level: currentLevel,
    );
  }
}
