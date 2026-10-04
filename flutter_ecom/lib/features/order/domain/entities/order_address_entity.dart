import 'package:equatable/equatable.dart';

/// 订单收货地址实体
class OrderAddressEntity extends Equatable {
  const OrderAddressEntity({
    required this.name,
    required this.phone,
    required this.province,
    required this.city,
    required this.district,
    required this.detail,
    this.isDefault = false,
  });

  final String name;
  final String phone;
  final String province;
  final String city;
  final String district;
  final String detail;
  final bool isDefault;

  /// 完整地址
  String get fullAddress =>
      '$province$city$district$detail';

  @override
  List<Object> get props => [
        name,
        phone,
        province,
        city,
        district,
        detail,
        isDefault,
      ];
}
