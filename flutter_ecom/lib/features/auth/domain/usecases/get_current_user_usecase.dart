import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// 获取当前登录用户 UseCase
class GetCurrentUserUseCase {
  GetCurrentUserUseCase(this._repository);
  final AuthRepository _repository;

  Future<UserEntity?> call() {
    return _repository.getCurrentUser();
  }
}
