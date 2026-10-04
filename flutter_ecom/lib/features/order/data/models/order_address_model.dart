import '../../domain/entities/order_address_entity.dart';

/// 订单收货地址数据模型
class OrderAddressModel {
  OrderAddressModel({
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

  factory OrderAddressModel.fromJson(Map<String, dynamic> json) {
    return OrderAddressModel(
      name: json['name'] as String,
      phone: json['phone'] as String,
      province: json['province'] as String,
      city: json['city'] as String,
      district: json['district'] as String,
      detail: json['detail'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  OrderAddressEntity toEntity() {
    return OrderAddressEntity(
      name: name,
      phone: phone,
      province: province,
      city: city,
      district: district,
      detail: detail,
      isDefault: isDefault,
    );
  }
}
