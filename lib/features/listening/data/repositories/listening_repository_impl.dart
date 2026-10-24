import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/listening_quest.dart';
import '../../domain/repositories/listening_repository.dart';
import '../datasources/listening_remote_data_source.dart';

/// Implementation of [ListeningRepository] loading listening quests with failure translation.
class ListeningRepositoryImpl implements ListeningRepository {
  /// Remote data source providing listening quests.
  final ListeningRemoteDataSource remoteDataSource;

  /// Network connectivity service.
  final NetworkInfo networkInfo;

  /// Creates a [ListeningRepositoryImpl] with [remoteDataSource] and [networkInfo].
  const ListeningRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<ListeningQuest>>> getListeningQuests({
    required GameSubtype gameType,
    required int level,
  }) async {
    try {
      final remoteQuests = await remoteDataSource.getListeningQuest(
        gameType: gameType,
        level: level,
      );
      return Right(remoteQuests);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
