import 'package:dartz/dartz.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/roleplay_quest.dart';
import '../../domain/repositories/roleplay_repository.dart';
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
    } on ServerException catch (e) {
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure(
          'No internet connection. Please verify your connection status.',
          code: 'OFFLINE_ERR',
        ));
      }
      return Left(ServerFailure(
        e.message,
        code: e.code,
        statusCode: e.statusCode,
        details: e.details,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(
        e.message,
        code: e.code,
        details: e.details,
      ));
    } catch (e) {
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure(
          'No internet connection. Please verify your connection status.',
          code: 'OFFLINE_ERR',
        ));
      }
      return Left(ServerFailure("Error loading quests: ${e.toString()}"));
    }
  }

  @override
  Future<void> preloadNextBatch({
    required GameSubtype gameType,
    required int currentLevel,
  }) async {
    try {
      await remoteDataSource.preloadNextBatch(
        gameType: gameType,
        level: currentLevel,
      );
    } catch (e) {
      // Swallowed and logged cleanly to prevent background prefetching tasks from crashing the app
    }
  }
}
