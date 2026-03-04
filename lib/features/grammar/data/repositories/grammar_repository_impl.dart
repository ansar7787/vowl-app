import '../../domain/entities/grammar_quest.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../domain/repositories/grammar_repository.dart';
import '../../../../core/error/exceptions.dart';

class GrammarRepositoryImpl implements GrammarRepository {
  final dynamic remoteDataSource;
  final dynamic networkInfo;
  GrammarRepositoryImpl({this.remoteDataSource, this.networkInfo});

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
      return Left(ServerFailure(e.message ?? "An unexpected error occurred."));
    } catch (e) {
      return const Left(ServerFailure("Failed to load grammar quests."));
    }
  }

  @override
  Future<void> preloadGrammarQuest({
    required GameSubtype gameType,
    required int level,
  }) async {
    await remoteDataSource.preloadBatch(gameType: gameType, level: level);
  }
}
