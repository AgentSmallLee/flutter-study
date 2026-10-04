import '../../domain/entities/logistics_entity.dart';

/// 物流更新数据模型
class LogisticsUpdateModel {
  LogisticsUpdateModel({
    required this.time,
    required this.content,
  });

  final String time;
  final String content;

  factory LogisticsUpdateModel.fromJson(Map<String, dynamic> json) {
    return LogisticsUpdateModel(
      time: json['time'] as String,
      content: json['content'] as String,
    );
  }

  LogisticsUpdateEntity toEntity() {
    return LogisticsUpdateEntity(
      time: time,
      content: content,
    );
  }
}

/// 物流信息数据模型
class LogisticsModel {
  LogisticsModel({
    required this.company,
    required this.trackingNo,
    required this.status,
    required this.updates,
  });

  final String company;
  final String trackingNo;
  final String status;
  final List<LogisticsUpdateModel> updates;

  factory LogisticsModel.fromJson(Map<String, dynamic> json) {
    final updatesList = json['updates'] as List? ?? [];
    return LogisticsModel(
      company: json['company'] as String,
      trackingNo: json['trackingNo'] as String,
      status: json['status'] as String,
      updates: updatesList
          .map((e) =>
              LogisticsUpdateModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  LogisticsEntity toEntity() {
    return LogisticsEntity(
      company: company,
      trackingNo: trackingNo,
      status: status,
      updates: updates.map((e) => e.toEntity()).toList(),
    );
  }
}
