import '../../../../core/usecases/usecase.dart';
import '../repositories/accent_repository.dart';

class ClearAccentQuestCache {
  final AccentRepository repository;

  ClearAccentQuestCache(this.repository);

  Future<void> call(NoParams params) async {
    await repository.clearQuestCache();
  }
}
