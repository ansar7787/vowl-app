import 'package:dartz/dartz.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/reading_quest.dart';
import '../../domain/repositories/reading_repository.dart';
import '../datasources/reading_remote_data_source.dart';

/// Implementation of [ReadingRepository] coordinating remote data access and network checks.
class ReadingRepositoryImpl implements ReadingRepository {
  /// Remote and asset data source provider for reading quests.
  final ReadingRemoteDataSource remoteDataSource;

  /// Network connectivity checker.
  final NetworkInfo networkInfo;

  /// Creates a [ReadingRepositoryImpl] instance.
  ReadingRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

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
    } catch (e) {
      if (!await networkInfo.isConnected) {
        return const Left(
          NetworkFailure(
            'No internet connection. Please verify your connection status.',
            code: 'OFFLINE_ERR',
          ),
        );
      }
      return Left(
        ServerFailure("Error loading reading quests: ${e.toString()}"),
      );
    }
  }
}
