import 'package:dartz/dartz.dart';
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
    try {
      // 1. Try Local Assets first (Free & Fast)
      final localQuests = await localDataSource.getQuestsByLevel(gameType, level);
      if (localQuests.isNotEmpty) {
        return Right(localQuests);
      }

      // 2. Fallback to Firestore if local not found
      final remoteQuests = await remoteDataSource.getQuestsByLevel(gameType, level);
      return Right(remoteQuests);
    } catch (e) {
      return const Left(ServerFailure('Failed to load Kids curriculum'));
    }
  }
}
