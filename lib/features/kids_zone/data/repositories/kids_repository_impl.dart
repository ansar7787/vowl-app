import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/exceptions.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/features/kids_zone/data/datasources/kids_remote_data_source.dart';
import 'package:vowl/features/kids_zone/data/datasources/kids_local_data_source.dart';
import 'package:vowl/features/kids_zone/domain/entities/kids_quest.dart';
import 'package:vowl/features/kids_zone/domain/repositories/kids_repository.dart';

class KidsRepositoryImpl implements KidsRepository {
  final KidsRemoteDataSource remoteDataSource;
  final KidsLocalDataSource localDataSource;

  KidsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<KidsQuest>>> getQuestsByLevel(
    String gameType,
    int level,
  ) async {
    // 1. Try Local Assets first (Free & Fast)
    try {
      final localQuests = await localDataSource.getQuestsByLevel(
        gameType,
        level,
      );
      if (localQuests.isNotEmpty) {
        return Right(localQuests);
      }
    } catch (_) {
      // Suppress local asset read failures to allow fallback to remote Firestore datasource lookup
    }

    // 2. Fallback to Firestore if local not found
    try {
      final remoteQuests = await remoteDataSource.getQuestsByLevel(
        gameType,
        level,
      );
      return Right(remoteQuests);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(
          e.message,
          code: e.code,
          statusCode: e.statusCode,
          details: e.details,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
