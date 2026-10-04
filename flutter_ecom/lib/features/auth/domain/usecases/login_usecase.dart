import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  LoginUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<UserEntity>> call({
    required String phone,
    required String password,
  }) {
    return _repository.login(phone: phone, password: password);
  }
}
