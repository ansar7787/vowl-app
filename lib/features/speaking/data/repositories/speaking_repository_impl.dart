import 'package:dartz/dartz.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/error/exceptions.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/features/speaking/data/datasources/speaking_remote_data_source.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/features/speaking/domain/repositories/speaking_repository.dart';

class SpeakingRepositoryImpl implements SpeakingRepository {
  final SpeakingRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  SpeakingRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

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
      return Left(NetworkFailure(e.message, code: e.code, details: e.details));
    } catch (e) {
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure(
          'No internet connection. Please verify your connection status.',
          code: 'OFFLINE_ERR',
        ));
      }
      return Left(ServerFailure(e.toString()));
    }
  }
}
