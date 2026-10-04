import '../../domain/entities/banner_entity.dart';

/// Banner 数据模型（Data 层）
///
/// 面试讲解点：
/// Model 和 Entity 的区别：
/// - Model 对应 API 返回的 JSON 结构，字段可能比 Entity 多
/// - Entity 是纯业务对象，只保留业务需要的字段
/// - Repository 中通过 toEntity() 做转换，
///   这样即使后端 JSON 结构变化，也只需要改 Model 层
class BannerModel {
  BannerModel({
    required this.id,
    required this.imageUrl,
    required this.linkType,
    required this.linkId,
    required this.sort,
  });

  final int id;
  final String imageUrl;
  final String linkType;
  final String linkId;
  final int sort;

  /// 从 JSON 解析
  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as int? ?? 0,
      imageUrl: json['imageUrl']?.toString() ?? '',
      linkType: json['linkType']?.toString() ?? '',
      linkId: json['linkId']?.toString() ?? '',
      sort: json['sort'] as int? ?? 0,
    );
  }

  /// 转换为 Entity
  BannerEntity toEntity() => BannerEntity(
        id: id,
        imageUrl: imageUrl,
        linkType: linkType,
        linkId: linkId,
        sort: sort,
      );
}
