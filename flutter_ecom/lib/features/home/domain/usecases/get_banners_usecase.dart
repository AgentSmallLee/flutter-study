import '../../../../core/error/failures.dart';
import '../entities/banner_entity.dart';
import '../repositories/home_repository.dart';

/// 获取 Banner 列表用例
///
/// 面试讲解点：
/// UseCase（用例）封装了一个完整的业务操作，
/// 它是连接 Presentation 层和 Domain 层的桥梁。
/// 每个 UseCase 只有一个方法（call），遵循单一职责原则。
/// 好处：
/// 1. 业务逻辑集中，便于复用
/// 2. 便于单元测试
/// 3. Bloc 只和 UseCase 打交道，不直接依赖 Repository
class GetBannersUseCase {
  GetBannersUseCase(this._repository);

  final HomeRepository _repository;

  Future<Result<List<BannerEntity>>> call() {
    return _repository.getBanners();
  }
}
