import 'package:equatable/equatable.dart';

/// Banner 实体（Domain 层）
///
/// 面试讲解点：
/// Entity 是纯业务对象，位于 Domain 层，
/// 不依赖任何框架，只包含业务需要的最少字段。
class BannerEntity extends Equatable {
  const BannerEntity({
    required this.id,
    required this.imageUrl,
    required this.linkType,
    required this.linkId,
    required this.sort,
  });

  final int id;
  final String imageUrl;

  /// 跳转类型：product / category / activity
  final String linkType;
  final String linkId;
  final int sort;

  @override
  List<Object> get props => [id, imageUrl, linkType, linkId, sort];
}
