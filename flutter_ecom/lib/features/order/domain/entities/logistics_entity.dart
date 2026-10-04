import 'package:equatable/equatable.dart';

/// 物流更新信息
class LogisticsUpdateEntity extends Equatable {
  const LogisticsUpdateEntity({
    required this.time,
    required this.content,
  });

  final String time;
  final String content;

  @override
  List<Object> get props => [time, content];
}

/// 物流信息实体
class LogisticsEntity extends Equatable {
  const LogisticsEntity({
    required this.company,
    required this.trackingNo,
    required this.status,
    required this.updates,
  });

  final String company;
  final String trackingNo;
  final String status;
  final List<LogisticsUpdateEntity> updates;

  @override
  List<Object> get props => [
        company,
        trackingNo,
        status,
        updates,
      ];
}
