import 'package:dartz/dartz.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/accent_quest.dart';
import '../../domain/repositories/accent_repository.dart';
import '../datasources/accent_data_source.dart';

/// Production implementation of [AccentRepository] coordinating remote data access and network validation.
class AccentRepositoryImpl implements AccentRepository {
  /// Remote data source providing accent quests.
  final AccentDataSource remoteDataSource;

  /// Network connectivity evaluator.
  final NetworkInfo networkInfo;

  /// Creates an [AccentRepositoryImpl] with [remoteDataSource] and [networkInfo].
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
    } on ServerException catch (e) {
      if (!await networkInfo.isConnected) {
        return const Left(
          NetworkFailure(
            'No internet connection. Please verify your connection status.',
            code: 'OFFLINE_ERR',
          ),
        );
      }
      return Left(
        ServerFailure(
          e.message,
          code: e.code,
          statusCode: e.statusCode,
          details: e.details,
        ),
      );
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message, code: e.code, details: e.details));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, code: e.code, details: e.details));
    } catch (e) {
      if (!await networkInfo.isConnected) {
        return const Left(
          NetworkFailure(
            'No internet connection. Please verify your connection status.',
            code: 'OFFLINE_ERR',
          ),
        );
      }
      return Left(ServerFailure(e.toString()));
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
        currentLevel: currentLevel,
      );
    } catch (_) {
      // Background operation fail-safe: suppress background preloading issues to prevent crashes
    }
  }

  @override
  Future<void> clearQuestCache() async {
    try {
      await remoteDataSource.clearQuestCache();
    } catch (_) {
      // Background operation fail-safe: suppress cache clearing issues to prevent crashes
    }
  }
}
