import '../../../../core/error/result.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class SetTutorialUseCase {
  const SetTutorialUseCase(this._repository);

  final AuthRepository _repository;

  /// `completed: true` lo marca como visto; `false` lo reinicia.
  Future<Result<AuthUser>> call({required bool completed}) =>
      _repository.setTutorial(completed: completed);
}
