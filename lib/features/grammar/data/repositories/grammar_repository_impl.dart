import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/grammar_quest.dart';
import '../../domain/repositories/grammar_repository.dart';
import '../datasources/grammar_remote_data_source.dart';

/// Production implementation of [GrammarRepository] retrieving quests from [GrammarRemoteDataSource].
class GrammarRepositoryImpl implements GrammarRepository {
  /// Remote data source providing grammar quest models.
  final GrammarRemoteDataSource remoteDataSource;

  /// Optional network info service.
  final NetworkInfo? networkInfo;

  /// Creates a [GrammarRepositoryImpl] with [remoteDataSource] and optional [networkInfo].
  const GrammarRepositoryImpl({
    required this.remoteDataSource,
    this.networkInfo,
  });

  @override
  Future<Either<Failure, List<GrammarQuest>>> getGrammarQuest({
    required GameSubtype gameType,
    required int level,
  }) async {
    try {
      final remoteQuests = await remoteDataSource.getGrammarQuest(
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

  @override
  Future<void> preloadGrammarQuest({
    required GameSubtype gameType,
    required int level,
  }) {
    return remoteDataSource.preloadBatch(gameType: gameType, level: level);
  }
}
