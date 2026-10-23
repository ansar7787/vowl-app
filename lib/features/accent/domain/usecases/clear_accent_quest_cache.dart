import '../../../../core/usecases/usecase.dart';
import '../repositories/accent_repository.dart';

/// Use case for clearing cached accent quests from storage.
class ClearAccentQuestCache {
  /// The underlying accent repository.
  final AccentRepository repository;

  /// Creates a [ClearAccentQuestCache] use case with the given [repository].
  const ClearAccentQuestCache(this.repository);

  /// Executes cache invalidation.
  Future<void> call(NoParams params) => repository.clearQuestCache();
}
