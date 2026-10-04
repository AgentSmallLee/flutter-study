// GENERATED CODE - DO NOT MODIFY BY HAND
//
// 说明：这是手动编写的 Hive TypeAdapter，
// 效果等同于 hive_generator 生成的代码。
// 正式项目中使用 `flutter packages pub run build_runner build` 自动生成。

part of 'cart_item_hive_model.dart';

/// CartItemHiveModel 的 TypeAdapter
///
/// 面试讲解点：
/// Hive 通过 TypeAdapter 实现对象的序列化/反序列化。
/// 每个字段用一个 typeId（0-255）标识，
/// 新增字段时要使用新的 typeId，不能修改已有字段的 typeId，
/// 否则旧版本 App 打开新版本数据会出错。
class CartItemHiveModelAdapter extends TypeAdapter<CartItemHiveModel> {
  @override
  final int typeId = 0;

  @override
  CartItemHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CartItemHiveModel(
      productId: fields[0] as int,
      productName: fields[1] as String,
      price: fields[2] as double,
      imageUrl: fields[3] as String,
      quantity: fields[4] as int,
      selected: fields[5] as bool? ?? true,
      specs: fields[6] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, CartItemHiveModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.productName)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.imageUrl)
      ..writeByte(4)
      ..write(obj.quantity)
      ..writeByte(5)
      ..write(obj.selected)
      ..writeByte(6)
      ..write(obj.specs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItemHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
